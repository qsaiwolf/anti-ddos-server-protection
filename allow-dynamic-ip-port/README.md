# Dynamic IP Port Allow (DDNS)

[العربية](#العربية) | [English](#english)

## English

This folder contains a script that protects a specific port (like SSH port 22) by only allowing connections from a dynamic IP address that is constantly updated via a DDNS (Dynamic DNS) domain.

### ⚠️ Warning
> [!CAUTION]
> **Do not run this script if you don't understand how it works!** If your DDNS service fails to update your IP, or if you provide the wrong domain, you will be permanently locked out of your server on that port (e.g., you won't be able to SSH into it). Always make sure you have an alternative way to access your server (like a web console / VNC provided by your hosting provider) before applying this.

### Mechanism
If you have a dynamic IP at home (it changes constantly) but you want to protect your server's SSH port from the internet, you can use a free DDNS service (like DuckDNS). 
The script you run here will:
1. Generate an auto-updater script in your server.
2. Setup a `cron` job that runs every minute to resolve your DDNS domain to your current home IP.
3. Automatically update `iptables` to allow your new IP and drop everything else on that port.

### Usage
Run the script with your DDNS domain and the port you want to protect. (If you don't provide a port, it defaults to 22).

```bash
chmod +x dynamic_port_allow.sh
sudo ./dynamic_port_allow.sh <YOUR_DDNS_DOMAIN> [PORT]
```

**Example:**
```bash
sudo ./dynamic_port_allow.sh myhome.duckdns.org 22
```

The script is fully automated; it will install required tools, generate the updater, and schedule it in the background!

---

## العربية

يحتوي هذا المجلد على سكربت لحماية منفذ معين (مثل منفذ SSH 22) عن طريق السماح بالاتصال فقط من عنوان IP ديناميكي (متغير) يتم تحديثه باستمرار عبر نطاق DDNS (مثل DuckDNS).

### ⚠️ تحذير هام
> [!CAUTION]
> **لا تقم بتشغيل هذا السكربت إن لم تكن تفهم آلية عمله تماماً!** إذا توقفت خدمة الـ DDNS عن تحديث الـ IP الخاص بك، أو إذا قمت بإدخال نطاق خاطئ، فسيتم حظرك نهائياً من دخول السيرفر عبر ذلك المنفذ (مثلاً لن تتمكن من الدخول عبر SSH). تأكد دائماً أن لديك طريقة بديلة للدخول إلى السيرفر (مثل الـ Web Console أو VNC من لوحة تحكم الاستضافة) قبل تفعيل هذه الحماية.

### آلية العمل
إذا كان عنوان IP الخاص بمنزلك متغيراً ولكنك ترغب في حماية منفذ SSH في الخادم الخاص بك بحيث لا يفتح للجميع، يمكنك استخدام خدمة DDNS.
هذا السكربت سيقوم بالآتي:
1. إنشاء سكربت تحديث تلقائي داخل السيرفر.
2. إضافة مهمة مجدولة (`cron job`) تعمل كل دقيقة لفحص النطاق الخاص بك وجلب عنوان IP منزلك الحالي.
3. تحديث قواعد الجدار الناري `iptables` تلقائياً للسماح للآي بي الجديد الخاص بك بالدخول وإغلاق المنفذ أمام أي شخص آخر.

### طريقة الاستخدام
قم بتشغيل السكربت مع تمرير نطاق الـ DDNS الخاص بك والمنفذ الذي تود حمايته. (إذا لم تمرر منفذ، سيتم حماية المنفذ 22 بشكل افتراضي).

```bash
chmod +x dynamic_port_allow.sh
sudo ./dynamic_port_allow.sh <YOUR_DDNS_DOMAIN> [PORT]
```

**مثال:**
```bash
sudo ./dynamic_port_allow.sh myhome.duckdns.org 22
```

السكربت يعمل بشكل آلي بالكامل (Auto)، سيقوم بتثبيت الأدوات اللازمة، وإنشاء المُحَدِّث، وإضافته في الخلفية للعمل كل دقيقة!
