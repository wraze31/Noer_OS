#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

echo "=> Настройка источников..."
cat <<EOF > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

apt-get update
apt-get upgrade -y

echo "=> Установка базы..."
apt-get install -y linux-image-generic initramfs-tools casper dbus systemd-sysv

echo "=> Установка KDE Plasma (Красивая графика) и драйверов..."
apt-get install -y kde-plasma-desktop sddm konsole dolphin kate plasma-nm xserver-xorg-video-all xserver-xorg-input-all pulseaudio

echo "=> Установка хакерского софта и OSINT-инструментов..."
apt-get install -y nmap wireshark aircrack-ng git curl wget vim python3 python3-pip htop nano iproute2 net-tools unzip sqlmap john hydra nikto

# Установка OSINT утилит
pip3 install spiderfoot sherlock --break-system-packages || true

curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall || true
rm msfinstall

echo "=> Настройка пользователя и автологина..."
cat <<EOF > /etc/casper.conf
export USERNAME="noer"
export USERFULLNAME="Noer OS"
export HOST="noeros"
export BUILD_SYSTEM="Ubuntu"
EOF

useradd -m -s /bin/bash noer
usermod -aG sudo noer
echo "noer:kali" | chpasswd

mkdir -p /etc/sddm.conf.d
cat <<EOF > /etc/sddm.conf.d/autologin.conf
[Autologin]
User=noer
Session=plasma
EOF

mkdir -p /usr/share/backgrounds/
if [ -f /tmp/assets/wallpaper.jpg ]; then
    cp /tmp/assets/wallpaper.jpg /usr/share/backgrounds/noer_wallpaper.jpg
fi

echo "=> Очистка мусора..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/*

echo "=> Кастомизация завершена!"
