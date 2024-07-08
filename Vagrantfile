Vagrant.configure("2") do |config|
    config.vm.provision "shell", inline: <<-SHELL
        apt update -y
        echo "10.0.10.10  master-node" >> /etc/hosts
        echo "10.0.10.11  worker-node01" >> /etc/hosts
        echo "10.0.10.12  worker-node02" >> /etc/hosts
        echo "10.0.10.13  worker-node03" >> /etc/hosts
    SHELL
    
    config.vm.define "master-node" do |master|
      master.vm.box = "generic/ubuntu2204"
      master.vm.hostname = "master-node"
      master.vm.network "private_network", ip: "10.0.10.10"
      master.vm.synced_folder ".","/vagrant"
      master.vm.provider "virtualbox" do |vb|
          vb.memory = 8192
          vb.cpus = 4
      end
      master.vm.provision "shell", path: "scripts/master-install-script.sh"
    end

    (1..3).each do |i|
  
    config.vm.define "worker-node0#{i}" do |node|
      node.vm.box = "generic/ubuntu2204"
      node.vm.hostname = "worker-node0#{i}"
      node.vm.network "private_network", ip: "10.0.10.1#{i}"
      node.vm.synced_folder ".","/vagrant"
      node.vm.provider "virtualbox" do |vb|
          vb.memory = 4096
          vb.cpus = 2
      end
      node.vm.provision "shell", path: "scripts/node-install-script.sh"
    end
 
    end
  end
