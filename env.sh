#!/usr/bin/env bash
# Source this file before running vagrant commands:
#   source ./env.sh
export VAGRANT_DEFAULT_PROVIDER=libvirt
export LIBVIRT_DEFAULT_URI="qemu:///system"
export LIBVIRT_STORAGE_POOL="images"
export ID_RSA_PUB="${HOME}/.ssh/id_rsa.pub"
export ID_RSA="${HOME}/.ssh/id_rsa"
