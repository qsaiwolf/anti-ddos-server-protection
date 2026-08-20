#!/bin/bash

IFACE=${1:-eth0}
ACTION=${2:-load}
OBJ_FILE="xdp_anti_ddos.o"
SRC_FILE="xdp_anti_ddos.c"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

if [ "$ACTION" == "unload" ] || [ "$ACTION" == "flush" ]; then
    echo "Unloading XDP program from $IFACE..."
    ip link set dev $IFACE xdp off 2>/dev/null
    ip link set dev $IFACE xdpgeneric off 2>/dev/null
    echo "✅ XDP program removed."
    exit 0
fi

# Ensure dependencies are installed
if ! command -v clang &> /dev/null || ! dpkg -l | grep -q libbpf-dev; then
    echo "Required packages (clang, llvm, libbpf-dev, linux-headers) are missing."
    read -p "Do you want to install them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing..."
        apt-get update
        apt-get install -y clang llvm libbpf-dev gcc iproute2 linux-headers-$(uname -r)
    else
        echo "Dependencies missing. Exiting."
        exit 1
    fi
fi

echo "Compiling $SRC_FILE to eBPF bytecode..."
clang -O2 -g -Wall -target bpf -c $SRC_FILE -o $OBJ_FILE

if [ ! -f "$OBJ_FILE" ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

echo "Unloading any existing XDP program on $IFACE..."
ip link set dev $IFACE xdp off 2>/dev/null
ip link set dev $IFACE xdpgeneric off 2>/dev/null

echo "Loading XDP program onto $IFACE (Trying Native mode)..."
ip link set dev $IFACE xdp obj $OBJ_FILE sec xdp

if [ $? -ne 0 ]; then
    echo "Native XDP failed. Trying Generic (SKB) mode as fallback..."
    ip link set dev $IFACE xdpgeneric obj $OBJ_FILE sec xdp
fi

if [ $? -eq 0 ]; then
    echo "✅ Success! XDP DDoS filter is now active on $IFACE."
    echo "To remove the filter, run: sudo ./load_xdp.sh $IFACE unload"
    echo "To check status, run: ip link show dev $IFACE"
else
    echo "❌ Failed to load XDP program in both Native and Generic modes."
fi
