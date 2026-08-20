# Game Server Protection (Anti-DDoS Toolkit)

[العربية](#العربية) | [English](#english)

## English

Welcome to the ultimate Game Server Anti-DDoS toolkit! Protecting game servers (like CS:GO, Minecraft, Rust, SAMP, MTA, FiveM, TeamSpeak 3, 7 Days to Die) is highly complex because they use custom UDP/TCP protocols that can't be protected by Cloudflare's standard web proxy.

This toolkit provides **Enterprise-Level Protection** using two layers:
1. **Layer 1 (eBPF/XDP):** Drops junk packets and volumetric UDP floods directly at the Network Interface Card (NIC) before they even reach the Linux Kernel. It uses advanced BPF maps to track and rate-limit IPs, thwarting IP Spoofing.
2. **Layer 2 (iptables):** Smart application-level filters. It uses fast rate-limiting combined with payload string-matching to block specific game exploits (e.g., A2S_INFO query floods, Minecraft bots, TCP SYN floods).

### How to Use

#### 1. XDP Filter (High-Performance UDP Drop)
Navigate to the `xdp_filter/` folder and run the loader. It will compile the C program and attach it to your network card.
```bash
cd xdp_filter
sudo ./load_xdp.sh eth0 load
```
*(Replace `eth0` with your actual network interface name).*
- To remove the filter, run: `sudo ./load_xdp.sh eth0 unload`

#### 2. iptables Smart Game Filters
Navigate to the `iptables_filters/` folder.
1. Open `game_config.ini` in any text editor.
2. Change `ENABLE="true"` for the games you host (CS:GO, Minecraft, SAMP, FiveM, TS3, Custom Ports).
3. Set `ENABLE_IPV6="true"` if your server listens on IPv6 as well.
4. Apply the rules:
```bash
cd iptables_filters
chmod +x apply_game_rules.sh
sudo ./apply_game_rules.sh apply
```
- To safely preview the rules without applying them, run: `sudo ./apply_game_rules.sh --dry-run`
- To flush (remove) all game rules, run: `sudo ./apply_game_rules.sh flush`

Everything is modular! You can modify `game_config.ini` and re-run the script anytime.

---

## العربية

مرحباً بك في مجموعة أدوات حماية سيرفرات الألعاب المطلقة! حماية سيرفرات الألعاب (مثل CS:GO, Minecraft, Rust, SAMP, MTA, FiveM, TeamSpeak, 7 Days to Die) معقدة جداً لأنها تستخدم بروتوكولات UDP/TCP خاصة لا يمكن حمايتها عبر بروكسي الويب العادي الخاص بـ Cloudflare.

توفر لك هذه الأدوات **حماية بمستوى الشركات الكبرى (Enterprise-Level)** باستخدام طبقتين:
1. **الطبقة الأولى (eBPF/XDP):** تقوم بإعدام الحزم الخبيثة وهجمات إغراق الـ UDP مباشرة في "بطاقة الشبكة" قبل أن تصل حتى إلى نواة لينكس. تستخدم هذه الطبقة خرائط BPF المتقدمة لتتبع الآيبيهات وتحديد معدل الإرسال (Rate Limit) لصد هجمات انتحال الـ IP Spoofing.
2. **الطبقة الثانية (iptables):** فلاتر ذكية تدمج بين الـ Rate Limit الفائق السريع وفحص محتوى الحزمة لسد ثغرات الألعاب (مثل هجمات A2S_INFO، بوتات Minecraft، وهجمات TCP SYN Floods).

### طريقة الاستخدام

#### 1. فلتر XDP (أداء خارق لصد الـ UDP)
ادخل إلى مجلد `xdp_filter/` وقم بتشغيل السكربت. سيقوم ببرمجة الكود وإرفاقه ببطاقة الشبكة الخاصة بك.
```bash
cd xdp_filter
sudo ./load_xdp.sh eth0 load
```
*(استبدل `eth0` باسم كرت الشبكة الخاص بك).*
- لإزالة الفلتر، استخدم الأمر: `sudo ./load_xdp.sh eth0 unload`

#### 2. فلاتر الألعاب الذكية (iptables)
ادخل إلى مجلد `iptables_filters/`.
1. افتح ملف `game_config.ini` بأي محرر نصوص.
2. ضع `ENABLE="true"` للألعاب التي تمتلكها (متوفر FiveM و TS3 والمزيد والمنافذ المخصصة).
3. ضع `ENABLE_IPV6="true"` إذا كان السيرفر الخاص بك يدعم ويستقبل اتصالات IPv6.
4. طبق القواعد فوراً عبر الأمر:
```bash
cd iptables_filters
chmod +x apply_game_rules.sh
sudo ./apply_game_rules.sh apply
```
- لطباعة القواعد ومراجعتها بأمان دون تطبيقها فعلياً (وضع التجربة)، استخدم: `sudo ./apply_game_rules.sh --dry-run`
- لمسح وإلغاء فلاتر الألعاب، استخدم: `sudo ./apply_game_rules.sh flush`

النظام مرن جداً! يمكنك التعديل على ملف `game_config.ini` وإعادة تشغيل السكربت في أي وقت.
