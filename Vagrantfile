# Vagrantfile for Kubernetes the Hard Way
# Based on: https://github.com/kelseyhightower/kubernetes-the-hard-way
#
# VMs:
#   jumpbox  - 1 vCPU, 512 MB  - administration host (Debian 12)
#   server   - 1 vCPU, 2 GB    - Kubernetes control plane (Debian 12)
#   node-0   - 1 vCPU, 2 GB    - Kubernetes worker node (Debian 12)
#   node-1   - 1 vCPU, 2 GB    - Kubernetes worker node (Debian 12)
#
# Network (cka-lab0 / 10.0.1.0/24):
#   jumpbox  10.0.1.10
#   server   10.0.1.20
#   node-0   10.0.1.21
#   node-1   10.0.1.22

Vagrant.configure("2") do |config|

    id_rsa_pub = ENV['ID_RSA_PUB'] || File.expand_path("~/.ssh/id_rsa.pub")
    id_rsa     = ENV['ID_RSA']     || File.expand_path("~/.ssh/id_rsa")

    config.vm.provider :libvirt do |lv|
        lv.uri               = "qemu:///system"
        lv.storage_pool_name = ENV['LIBVIRT_STORAGE_POOL'] || "images"
    end

    # ── Shared provisioner: SSH keys + sshd hardening ───────────────────────
    ssh_key_provision = <<-SHELL
        mkdir -p /home/vagrant/.ssh
        cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys /home/vagrant/.ssh/id_rsa
        chown -R vagrant:vagrant /home/vagrant/.ssh
        mkdir -p /root/.ssh
        cat /home/vagrant/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
        cp  /home/vagrant/.ssh/id_rsa /root/.ssh/id_rsa
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_rsa
        chown -R root:root /root/.ssh
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/'         /etc/ssh/sshd_config
        sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        systemctl restart sshd
    SHELL

    # ── jumpbox ─────────────────────────────────────────────────────────────
    config.vm.define "jumpbox" do |node|
        node.vm.box      = "debian/bookworm64"
        node.vm.hostname = "jumpbox"
        node.vm.network "private_network", ip: "10.0.1.10",
            libvirt__network_name: "cka-lab0"
        node.vm.network "forwarded_port", guest: 22, host: 2210, id: "ssh"

        node.vm.provider :libvirt do |lv|
            lv.memory = 512
            lv.cpus   = 1
            lv.machine_virtual_size = 10
        end

        node.vm.synced_folder "./shared_folder", "/vagrant",
            type: "rsync", rsync__exclude: ".git/"

        node.vm.provision "file",  run: "once", source: id_rsa_pub,
            destination: "/home/vagrant/.ssh/id_rsa.pub"
        node.vm.provision "file",  run: "once", source: id_rsa,
            destination: "/home/vagrant/.ssh/id_rsa"
        node.vm.provision "shell", run: "once", inline: ssh_key_provision
        node.vm.provision "shell", run: "once", inline: <<-SHELL
            apt-get update -y
            apt-get install -y curl wget git vim tmux net-tools dnsutils \
                               iproute2 iputils-ping
        SHELL
    end

    # ── server (control plane) ───────────────────────────────────────────────
    config.vm.define "server" do |node|
        node.vm.box      = "debian/bookworm64"
        node.vm.hostname = "server"
        node.vm.network "private_network", ip: "10.0.1.20",
            libvirt__network_name: "cka-lab0"
        node.vm.network "forwarded_port", guest: 22, host: 2220, id: "ssh"

        node.vm.provider :libvirt do |lv|
            lv.memory = 2048
            lv.cpus   = 1
            lv.machine_virtual_size = 20
        end

        node.vm.synced_folder "./shared_folder", "/vagrant",
            type: "rsync", rsync__exclude: ".git/"

        node.vm.provision "file",  run: "once", source: id_rsa_pub,
            destination: "/home/vagrant/.ssh/id_rsa.pub"
        node.vm.provision "file",  run: "once", source: id_rsa,
            destination: "/home/vagrant/.ssh/id_rsa"
        node.vm.provision "shell", run: "once", inline: ssh_key_provision
        node.vm.provision "shell", run: "once", inline: <<-SHELL
            apt-get update -y
            apt-get install -y curl wget vim net-tools iproute2 iputils-ping
        SHELL
    end

    # ── node-0 (worker) ──────────────────────────────────────────────────────
    config.vm.define "node-0" do |node|
        node.vm.box      = "debian/bookworm64"
        node.vm.hostname = "node-0"
        node.vm.network "private_network", ip: "10.0.1.21",
            libvirt__network_name: "cka-lab0"
        node.vm.network "forwarded_port", guest: 22, host: 2221, id: "ssh"

        node.vm.provider :libvirt do |lv|
            lv.memory = 2048
            lv.cpus   = 1
            lv.machine_virtual_size = 20
        end

        node.vm.synced_folder "./shared_folder", "/vagrant",
            type: "rsync", rsync__exclude: ".git/"

        node.vm.provision "file",  run: "once", source: id_rsa_pub,
            destination: "/home/vagrant/.ssh/id_rsa.pub"
        node.vm.provision "file",  run: "once", source: id_rsa,
            destination: "/home/vagrant/.ssh/id_rsa"
        node.vm.provision "shell", run: "once", inline: ssh_key_provision
        node.vm.provision "shell", run: "once", inline: <<-SHELL
            apt-get update -y
            apt-get install -y curl wget vim net-tools iproute2 iputils-ping
        SHELL
    end

    # ── node-1 (worker) ──────────────────────────────────────────────────────
    config.vm.define "node-1" do |node|
        node.vm.box      = "debian/bookworm64"
        node.vm.hostname = "node-1"
        node.vm.network "private_network", ip: "10.0.1.22",
            libvirt__network_name: "cka-lab0"
        node.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh"

        node.vm.provider :libvirt do |lv|
            lv.memory = 2048
            lv.cpus   = 1
            lv.machine_virtual_size = 20
        end

        node.vm.synced_folder "./shared_folder", "/vagrant",
            type: "rsync", rsync__exclude: ".git/"

        node.vm.provision "file",  run: "once", source: id_rsa_pub,
            destination: "/home/vagrant/.ssh/id_rsa.pub"
        node.vm.provision "file",  run: "once", source: id_rsa,
            destination: "/home/vagrant/.ssh/id_rsa"
        node.vm.provision "shell", run: "once", inline: ssh_key_provision
        node.vm.provision "shell", run: "once", inline: <<-SHELL
            apt-get update -y
            apt-get install -y curl wget vim net-tools iproute2 iputils-ping
        SHELL
    end

end
