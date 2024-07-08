#!/bin/sh

# Based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

K8S_VERSION=1.30.2
MASTER_IP=10.0.10.10
POD_CIDR="192.168.0.0/16"
NODENAME=$(hostname -s)

#not on production systems
sudo ufw disable

#start update and installing requisite tools
sudo apt -y update
sudo apt -y full-upgrade
sudo apt install systemd-timesyncd
sudo timedatectl set-ntp true

#turn off swap
sudo swapoff -a
sudo sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

#Load the kernel modules at every boot
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Load required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

#installing the packages to be able to install others
sudo apt install -y curl apt-transport-https ca-certificates binutils gpg gnupg2 software-properties-common lsb-release

#add docker containerd repo
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#install containerd
sudo apt update && sudo apt install -y containerd.io

#containerd setup, make sure the directory exists
sudo mkdir -p /etc/containerd

#create containerd default config, suitable for K8S, change the CGroup setting
sudo containerd config default|sudo tee /etc/containerd/config.toml
sudo sed 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml

sudo systemctl restart containerd

#add K8S install repo
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#installing base K8S packages
sudo apt -y update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#setting crictl to use containerd otherwise crictl complains
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF


# Setting up sysctl for k8s
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

#Load the sysctl settings
sudo sysctl --system

#setting kubelet to use containerd

#cat <<EOF | sudo tee /etc/default/kubelet
#KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
#EOF


#starting up the services
sudo systemctl daemon-reload
sudo systemctl enable kubelet

#cleaning up the previous system remnants if there was any
sudo kubeadm reset -f
sudo rm /root/.kube/config

#download the images locally so it will not "block" kubeadm init and it runs faster
sudo kubeadm config images pull --kubernetes-version $K8S_VERSION --cri-socket unix:///run/containerd/containerd.sock

#initializing k8s, setting it to specific version, not the latest one (default) and enable to run only with one cpu/core
sudo kubeadm init --kubernetes-version=$K8S_VERSION --ignore-preflight-errors=NumCPU --apiserver-advertise-address=$MASTER_IP  --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name $NODENAME --cri-socket unix:///run/containerd/containerd.sock

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

config_path="/vagrant/configs"

if [ -d $config_path ]; then
   rm -f $config_path/*
else
   mkdir -p /vagrant/configs
fi

sudo cp -i /etc/kubernetes/admin.conf /vagrant/configs/config
sudo touch /vagrant/configs/join.sh
sudo chmod +x /vagrant/configs/join.sh       

sudo kubeadm token create --print-join-command > /vagrant/configs/join.sh

curl https://calico-v3-25.netlify.app/archive/v3.25/manifests/calico.yaml -O

kubectl apply -f calico.yaml

sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF

kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl
crictl completion bash | sudo tee /etc/bash_completion.d/crictl