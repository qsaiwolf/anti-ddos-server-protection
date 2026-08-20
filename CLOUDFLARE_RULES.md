# Cloudflare WAF & Rate Limiting Rules / قواعد حماية كلاودفلير

[العربية](#العربية) | [English](#english)

## English

Here are the recommended Cloudflare Security rules to protect your application from malicious bots and layer 7 DDoS attacks. 

You need to add these rules in your Cloudflare dashboard under **Security** -> **WAF**.

### 1. WAF Custom Rule: Allow Known Bots & Specific IPs (Skip Rule)
This rule ensures that good bots (like Googlebot) and your trusted IP addresses bypass all security challenges.

- **Rule Name:** `ips skips & Allow Known bots`
- **Expression:** 
  ```text
  (cf.client.bot) or (ip.src eq 192.168.1.1) or (ip.src eq 10.0.0.1)
  ```
- **Action:** `Skip`
- **WAF components to skip:** Check ALL options.
- **Execution Order:** `First`

### 2. WAF Custom Rule: Block Malicious User Agents
This rule blocks or challenges bad actors, scrapers, and scripts that commonly attack websites.

- **Rule Name:** `Block Bad UAs`
- **Expression:** 
  ```text
  (http.user_agent contains "python") or (http.user_agent contains "wget") or (http.user_agent contains "Wget") or (http.user_agent contains "node") or (http.user_agent contains "Check") or (http.user_agent contains "golang") or (http.user_agent eq "go") or (http.user_agent contains "curl") or (http.user_agent contains "Python") or (http.user_agent contains "BlackBerry9530") or (http.user_agent contains "BlackBerry")
  ```
- **Action:** `Managed Challenge` (or `Block`)
- **Execution Order:** `Custom` (Select to fire AFTER the `ips skips & Allow Known bots` rule).

### 3. Rate Limiting Rule: Protect Against Flooding
This rule prevents HTTP flood attacks by limiting the number of requests a single IP can make within a time frame.

- **Rule Name:** `Rate Limit All Traffic`
- **Expression:**
  ```text
  (http.request.uri.path eq "/") or (http.request.uri.path contains "/")
  ```
- **When rate exceeds:** `200` requests per `10` seconds.
- **Then take action:** `Block`
- **For duration:** `10` seconds (or minutes based on your preference).

---

## العربية

فيما يلي قواعد الحماية الموصى بها في Cloudflare لحماية تطبيقك من البوتات الخبيثة وهجمات حجب الخدمة (DDoS) من الطبقة السابعة.

يجب عليك إضافة هذه القواعد في لوحة تحكم Cloudflare تحت قسم **Security** ثم **WAF**.

### 1. القاعدة الأولى: السماح للبوتات المعروفة وعناوين IP محددة (تخطي الحماية)
تضمن هذه القاعدة أن البوتات الجيدة (مثل محركات البحث) وعناوين IP الموثوقة الخاصة بك يمكنها تخطي جميع تحديات الأمان.

- **اسم القاعدة (Rule Name):** `ips skips & Allow Known bots`
- **التعبير (Expression):** 
  ```text
  (cf.client.bot) or (ip.src eq 192.168.1.1) or (ip.src eq 10.0.0.1)
  ```
- **الإجراء (Action):** `Skip`
- **المكونات المراد تخطيها (WAF components to skip):** قم بتحديد جميع الخيارات.
- **ترتيب التنفيذ (Execution Order):** `First`

### 2. القاعدة الثانية: حظر المتصفحات والأدوات الخبيثة (User Agents)
تقوم هذه القاعدة بحظر أو تحدي السكربتات والأدوات المبرمجة التي عادةً ما تستخدم للهجوم على المواقع.

- **اسم القاعدة (Rule Name):** `Block Bad UAs`
- **التعبير (Expression):** 
  ```text
  (http.user_agent contains "python") or (http.user_agent contains "wget") or (http.user_agent contains "Wget") or (http.user_agent contains "node") or (http.user_agent contains "Check") or (http.user_agent contains "golang") or (http.user_agent eq "go") or (http.user_agent contains "curl") or (http.user_agent contains "Python") or (http.user_agent contains "BlackBerry9530") or (http.user_agent contains "BlackBerry")
  ```
- **الإجراء (Action):** `Managed Challenge` (أو `Block`)
- **ترتيب التنفيذ (Execution Order):** `Custom` (قم باختيار أن يتم تنفيذها **بعد** القاعدة الأولى `ips skips`).

### 3. قاعدة تقييد المعدل (Rate Limiting)
تمنع هذه القاعدة هجمات إغراق السيرفر (HTTP Flood) عن طريق تحديد عدد الطلبات التي يمكن أن يرسلها IP واحد خلال فترة زمنية.

- **اسم القاعدة (Rule Name):** `Rate Limit All Traffic`
- **التعبير (Expression):**
  ```text
  (http.request.uri.path eq "/") or (http.request.uri.path contains "/")
  ```
- **عند تجاوز المعدل (When rate exceeds):** `200` طلب لكل `10` ثوانٍ.
- **الإجراء (Then take action):** `Block`
- **لمدة (For duration):** `10` ثوانٍ (أو دقائق حسب الرغبة).
