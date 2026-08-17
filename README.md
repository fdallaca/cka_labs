# CKA Labs — Kubernetes the Hard Way

Vagrant + libvirt lab that recreates the machine prerequisites defined in
[Kubernetes the Hard Way – Prerequisites](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/01-prerequisites.md).

All four VMs run **Debian 12 (bookworm)** on a single isolated libvirt network (`cka-lab0 / 10.0.1.0/24`).

---

## Table of Contents

- [Lab Topology](#lab-topology)
- [Host Requirements](#host-requirements)
- [Install vagrant-libvirt on the Host](#install-vagrant-libvirt-on-the-host)
  - [Debian / Ubuntu](#debian--ubuntu)
  - [RHEL / CentOS / Fedora](#rhel--centos--fedora)
  - [Vagrant plugin](#vagrant-plugin)
- [Quick Start](#quick-start)
- [VM Access](#vm-access)
- [Tear Down](#tear-down)
- [Troubleshooting](#troubleshooting)

---

## Lab Topology

| VM       | Role                     | vCPU | RAM    | Disk   | IP         | SSH port |
|----------|--------------------------|------|--------|--------|------------|----------|
| jumpbox  | Administration host      | 1    | 512 MB | 100 GB | 10.0.1.10  | 2210     |
| server   | Kubernetes control plane | 1    | 2 GB   | 100 GB | 10.0.1.20  | 2220     |
| node-0   | Kubernetes worker        | 1    | 2 GB   | 100 GB | 10.0.1.21  | 2221     |
| node-1   | Kubernetes worker        | 1    | 2 GB   | 100 GB | 10.0.1.22  | 2222     |

Network: `cka-lab0` — `10.0.1.0/24` — isolated (no NAT, no DHCP)

---

## Host Requirements

| Resource | Minimum       |
|----------|---------------|
| CPU      | 4 cores (VT-x/AMD-V enabled) |
| RAM      | 8 GB free     |
| Disk     | 60 GB free (in the libvirt storage pool) |
| OS       | Linux (KVM-capable kernel) |

Verify KVM is available:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo   # must be > 0
kvm-ok                                # if cpu-checker is installed
```

---

## Install vagrant-libvirt on the Host

### Debian / Ubuntu

```bash
# KVM / libvirt stack
sudo apt install -y \
    qemu-kvm libvirt-daemon libvirt-daemon-system libvirt-clients \
    libvirt-dev virt-manager bridge-utils

# Enable and start libvirtd
sudo systemctl enable --now libvirtd

# Add your user to the libvirt group (log out and back in afterwards)
sudo usermod -aG libvirt,kvm "$(whoami)"

# Vagrant itself (official HashiCorp repo)
wget -O - https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y vagrant

# Build dependencies required by the vagrant-libvirt gem
sudo apt install -y ruby-dev ruby-libvirt pkg-config libvirt-dev build-essential
```

### RHEL / CentOS / Fedora

```bash
# KVM / libvirt stack
sudo dnf install -y \
    qemu-kvm libvirt libvirt-daemon libvirt-daemon-driver-qemu \
    libvirt-devel virt-manager

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$(whoami)"

# Vagrant (HashiCorp repo for RHEL/CentOS)
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo \
    https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y vagrant

# Build dependencies for the vagrant-libvirt gem
sudo dnf install -y ruby-devel libvirt-devel gcc make
```

### Vagrant plugin

Install the `vagrant-libvirt` plugin **once** after installing Vagrant:

```bash
vagrant plugin install vagrant-libvirt
```

Verify:

```bash
vagrant plugin list
# vagrant-libvirt (x.y.z, global)
```

> **Note:** if your system uses a system-packaged Vagrant (e.g. from distro
> repos) the plugin install path can differ. The HashiCorp upstream package is
> recommended to avoid version mismatches.

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/fdallaca/cka_labs.git
cd cka_labs

# 2. Source environment variables
source ./env.sh

# 3. Create the shared folder used for file exchange between VMs
mkdir -p shared_folder

# 4. Bring up all four VMs (the cka-lab0 network is created automatically)
vagrant up
```

Expected output: Vagrant boots jumpbox → server → node-0 → node-1 in order,
provisions SSH keys, and installs base packages on each.

To bring up a single VM:

```bash
vagrant up jumpbox
```

---

## VM Access

Using Vagrant's SSH wrapper:

```bash
vagrant ssh jumpbox
vagrant ssh server
vagrant ssh node-0
vagrant ssh node-1
```

Using your own SSH key directly (useful for Ansible or `scp`):

```bash
ssh -i ~/.ssh/id_rsa -p 2210 vagrant@127.0.0.1   # jumpbox
ssh -i ~/.ssh/id_rsa -p 2220 vagrant@127.0.0.1   # server
ssh -i ~/.ssh/id_rsa -p 2221 vagrant@127.0.0.1   # node-0
ssh -i ~/.ssh/id_rsa -p 2222 vagrant@127.0.0.1   # node-1
```

Or from `jumpbox` to any other node using the private network IP:

```bash
vagrant ssh jumpbox
# inside jumpbox:
ssh vagrant@10.0.1.20   # server
ssh vagrant@10.0.1.21   # node-0
ssh vagrant@10.0.1.22   # node-1
```

Verify the OS on every machine:

```bash
vagrant ssh server -- cat /etc/os-release | grep PRETTY_NAME
# PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
```

---

## Tear Down

Destroy all VMs (the `cka-lab0` network is removed automatically after the last VM is destroyed):

```bash
source ./env.sh

vagrant destroy -f

vagrant global-status --prune
```

---

## Troubleshooting

**`vagrant up` fails with "Call to virConnectOpen failed"`**  
Make sure `libvirtd` is running and your user is in the `libvirt` group:

```bash
sudo systemctl status libvirtd
groups   # must include 'libvirt'
```

**`NFS / rsync` errors on synced_folder**  
The Vagrantfile uses `rsync` (no NFS daemon needed). If rsync is missing:

```bash
sudo apt install -y rsync    # Debian/Ubuntu
sudo dnf install -y rsync    # RHEL/Fedora
```

**Network already exists error**  
`setup-networks.sh` is idempotent — running it again is safe. If you need a
fresh network:

```bash
virsh --connect qemu:///system net-destroy  cka-lab0
virsh --connect qemu:///system net-undefine cka-lab0
bash ./scripts/setup-networks.sh
```

**`vagrant-libvirt` plugin build fails (missing headers)**  
Install the libvirt development headers for your distro (see the install
sections above) and retry `vagrant plugin install vagrant-libvirt`.

**VM uses NAT address instead of private IP**  
libvirt assigns a NAT interface (`192.168.122.x`) as the first interface by
default; the private network IP is on the second interface. This is expected.
Use the `10.0.1.x` addresses for inter-VM communication.

---

## Next Steps

Follow the guide starting from
[02-jumpbox.md](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/02-jumpbox.md)
— all required tools should be downloaded and staged on `jumpbox`.
