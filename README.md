# Anti-DDoS HTTP/HTTPS by Cloudflare

[🇪🇬 العربية](#العربية) | [🇬🇧 English](#english)

## English

This repository contains a Bash script to protect your server (Anti-DDoS) by restricting access to web ports (80 and 443) so that they only accept connections from Cloudflare servers, in addition to your own IP address.

### How it works

1. **Applying Rules (The Script):**
   - When you run the script, it installs `iptables-persistent` to save the rules permanently.
   - It adds all Cloudflare IP addresses (IPv4 and IPv6) to the whitelist (`ACCEPT`).
   - It adds your own IP address to the whitelist so you don't lose direct access to the server.
   - Finally, it drops (`DROP`) any other incoming connections to ports 80 and 443.

2. **Cloudflare Setup:**
   - After running the script successfully, go to your [Cloudflare](https://dash.cloudflare.com/) dashboard.
   - Add your domain or link.
   - Enable the Proxy option (the orange cloud icon) in your domain's DNS settings.
   - This way, you can take advantage of all Cloudflare features (protection, caching, etc.), and your server will be protected from direct attacks because it will reject any request that doesn't come through Cloudflare.

### Usage

1. Clone the repository to your server:
   ```bash
   git clone https://github.com/qsaiwolf/antiddos-http-https-by-cloudflare.git
   cd antiddos-http-https-by-cloudflare
   ```

2. Make the script executable:
   ```bash
   chmod +x cloudflare_antiddos.sh
   ```

3. Run the script, passing your IP address as an argument (to allow direct access):
   ```bash
   sudo ./cloudflare_antiddos.sh <YOUR_IP_ADDRESS>
   ```
   **Example:**
   ```bash
   sudo ./cloudflare_antiddos.sh 192.168.1.100
   ```

---

## العربية

هذا المستودع يحتوي على سكربت Bash لحماية الخادم الخاص بك (Anti-DDoS) عن طريق حصر الوصول لمنافذ الويب (80 و 443) بحيث لا تستقبل اتصالات إلا من خوادم Cloudflare، بالإضافة إلى عنوان IP الخاص بك.

### آلية العمل

1. **تفعيل القواعد (السكربت):**
   - عند تشغيل السكربت، سيقوم بتنزيل `iptables-persistent` لحفظ القواعد بشكل دائم.
   - سيقوم بإضافة جميع عناوين IP الخاصة بـ Cloudflare (IPv4 و IPv6) إلى القائمة البيضاء (`ACCEPT`).
   - سيقوم بإضافة عنوان IP الخاص بك إلى القائمة البيضاء حتى لا تفقد القدرة على الاتصال بالخادم.
   - أخيراً، سيقوم بحظر (`DROP`) أي اتصال آخر قادم إلى المنفذين 80 و 443.

2. **التفعيل على Cloudflare:**
   - بعد تشغيل السكربت بنجاح، اذهب إلى لوحة تحكم حسابك في [Cloudflare](https://dash.cloudflare.com/).
   - قم بإضافة نطاقك (Domain) أو الرابط الخاص بك.
   - قم بتفعيل خيار الـ Proxy (الأيقونة البرتقالية ذات السحابة) في إعدادات DNS للنطاق.
   - بهذه الطريقة ستتمكن من الاستفادة من جميع مزايا Cloudflare (حماية، كاش، وغيرها)، وسيكون خادمك محمياً من أي هجوم مباشر لأنه سيرفض أي طلب لا يأتي من خلال Cloudflare.

### طريقة الاستخدام

1. قم بتحميل السكربت إلى خادمك:
   ```bash
   git clone https://github.com/qsaiwolf/antiddos-http-https-by-cloudflare.git
   cd antiddos-http-https-by-cloudflare
   ```

2. أعطِ السكربت صلاحية التنفيذ:
   ```bash
   chmod +x cloudflare_antiddos.sh
   ```

3. قم بتشغيل السكربت مع تمرير عنوان IP الخاص بك كمُعامل (لكي يسمح لك بالوصول المباشر للخادم):
   ```bash
   sudo ./cloudflare_antiddos.sh <YOUR_IP_ADDRESS>
   ```
   **مثال:**
   ```bash
   sudo ./cloudflare_antiddos.sh 192.168.1.100
   ```
