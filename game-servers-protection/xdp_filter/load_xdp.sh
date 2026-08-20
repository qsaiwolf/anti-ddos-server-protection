#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

IFACE=$1
ACTION=${2:-load}
SRC_FILE="xdp_anti_ddos.c"
OBJ_FILE="xdp_anti_ddos.o"
BPF_FS="/sys/fs/bpf"
PIN_DIR="$BPF_FS/game_shield"
CONFIG_FILE="../iptables_filters/game_config.ini"

if [ -z "$IFACE" ]; then
    echo "Usage: $0 <interface> [load|unload]"
    echo "Example: $0 eth0 load"
    exit 1
fi

if [ "$ACTION" == "unload" ]; then
    echo "Unloading XDP from $IFACE..."
    ip link set dev $IFACE xdp off 2>/dev/null
    ip link set dev $IFACE xdpgeneric off 2>/dev/null
    rm -rf $PIN_DIR
    echo "✅ XDP unloaded successfully."
    exit 0
fi

# Ensure dependencies are installed
if ! command -v clang &> /dev/null || ! command -v bpftool &> /dev/null; then
    echo "Required packages are missing."
    read -p "Install dependencies now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apt-get update
        apt-get install -y clang llvm libbpf-dev gcc iproute2 linux-headers-$(uname -r) linux-tools-common linux-tools-generic
    else
        echo "Exiting."
        exit 1
    fi
fi

if ! mount | grep -q "$BPF_FS"; then
    mount -t bpf bpf $BPF_FS
fi

echo "Compiling $SRC_FILE to eBPF bytecode..."
clang -O2 -g -Wall -target bpf -c $SRC_FILE -o $OBJ_FILE

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed."
    exit 1
fi

# Clear old pinned maps
rm -rf $PIN_DIR
mkdir -p $PIN_DIR

echo "Loading eBPF object and pinning maps..."
bpftool prog loadall $OBJ_FILE $PIN_DIR/xdp_prog type xdp
if [ $? -ne 0 ]; then
    echo "❌ Failed to load eBPF object."
    exit 1
fi

echo "Attaching XDP program to $IFACE..."
PROG_ID=$(bpftool prog show pinned $PIN_DIR/xdp_prog | head -n1 | awk '{print $1}' | tr -d ':')

# Try native first, fallback to generic
ip link set dev $IFACE xdp obj $OBJ_FILE sec xdp 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Native XDP failed, trying xdpgeneric..."
    ip link set dev $IFACE xdpgeneric obj $OBJ_FILE sec xdp
    if [ $? -ne 0 ]; then
        echo "❌ Failed to attach XDP to $IFACE."
        exit 1
    fi
fi

# Parse whitelist if config exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    if [ -n "$WHITELIST_IPS" ]; then
        echo "Applying IPv4 Whitelists..."
        for ip in $WHITELIST_IPS; do
            # Convert IP string to hex format suitable for bpftool (little endian)
            hex_ip=$(printf '%02x ' $(echo $ip | tr '.' ' ') | awk '{print $4, $3, $2, $1}')
            bpftool map update pinned $PIN_DIR/whitelist_map key hex $hex_ip value hex 01 00 00 00
            echo " - Whitelisted $ip"
        done
    fi
    # Optional IPv6 whitelist logic could be added here
fi

echo "✅ XDP Anti-DDoS Loaded Successfully on $IFACE!"
echo "Use 'bpftool map dump pinned $PIN_DIR/xdp_stats_map' to view dropped packet count."
