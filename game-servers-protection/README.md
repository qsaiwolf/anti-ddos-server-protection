# Game Server Protection (Anti-DDoS Toolkit)

[العربية](#العربية) | [English](#english)

## English

Welcome to the ultimate Game Server Anti-DDoS toolkit! Protecting game servers (like CS:GO, Minecraft, Rust, SAMP, MTA, FiveM, TeamSpeak 3, 7 Days to Die) is highly complex because they use custom UDP/TCP protocols that can't be protected by Cloudflare's standard web proxy.

This toolkit provides **Enterprise-Level Protection** using two layers:
1. **Layer 1 (eBPF/XDP):** Drops junk packets and volumetric UDP floods directly at the Network Interface Card (NIC) before they even reach the Linux Kernel. It uses advanced BPF maps to track and rate-limit IPs, thwarting IP Spoofing.
2. **Layer 2 (iptables):** Smart application-level filters. It uses fast rate-limiting combined with payload string-matching to block specific game exploits (e.g., A2S_INFO query floods, Minecraft bots, TCP SYN floods).

### How to Use

The toolkit is unified under a single, easy-to-use CLI tool called `game-shield.sh`.

#### Configuration First
1. Open `iptables_filters/game_config.ini` in any text editor.
2. Change `ENABLE="true"` for the games you host (CS:GO, Minecraft, SAMP, FiveM, TS3, Custom Ports).
3. Set your `WHITELIST_IPS` if you have trusted admins.
4. Set `ENABLE_IPV6="true"` if your server listens on IPv6.

#### Start the Shield
```bash
chmod +x game-shield.sh
sudo ./game-shield.sh start eth0
```
*(Replace `eth0` with your network interface).*

#### Helpful Commands
- **Check Status (Live Dropped Packets):** `sudo ./game-shield.sh status`
- **Self-Test (Simulate Attack):** `sudo ./game-shield.sh test`
- **Preview Rules:** `sudo ./game-shield.sh dry-run`
- **Stop & Flush:** `sudo ./game-shield.sh stop`

> **📚 For real-world usage scenarios, read [EXAMPLES.md](EXAMPLES.md)**

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

### طريقة الاستخدام

الآن أصبح استخدام المنظومة بالكامل مدمجاً في سطر أوامر موحد وسهل جداً عبر سكربت `game-shield.sh`.

#### أولاً: ضبط الإعدادات
1. افتح ملف `iptables_filters/game_config.ini` بأي محرر نصوص.
2. ضع `ENABLE="true"` للألعاب التي تمتلكها (متوفر FiveM و TS3 والمزيد والمنافذ المخصصة).
3. أضف عناوين الـ IP الخاصة بالأدمن في `WHITELIST_IPS` لضمان عدم حظرهم أبدًا.
4. ضع `ENABLE_IPV6="true"` إذا كان السيرفر يدعم IPv6.

#### ثانياً: تشغيل درع الحماية
```bash
chmod +x game-shield.sh
sudo ./game-shield.sh start eth0
```
*(استبدل `eth0` باسم كرت الشبكة الخاص بك).*

#### أوامر هامة للتحكم:
- **معرفة حالة السيرفر وعدد الحزم المسقطة مباشرة:** `sudo ./game-shield.sh status`
- **تشغيل اختبار ذاتي (للتأكد من صد الهجمات):** `sudo ./game-shield.sh test`
- **مراجعة القواعد قبل تطبيقها:** `sudo ./game-shield.sh dry-run`
- **إيقاف جميع الحمايات (مسح):** `sudo ./game-shield.sh stop`

> **📚 لتعلم كيفية استخدامه في سيناريوهات واقعية، اقرأ ملف [EXAMPLES.md](EXAMPLES.md)**

النظام مرن جداً! يمكنك التعديل على ملف `game_config.ini` وإعادة تشغيل السكربت في أي وقت.
