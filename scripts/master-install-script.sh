#!/bin/sh

# Based on https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

K8S_VERSION=1.22.2
MASTER_IP=10.0.10.10
POD_CIDR="192.168.0.0/16"
NODENAME=$(hostname -s)

#start installing system tools
sudo apt -y update
sudo apt -y upgrade
sudo apt install -y curl apt-transport-https bash-completion binutils ca-certificates gnupg lsb-release

curl -sSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

sudo apt -y update
sudo apt install -y docker.io containerd kubelet=${K8S_VERSION}-00 kubeadm=${K8S_VERSION}-00 kubectl=${K8S_VERSION}-00

sudo apt-mark hold kubelet kubeadm kubectl

# Load required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

#Load the kernel modules at every boot
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Setting up sysctl
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

#Load the sysctl settings
sudo sysctl --system

#containerd setup
sudo mkdir -p /etc/containerd

### containerd config
sudo cat > /etc/containerd/config.toml <<EOF
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
EOF


#setting crictl to use containerd
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

#setting kubelet to use containerd

cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF


#starting up the services
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl enable kubelet --now

#cleaning up the previous system remnants if there was any
sudo kubeadm reset -f
sudo rm /root/.kube/config

#download the images locally so it will not "block" kubeadm init and it runs faster
sudo kubeadm config images pull --kubernetes-version $K8S_VERSION


#initializing k8s, setting it to specific version, not the latest one (default) and enable to run only with one cpu/core
sudo kubeadm init --kubernetes-version=$K8S_VERSION --ignore-preflight-errors=NumCPU --apiserver-advertise-address=$MASTER_IP  --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name $NODENAME

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
touch /vagrant/configs/join.sh
chmod +x /vagrant/configs/join.sh       

kubeadm token create --print-join-command > /vagrant/configs/join.sh

curl https://docs.projectcalico.org/manifests/calico.yaml -O

kubectl apply -f calico.yaml

sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF

kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl
crictl completion bash | sudo tee /etc/bash_completion.d/crictl