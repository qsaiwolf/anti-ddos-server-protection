#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Check if an IP address was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <YOUR_IP_ADDRESS>"
  echo "Example: $0 192.168.1.100"
  exit 1
fi

USER_IP=$1

echo "Installing iptables-persistent..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install iptables-persistent -y

echo "Allowing Cloudflare IPv4 addresses..."
iptables -A INPUT -s 173.245.48.0/20 -j ACCEPT
iptables -A INPUT -s 103.21.244.0/22 -j ACCEPT
iptables -A INPUT -s 103.22.200.0/22 -j ACCEPT
iptables -A INPUT -s 103.31.4.0/22 -j ACCEPT
iptables -A INPUT -s 141.101.64.0/18 -j ACCEPT
iptables -A INPUT -s 108.162.192.0/18 -j ACCEPT
iptables -A INPUT -s 190.93.240.0/20 -j ACCEPT
iptables -A INPUT -s 188.114.96.0/20 -j ACCEPT
iptables -A INPUT -s 197.234.240.0/22 -j ACCEPT
iptables -A INPUT -s 198.41.128.0/17 -j ACCEPT
iptables -A INPUT -s 162.158.0.0/15 -j ACCEPT
iptables -A INPUT -s 104.16.0.0/13 -j ACCEPT
iptables -A INPUT -s 104.24.0.0/14 -j ACCEPT
iptables -A INPUT -s 172.64.0.0/13 -j ACCEPT
iptables -A INPUT -s 131.0.72.0/22 -j ACCEPT

echo "Allowing Cloudflare IPv6 addresses..."
ip6tables -A INPUT -s 2400:cb00::/32 -j ACCEPT
ip6tables -A INPUT -s 2606:4700::/32 -j ACCEPT
ip6tables -A INPUT -s 2803:f800::/32 -j ACCEPT
ip6tables -A INPUT -s 2405:b500::/32 -j ACCEPT
ip6tables -A INPUT -s 2405:8100::/32 -j ACCEPT
ip6tables -A INPUT -s 2a06:98c0::/29 -j ACCEPT
ip6tables -A INPUT -s 2c0f:f248::/32 -j ACCEPT

echo "Allowing access from your IP ($USER_IP)..."
sudo iptables -I INPUT -s $USER_IP -j ACCEPT

echo "Dropping all other traffic on ports 80 and 443..."
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
sudo iptables -A INPUT -p tcp --dport 443 -j DROP

echo "Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

echo "Protection applied successfully!"
