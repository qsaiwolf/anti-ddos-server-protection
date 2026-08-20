#!/bin/bash

# Default interface is eth0, but user can pass another interface like ens3
IFACE=${1:-eth0}
OBJ_FILE="xdp_anti_ddos.o"
SRC_FILE="xdp_anti_ddos.c"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Ensure dependencies are installed
if ! command -v clang &> /dev/null; then
    echo "Installing required packages (clang, llvm, libbpf-dev, iproute2)..."
    apt-get update
    apt-get install -y clang llvm libbpf-dev gcc iproute2 linux-headers-$(uname -r)
fi

echo "Compiling $SRC_FILE to eBPF bytecode..."
clang -O2 -g -Wall -target bpf -c $SRC_FILE -o $OBJ_FILE

if [ ! -f "$OBJ_FILE" ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Unloading any existing XDP program on $IFACE..."
ip link set dev $IFACE xdp off 2>/dev/null

echo "Loading XDP program onto $IFACE..."
ip link set dev $IFACE xdp obj $OBJ_FILE sec xdp

if [ $? -eq 0 ]; then
    echo "✅ Success! XDP DDoS filter is now active on $IFACE."
    echo "To remove the filter, run: sudo ip link set dev $IFACE xdp off"
    echo "To check status, run: ip link show dev $IFACE"
else
    echo "❌ Failed to load XDP program. Your kernel or NIC driver might not support XDP."
fi
