#!/usr/bin/env bash
# Called by the Vagrant 'after :destroy' trigger.
# Removes the cka-lab0 libvirt network once ALL lab VMs have been destroyed.

LIBVIRT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"
VIRSH="virsh --connect ${LIBVIRT_URI}"

# Keep the network while any lab VM still exists in libvirt (any state)
if $VIRSH list --all --name 2>/dev/null | grep -qE '_(jumpbox|server|node-0|node-1)$'; then
    echo "Lab VMs still exist; keeping cka-lab0 network."
    exit 0
fi

if ! $VIRSH net-info cka-lab0 &>/dev/null; then
    exit 0   # network is already gone
fi

$VIRSH net-destroy  cka-lab0 2>/dev/null || true
$VIRSH net-undefine cka-lab0 2>/dev/null || true
echo "Network cka-lab0 removed."
