# Anti-DDoS & Server Protection Mechanisms

[العربية](#العربية) | [English](#english)

## English

This repository contains various tools and scripts to protect your server from DDoS attacks, unauthorized access, and malicious bots. 

We have organized the protections into three independent categories. You can choose to use any of them depending on your needs. Please click on the links below to read the detailed instructions for each type:

### 1. [Cloudflare iptables Whitelist](./cloudflare-iptables/)
A script that configures your server firewall to **only accept HTTP/HTTPS traffic (ports 80 and 443) from Cloudflare servers**, preventing attackers from bypassing Cloudflare to hit your server directly.

### 2. [Cloudflare WAF & Rate Limiting Rules](./cloudflare-waf-rules/)
Recommended configurations for your Cloudflare Dashboard. These rules are designed to block bad bots, mitigate layer 7 (HTTP Flood) attacks, and rate-limit suspicious traffic before it even reaches your server.

### 3. [Dynamic IP Port Allow (DDNS)](./allow-dynamic-ip-port/)
A script that secures any port (like SSH port 22) by only allowing connections from your constantly changing home IP address. It uses a dynamic DNS (DDNS) service to automatically update your firewall rules every minute.

---

## العربية

هذا المستودع يحتوي على أدوات وسكربتات متنوعة لحماية الخادم الخاص بك من هجمات الحرمان من الخدمة (DDoS)، والوصول غير المصرح به، والبوتات الخبيثة.

لقد قمنا بتنظيم آليات الحماية في ثلاثة أقسام مستقلة. يمكنك اختيار استخدام أي منها حسب احتياجاتك. يرجى الضغط على الروابط أدناه لقراءة التعليمات التفصيلية لكل نوع:

### 1. [سكربت حصر الاتصال بخوادم Cloudflare](./cloudflare-iptables/)
سكربت يقوم ببرمجة الجدار الناري لخادمك بحيث **يستقبل اتصالات الويب (المنافذ 80 و 443) حصراً من خوادم Cloudflare**، مما يمنع المهاجمين من تجاوز كلاودفلير وضرب الخادم بشكل مباشر.

### 2. [قواعد حماية Cloudflare WAF وتقييد الطلبات](./cloudflare-waf-rules/)
إعدادات وقواعد نوصي بوضعها في لوحة تحكم Cloudflare الخاصة بك. هذه القواعد مصممة لحظر البوتات الخبيثة، وصد هجمات إغراق السيرفر (DDoS Layer 7)، وتقييد حركة المرور المشبوهة قبل أن تصل لخادمك أساساً.

### 3. [حماية المنافذ للـ IP المتغير (DDNS)](./allow-dynamic-ip-port/)
سكربت لحماية أي منفذ في خادمك (مثل منفذ SSH 22) عن طريق السماح بالاتصال به فقط من عنوان الـ IP الخاص بمنزلك (حتى لو كان يتغير باستمرار). يستخدم السكربت خدمة DDNS لتحديث قواعد الجدار الناري تلقائياً كل دقيقة لضمان عدم انقطاع اتصالك وبنفس الوقت إغلاق المنفذ عن العالم.
