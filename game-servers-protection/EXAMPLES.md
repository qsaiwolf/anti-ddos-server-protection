# Real-World Usage Scenarios 🌍

This file contains practical examples of how to use the Game Server Protection Toolkit in the wild.

## Scenario 1: Protecting a FiveM Server from UDP Floods
**The Problem:** Your FiveM server (`port 30120`) is being targeted by a massive 50 Gbps UDP flood, crashing your CPU.
**The Solution:**
1. Open `iptables_filters/game_config.ini`.
2. Ensure `FIVEM_ENABLE="true"`.
3. Start the protection using the CLI:
   ```bash
   sudo ./game-shield.sh start eth0
   ```
4. **What happens?** The XDP program will immediately block any single IP sending more than 5,000 PPS. If the attack uses spoofed IPs (millions of IPs sending 1 packet each), the global XDP map will detect the total threshold exceeding 1M PPS and drop all excessive traffic, saving your kernel.

## Scenario 2: Adding a Server Admin to the Whitelist
**The Problem:** Your strict iptables limits are kicking the server owner because their connection is unstable or aggressive.
**The Solution:**
1. Open `iptables_filters/game_config.ini`.
2. Find the `WHITELIST_IPS` setting.
3. Add the admin's IP: `WHITELIST_IPS="203.0.113.50"`
4. Reload the shield:
   ```bash
   sudo ./game-shield.sh stop
   sudo ./game-shield.sh start eth0
   ```

## Scenario 3: Safely Testing iptables Rules (Dry Run)
**The Problem:** You want to add custom ports to `game_config.ini` but you are afraid it will lock you out of SSH.
**The Solution:**
1. Edit `game_config.ini` and add your ports.
2. Run a dry run:
   ```bash
   sudo ./game-shield.sh dry-run
   ```
3. Read the output. The script will print the exact `iptables` commands it plans to execute without actually running them. If they look safe, run `start`.

## Scenario 4: Monitoring Active Attacks
**The Problem:** Players complain about lag and you suspect an attack.
**The Solution:**
1. Run the status command:
   ```bash
   sudo ./game-shield.sh status
   ```
2. You will see output like this:
   ```
   📊 Game-Shield Status:
   🟢 XDP Filter is ACTIVE.
   ⛔ Total Malicious Packets Dropped by XDP: 4509182
   🔥 iptables Active Rules Count:
   12
   ```
3. If the drop count is rapidly increasing, the server is under attack, but the toolkit is successfully mitigating it.
