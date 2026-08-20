#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

ACTION=${1:-apply}
DRY_RUN=false

if [ "$ACTION" == "--dry-run" ]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE ENABLED. Rules will be printed but NOT applied."
elif [ "$ACTION" == "flush" ] || [ "$ACTION" == "unload" ]; then
    echo "Flushing and removing Game Server Protection Rules..."
    iptables -D INPUT -j GAME_PROTECTION 2>/dev/null
    iptables -F GAME_PROTECTION 2>/dev/null
    iptables -X GAME_PROTECTION 2>/dev/null
    ip6tables -D INPUT -j GAME_PROTECTION 2>/dev/null
    ip6tables -F GAME_PROTECTION 2>/dev/null
    ip6tables -X GAME_PROTECTION 2>/dev/null
    echo "✅ Rules flushed."
    exit 0
fi

CONFIG_FILE="game_config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found in current directory!"
    exit 1
fi

source "$CONFIG_FILE"

# Wrapper to execute iptables and optionally ip6tables or just print them for dry-run
run_rule() {
    local rule="$@"
    if [ "$DRY_RUN" == "true" ]; then
        echo "[DRY RUN] iptables $rule"
        if [ "$ENABLE_IPV6" == "true" ]; then
            echo "[DRY RUN] ip6tables $rule"
        fi
    else
        iptables $rule 2>/dev/null
        if [ "$ENABLE_IPV6" == "true" ]; then
            ip6tables $rule 2>/dev/null
        fi
    fi
}

echo "Applying Game Server Protection Rules..."

if [ "$DRY_RUN" != "true" ]; then
    # Create a custom chain for clean management
    iptables -D INPUT -j GAME_PROTECTION 2>/dev/null
    iptables -F GAME_PROTECTION 2>/dev/null
    iptables -X GAME_PROTECTION 2>/dev/null
    iptables -N GAME_PROTECTION
    iptables -I INPUT -j GAME_PROTECTION
    
    if [ "$ENABLE_IPV6" == "true" ]; then
        ip6tables -D INPUT -j GAME_PROTECTION 2>/dev/null
        ip6tables -F GAME_PROTECTION 2>/dev/null
        ip6tables -X GAME_PROTECTION 2>/dev/null
        ip6tables -N GAME_PROTECTION
        ip6tables -I INPUT -j GAME_PROTECTION
    fi
fi

# Array to collect TCP ports for global SYN protection
TCP_PORTS=()

# 1. Source Engine Protection (UDP)
if [ "$SOURCE_ENGINE_ENABLE" == "true" ]; then
    echo "🛡️ Enabling Source Engine Protection on UDP port $SOURCE_ENGINE_PORT..."
    run_rule "-A GAME_PROTECTION -p udp --dport $SOURCE_ENGINE_PORT -m hashlimit --hashlimit-above $SOURCE_ENGINE_LIMIT/sec --hashlimit-burst 10 --hashlimit-mode srcip --hashlimit-name source_limit -j DROP"
    run_rule "-A GAME_PROTECTION -p udp --dport $SOURCE_ENGINE_PORT -m string --algo bm --hex-string \"|ff ff ff ff 54|\" -j ACCEPT"
fi

# 2. Minecraft Protection (TCP)
if [ "$MINECRAFT_ENABLE" == "true" ]; then
    echo "🛡️ Enabling Minecraft Bot Protection on TCP port $MINECRAFT_PORT..."
    run_rule "-A GAME_PROTECTION -p tcp --syn --dport $MINECRAFT_PORT -m connlimit --connlimit-above $MINECRAFT_CONNLIMIT --connlimit-mask 32 -j REJECT --reject-with tcp-reset"
    TCP_PORTS+=("$MINECRAFT_PORT")
fi

# 3. SAMP / MTA Protection (UDP)
if [ "$SAMP_MTA_ENABLE" == "true" ]; then
    echo "🛡️ Enabling SAMP/MTA Protection on UDP port $SAMP_MTA_PORT..."
    run_rule "-A GAME_PROTECTION -p udp --dport $SAMP_MTA_PORT -m hashlimit --hashlimit-above $SAMP_MTA_LIMIT/sec --hashlimit-burst 20 --hashlimit-mode srcip --hashlimit-name samp_limit -j DROP"
fi

# 4. FiveM Protection (TCP/UDP)
if [ "$FIVEM_ENABLE" == "true" ]; then
    echo "🛡️ Enabling FiveM Protection on port $FIVEM_PORT..."
    run_rule "-A GAME_PROTECTION -p tcp --syn --dport $FIVEM_PORT -m connlimit --connlimit-above $FIVEM_CONNLIMIT --connlimit-mask 32 -j REJECT --reject-with tcp-reset"
    run_rule "-A GAME_PROTECTION -p udp --dport $FIVEM_PORT -m hashlimit --hashlimit-above 50/sec --hashlimit-burst 100 --hashlimit-mode srcip --hashlimit-name fivem_udp -j DROP"
    TCP_PORTS+=("$FIVEM_PORT")
fi

# 5. TeamSpeak 3 Protection (UDP)
if [ "$TS3_ENABLE" == "true" ]; then
    echo "🛡️ Enabling TeamSpeak 3 Protection on UDP port $TS3_PORT..."
    run_rule "-A GAME_PROTECTION -p udp --dport $TS3_PORT -m hashlimit --hashlimit-above $TS3_UDP_LIMIT/sec --hashlimit-burst 20 --hashlimit-mode srcip --hashlimit-name ts3_limit -j DROP"
fi

# 6. 7 Days to Die Protection (TCP/UDP)
if [ "$SEVEN_DAYS_ENABLE" == "true" ]; then
    echo "🛡️ Enabling 7 Days to Die Protection on port $SEVEN_DAYS_PORT..."
    run_rule "-A GAME_PROTECTION -p tcp --syn --dport $SEVEN_DAYS_PORT -m connlimit --connlimit-above $SEVEN_DAYS_CONNLIMIT --connlimit-mask 32 -j REJECT --reject-with tcp-reset"
    run_rule "-A GAME_PROTECTION -p udp --dport $SEVEN_DAYS_PORT -m hashlimit --hashlimit-above 50/sec --hashlimit-burst 100 --hashlimit-mode srcip --hashlimit-name sevendays_udp -j DROP"
    TCP_PORTS+=("$SEVEN_DAYS_PORT")
fi

# 7. Custom Ports
if [ -n "$CUSTOM_TCP_PORTS" ]; then
    for port in $CUSTOM_TCP_PORTS; do
        echo "🛡️ Enabling Custom TCP Protection on port $port..."
        run_rule "-A GAME_PROTECTION -p tcp --syn --dport $port -m connlimit --connlimit-above $CUSTOM_TCP_CONNLIMIT --connlimit-mask 32 -j REJECT --reject-with tcp-reset"
        TCP_PORTS+=("$port")
    done
fi

if [ -n "$CUSTOM_UDP_PORTS" ]; then
    for port in $CUSTOM_UDP_PORTS; do
        echo "🛡️ Enabling Custom UDP Protection on port $port..."
        run_rule "-A GAME_PROTECTION -p udp --dport $port -m hashlimit --hashlimit-above $CUSTOM_UDP_LIMIT/sec --hashlimit-burst $((CUSTOM_UDP_LIMIT*2)) --hashlimit-mode srcip --hashlimit-name custom_udp_$port -j DROP"
    done
fi

# 8. General TCP SYN Flood Protection
if [ "$GENERAL_TCP_SYN_ENABLE" == "true" ] && [ ${#TCP_PORTS[@]} -gt 0 ]; then
    echo "🛡️ Enabling Global TCP SYN Flood Protection..."
    COMMA_PORTS=$(IFS=,; echo "${TCP_PORTS[*]}")
    run_rule "-A GAME_PROTECTION -p tcp --syn -m multiport --dports $COMMA_PORTS -m recent --name synflood --set"
    run_rule "-A GAME_PROTECTION -p tcp --syn -m multiport --dports $COMMA_PORTS -m recent --name synflood --update --seconds 1 --hitcount $GENERAL_TCP_SYN_LIMIT -j DROP"
fi

# 9. General UDP Rate Limiting
if [ "$GENERAL_LIMIT_ENABLE" == "true" ]; then
    echo "🛡️ Enabling General UDP Rate Limiting (Max $GENERAL_UDP_MAX packets/s per IP)..."
    run_rule "-A GAME_PROTECTION -p udp -m hashlimit --hashlimit-above $GENERAL_UDP_MAX/sec --hashlimit-mode srcip --hashlimit-name global_udp_drop -j DROP"
fi

if [ "$DRY_RUN" == "true" ]; then
    echo "✅ Dry Run Complete."
    exit 0
fi

echo "📦 Saving rules..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections 2>/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent 2>/dev/null
iptables-save > /etc/iptables/rules.v4
if [ "$ENABLE_IPV6" == "true" ]; then
    ip6tables-save > /etc/iptables/rules.v6 2>/dev/null
fi

echo "✅ All game rules applied successfully!"
