#!/usr/bin/env bash
# Pre-create libvirt network for the cka-lab Vagrant environment.
# Run once before: vagrant up
#
# Network:
#   cka-lab0  -  10.0.1.0/24  (management + Kubernetes internal)

LIBVIRT_URI="${1:-${LIBVIRT_DEFAULT_URI:-qemu:///system}}"
VIRSH="virsh --connect ${LIBVIRT_URI}"

# Serialize concurrent runs (vagrant fires one trigger per VM in parallel)
exec 9>/tmp/cka-lab0-setup.lock
trap 'rm -f /tmp/cka-lab0-setup.lock' EXIT
flock -x 9

if [[ "${LIBVIRT_URI}" != "qemu:///system" ]]; then
  echo "ERROR: this lab supports only qemu:///system." >&2
  echo "Please set LIBVIRT_DEFAULT_URI=qemu:///system and retry." >&2
  exit 1
fi

create_network() {
    local name=$1
    local gateway=$2

    if $VIRSH net-info "$name" &>/dev/null; then
        local active_state
        active_state="$($VIRSH net-info "$name" | awk '/Active:/ {print $2}')"
        if [[ "$active_state" != "yes" ]]; then
            if ! $VIRSH net-start "$name"; then
                echo "ERROR: network '$name' exists but could not be started." >&2
                exit 1
            fi
        fi
        $VIRSH net-autostart "$name" &>/dev/null || true
        echo "Network $name already exists and is active."
        return
    fi

    cat > /tmp/${name}.xml <<EOF
<network>
  <name>${name}</name>
  <forward mode='none'/>
  <bridge name="${name}" stp="on" delay="0"/>
  <ip address="${gateway}" netmask="255.255.255.0">
  </ip>
</network>
EOF

    $VIRSH net-define /tmp/${name}.xml
    $VIRSH net-start "$name"
    $VIRSH net-autostart "$name"
    echo "Network $name created and started."
    rm /tmp/${name}.xml
}

create_network "cka-lab0" "10.0.1.1"

echo ""
echo "Networks ready:"
$VIRSH net-list --all | grep -E "cka-lab|Name"
