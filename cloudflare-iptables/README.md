# Cloudflare iptables Script

[العربية](#العربية) | [English](#english)

## English

This folder contains a Bash script that configures `iptables` on your server to **only accept HTTP/HTTPS traffic (ports 80 and 443) from Cloudflare IPs**. It also whitelists your personal IP address so you can access the server directly.

### Usage
Run the script as root and pass your IP address as an argument:
```bash
sudo ./cloudflare_antiddos.sh <YOUR_IP_ADDRESS>
```

---

## العربية

هذا المجلد يحتوي على سكربت لإعداد `iptables` بحيث **يسمح بالاتصال بمنافذ الويب (80 و 443) فقط من خوادم Cloudflare**، مع استثناء عنوان IP الخاص بك للسماح لك بالوصول المباشر.

### طريقة الاستخدام
قم بتشغيل السكربت بصلاحيات الرووت ومرر الآي بي الخاص بك:
```bash
sudo ./cloudflare_antiddos.sh <YOUR_IP_ADDRESS>
```
