#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

CONFIG_FILE="game_config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found in current directory!"
    exit 1
fi

source "$CONFIG_FILE"

echo "Applying Game Server Protection Rules..."

# Create a custom chain for clean management
iptables -N GAME_PROTECTION 2>/dev/null
iptables -F GAME_PROTECTION
# Link it to INPUT if not already linked (Insert at the top)
iptables -C INPUT -j GAME_PROTECTION 2>/dev/null || iptables -I INPUT -j GAME_PROTECTION

# 1. Source Engine Protection
if [ "$SOURCE_ENGINE_ENABLE" == "true" ]; then
    echo "🛡️ Enabling Source Engine Protection on UDP port $SOURCE_ENGINE_PORT..."
    # A2S_INFO query payload usually starts with 0xFFFFFFFF54
    # We rate limit it to prevent query floods
    iptables -A GAME_PROTECTION -p udp --dport "$SOURCE_ENGINE_PORT" -m string --algo bm --hex-string "|ff ff ff ff 54|" -m hashlimit --hashlimit-upto "$SOURCE_ENGINE_LIMIT/sec" --hashlimit-burst 5 --hashlimit-mode srcip --hashlimit-name source_query_limit -j ACCEPT
    iptables -A GAME_PROTECTION -p udp --dport "$SOURCE_ENGINE_PORT" -m string --algo bm --hex-string "|ff ff ff ff 54|" -j DROP
fi

# 2. Minecraft Protection
if [ "$MINECRAFT_ENABLE" == "true" ]; then
    echo "🛡️ Enabling Minecraft Bot Protection on TCP port $MINECRAFT_PORT..."
    # Reject new connections if the IP already has too many open connections
    iptables -A GAME_PROTECTION -p tcp --syn --dport "$MINECRAFT_PORT" -m connlimit --connlimit-above "$MINECRAFT_CONNLIMIT" --connlimit-mask 32 -j REJECT --reject-with tcp-reset
fi

# 3. SAMP / MTA Protection
if [ "$SAMP_MTA_ENABLE" == "true" ]; then
    echo "🛡️ Enabling SAMP/MTA Protection on UDP port $SAMP_MTA_PORT..."
    # Simple UDP rate limiting for the game port
    iptables -A GAME_PROTECTION -p udp --dport "$SAMP_MTA_PORT" -m hashlimit --hashlimit-upto "$SAMP_MTA_LIMIT/sec" --hashlimit-burst 20 --hashlimit-mode srcip --hashlimit-name samp_query_limit -j ACCEPT
    # Note: We don't blind DROP all other UDP on this port, because valid players need to play. 
    # The hashlimit above is just an example of how to tag. A safer way to DROP excessive traffic:
    iptables -A GAME_PROTECTION -p udp --dport "$SAMP_MTA_PORT" -m hashlimit --hashlimit-above "$SAMP_MTA_LIMIT/sec" --hashlimit-mode srcip --hashlimit-name samp_query_drop -j DROP
fi

# 4. General UDP Rate Limiting
if [ "$GENERAL_LIMIT_ENABLE" == "true" ]; then
    echo "🛡️ Enabling General UDP Rate Limiting (Max $GENERAL_UDP_MAX packets/s per IP)..."
    iptables -A GAME_PROTECTION -p udp -m hashlimit --hashlimit-above "$GENERAL_UDP_MAX/sec" --hashlimit-mode srcip --hashlimit-name global_udp_drop -j DROP
fi

echo "📦 Saving rules..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
iptables-save > /etc/iptables/rules.v4

echo "✅ All game rules applied successfully!"
