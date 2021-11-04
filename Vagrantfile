Vagrant.configure("2") do |config|
    config.vm.provision "shell", inline: <<-SHELL
        apt update -y
        echo "10.0.10.10  master-node" >> /etc/hosts
        echo "10.0.10.11  worker-node01" >> /etc/hosts
        echo "10.0.10.12  worker-node02" >> /etc/hosts
    SHELL
    
    config.vm.define "master-node" do |master|
      master.vm.box = "bento/ubuntu-20.04"
      master.vm.hostname = "master-node"
      master.vm.network "private_network", ip: "10.0.10.10"
      master.vm.provider "virtualbox" do |vb|
          vb.memory = 4096
          vb.cpus = 2
      end
      master.vm.provision "shell", path: "scripts/master-install-script.sh"
    end

    (1..2).each do |i|
  
    config.vm.define "worker-node0#{i}" do |node|
      node.vm.box = "bento/ubuntu-20.04"
      node.vm.hostname = "worker-node0#{i}"
      node.vm.network "private_network", ip: "10.0.10.1#{i}"
      node.vm.provider "virtualbox" do |vb|
          vb.memory = 4096
          vb.cpus = 2
      end
      node.vm.provision "shell", path: "scripts/node-install-script.sh"
    end
 
    end
  end
