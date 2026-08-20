#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

DOMAIN=$1
PORT=${2:-22} # Default port is 22

if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <DDNS_DOMAIN> [PORT]"
  echo "Example: $0 myhome.duckdns.org 22"
  exit 1
fi

echo "Installing required packages (dnsutils, iptables-persistent)..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y dnsutils iptables-persistent

CRON_SCRIPT="/usr/local/bin/update_dynamic_port_${PORT}.sh"

echo "Creating the auto-updater script at $CRON_SCRIPT..."

cat << 'EOF' > "$CRON_SCRIPT"
#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DOMAIN="MY_DOMAIN"
PORT="MY_PORT"
IP=$(dig +short $DOMAIN | tail -n 1)

if [[ -n "$IP" ]]; then
  # Check if rule already exists for this IP and Port
  if ! iptables -C INPUT -s "$IP" -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
    iptables -I INPUT -s "$IP" -p tcp --dport "$PORT" -j ACCEPT
  fi
fi

# Ensure default DROP rule for the port exists
if ! iptables -C INPUT -p tcp --dport "$PORT" -j DROP 2>/dev/null; then
  iptables -A INPUT -p tcp --dport "$PORT" -j DROP
fi

iptables-save > /etc/iptables/rules.v4
EOF

# Replace placeholders with actual values
sed -i "s/MY_DOMAIN/$DOMAIN/g" "$CRON_SCRIPT"
sed -i "s/MY_PORT/$PORT/g" "$CRON_SCRIPT"

chmod +x "$CRON_SCRIPT"

echo "Running the script for the first time..."
"$CRON_SCRIPT"

echo "Setting up cron job to run every minute..."
CRON_JOB="* * * * * $CRON_SCRIPT >> /var/log/update_dynamic_port_${PORT}.log 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$CRON_SCRIPT"; then
    echo "Cron job already exists."
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Cron job added successfully."
fi

echo "Done! Port $PORT is now protected and will only accept connections from $DOMAIN."
