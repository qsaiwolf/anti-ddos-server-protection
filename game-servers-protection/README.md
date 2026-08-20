# Game Server Protection (Anti-DDoS Toolkit)

[العربية](#العربية) | [English](#english)

## English

Welcome to the ultimate Game Server Anti-DDoS toolkit! Protecting game servers (like CS:GO, Minecraft, Rust, SAMP, MTA, etc.) is highly complex because they use custom UDP/TCP protocols that can't be protected by Cloudflare's standard web proxy.

This toolkit provides **Enterprise-Level Protection** using two layers:
1. **Layer 1 (eBPF/XDP):** Drops junk packets and volumetric UDP floods directly at the Network Interface Card (NIC) before they even reach the Linux Kernel. This handles millions of packets per second with almost 0% CPU usage!
2. **Layer 2 (iptables):** Smart application-level filters. It reads the payload of the packets to block specific game exploits (e.g., A2S_INFO query floods for Source Engine, or Fake Player Bot floods for Minecraft).

### How to Use

#### 1. XDP Filter (High-Performance UDP Drop)
Navigate to the `xdp_filter/` folder and run the loader. It will compile the C program and attach it to your network card.
```bash
cd xdp_filter
sudo ./load_xdp.sh eth0
```
*(Replace `eth0` with your actual network interface name if different).*

#### 2. iptables Smart Game Filters
Navigate to the `iptables_filters/` folder.
1. Open `game_config.ini` in any text editor.
2. Change `ENABLE="true"` for the games you host, and verify the ports.
3. Apply the rules:
```bash
cd iptables_filters
chmod +x apply_game_rules.sh
sudo ./apply_game_rules.sh
```

Everything is modular! You can modify `game_config.ini` and re-run the script anytime.

---

## العربية

مرحباً بك في مجموعة أدوات حماية سيرفرات الألعاب المطلقة! حماية سيرفرات الألعاب (مثل CS:GO, Minecraft, Rust, SAMP) معقدة جداً لأنها تستخدم بروتوكولات UDP/TCP خاصة لا يمكن حمايتها عبر بروكسي الويب العادي الخاص بـ Cloudflare.

توفر لك هذه الأدوات **حماية بمستوى الشركات الكبرى (Enterprise-Level)** باستخدام طبقتين:
1. **الطبقة الأولى (eBPF/XDP):** تقوم بإعدام الحزم الخبيثة وهجمات إغراق الـ UDP مباشرة في "بطاقة الشبكة" قبل أن تصل حتى إلى نواة لينكس! هذه التقنية تستطيع صد ملايين الحزم في الثانية باستهلاك معالج (CPU) يكاد يكون 0%.
2. **الطبقة الثانية (iptables):** فلاتر ذكية تقرأ محتوى الحزمة نفسها لصد هجمات مخصصة لألعاب معينة (مثل هجمات A2S_INFO لمحركات Source، أو هجمات البوتات الوهمية في Minecraft).

### طريقة الاستخدام

#### 1. فلتر XDP (أداء خارق لصد الـ UDP)
ادخل إلى مجلد `xdp_filter/` وقم بتشغيل السكربت. سيقوم ببرمجة الكود وإرفاقه ببطاقة الشبكة الخاصة بك.
```bash
cd xdp_filter
sudo ./load_xdp.sh eth0
```
*(استبدل `eth0` باسم كرت الشبكة الخاص بك إذا كان مختلفاً).*

#### 2. فلاتر الألعاب الذكية (iptables)
ادخل إلى مجلد `iptables_filters/`.
1. افتح ملف `game_config.ini` بأي محرر نصوص.
2. ضع `ENABLE="true"` للألعاب التي تمتلكها، وتأكد من أرقام المنافذ.
3. طبق القواعد فوراً عبر الأمر:
```bash
cd iptables_filters
chmod +x apply_game_rules.sh
sudo ./apply_game_rules.sh
```

النظام مرن جداً! يمكنك التعديل على ملف `game_config.ini` وإعادة تشغيل السكربت في أي وقت.
