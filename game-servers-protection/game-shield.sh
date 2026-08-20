#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./game-shield.sh)"
  exit
fi

ACTION=$1
IFACE=${2:-eth0}

XDP_DIR="xdp_filter"
IPTABLES_DIR="iptables_filters"
BPF_FS="/sys/fs/bpf/game_shield"

print_help() {
    echo "🛡️ Game-Shield Ultimate CLI 🛡️"
    echo "Usage: ./game-shield.sh [command] [interface]"
    echo ""
    echo "Commands:"
    echo "  start [iface]   - Start both XDP and iptables protections (default iface: eth0)"
    echo "  stop [iface]    - Stop and flush all protections"
    echo "  status          - View live dropped packet statistics and XDP status"
    echo "  test            - Run a local UDP flood self-test to verify XDP is blocking"
    echo "  apply-rules     - Re-apply iptables rules from game_config.ini"
    echo "  dry-run         - Preview iptables rules safely"
    echo ""
}

case $ACTION in
    start)
        echo "🚀 Starting Game-Shield..."
        cd $XDP_DIR && ./load_xdp.sh $IFACE load
        cd ../$IPTABLES_DIR && ./apply_game_rules.sh apply
        echo "✅ Game-Shield is now ACTIVE."
        ;;
    stop|flush)
        echo "🛑 Stopping Game-Shield..."
        cd $XDP_DIR && ./load_xdp.sh $IFACE unload
        cd ../$IPTABLES_DIR && ./apply_game_rules.sh flush
        echo "✅ Game-Shield is now INACTIVE."
        ;;
    status)
        echo "📊 Game-Shield Status:"
        if [ -d "$BPF_FS" ]; then
            echo "🟢 XDP Filter is ACTIVE."
            DROPS=$(bpftool map dump pinned $BPF_FS/xdp_stats_map 2>/dev/null | grep value | awk '{print $2}' | tr -d '\n')
            if [ -n "$DROPS" ]; then
                echo "⛔ Total Malicious Packets Dropped by XDP: $((16#$DROPS))"
            else
                echo "⛔ Total Malicious Packets Dropped by XDP: 0"
            fi
        else
            echo "🔴 XDP Filter is INACTIVE."
        fi
        echo "🔥 iptables Active Rules Count:"
        iptables -S GAME_PROTECTION 2>/dev/null | wc -l
        ;;
    apply-rules)
        cd $IPTABLES_DIR && ./apply_game_rules.sh apply
        ;;
    dry-run)
        cd $IPTABLES_DIR && ./apply_game_rules.sh --dry-run
        ;;
    test)
        echo "🧪 Running Self-Test..."
        if ! command -v hping3 &> /dev/null; then
            echo "Installing hping3 for testing..."
            apt-get install -y hping3
        fi
        
        # Note dropped before test
        BEFORE=0
        if [ -d "$BPF_FS" ]; then
            RAW=$(bpftool map dump pinned $BPF_FS/xdp_stats_map 2>/dev/null | grep value | awk '{print $2}' | tr -d '\n')
            if [ -n "$RAW" ]; then
                BEFORE=$((16#$RAW))
            fi
        fi

        echo "Sending 10,000 spoofed UDP packets to localhost (simulated attack)..."
        # Fast flood
        hping3 -c 10000 -d 120 -S -w 64 -p 27015 --flood --rand-source 127.0.0.1 2>/dev/null &
        sleep 3
        killall hping3 2>/dev/null
        
        if [ -d "$BPF_FS" ]; then
            RAW=$(bpftool map dump pinned $BPF_FS/xdp_stats_map 2>/dev/null | grep value | awk '{print $2}' | tr -d '\n')
            if [ -n "$RAW" ]; then
                AFTER=$((16#$RAW))
                DIFF=$((AFTER - BEFORE))
                echo "🛡️ Result: XDP successfully blocked $DIFF packets during the test!"
                if [ $DIFF -gt 0 ]; then
                    echo "✅ Test PASSED. Protection is working perfectly."
                else
                    echo "⚠️ Test FAILED. No packets were dropped. Check if XDP is attached to the loopback interface for testing, or test via an external IP."
                fi
            fi
        else
            echo "XDP is not loaded."
        fi
        ;;
    *)
        print_help
        ;;
esac
