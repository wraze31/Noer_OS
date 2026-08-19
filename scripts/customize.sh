#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
export HOME=/root

echo "=> Настройка источников (sources.list)..."
cat <<EOF > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

echo "=> Обновление пакетов..."
apt-get update
apt-get upgrade -y

echo "=> Установка ядра и утилит Live-загрузки (casper)..."
apt-get install -y linux-image-generic initramfs-tools casper dbus systemd-sysv

echo "=> Установка легковесного графического окружения (XFCE4)..."
apt-get install -y xfce4 xfce4-goodies lightdm xorg pulseaudio network-manager-gnome 

echo "=> Установка хакерского софта и зависимостей..."
apt-get install -y nmap wireshark aircrack-ng git curl wget vim python3 python3-pip htop nano iproute2 net-tools unzip

echo "=> Установка Metasploit..."
curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall || echo "Ошибка при установке MSF, пропускаем..."
rm msfinstall

echo "=> Установка кастомных скриптов (Noer OSINT)..."
mkdir -p /opt/osint
cat <<EOF > /opt/osint/welcome.txt
Добро пожаловать в Noer OS!
Система загружена и готова к работе.
EOF

echo "=> Настройка внешнего вида..."
# Устанавливаем красивую темную тему (Greybird/Adwaita-dark)
apt-get install -y greybird-gtk-theme adwaita-icon-theme
mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/
# Базовый конфиг темы
cat <<EOF > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird-dark"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
</channel>
EOF

echo "=> Настройка автологина для Live-пользователя..."
# Создаем кастомного пользователя 'noer'
useradd -m -s /bin/bash noer
usermod -aG sudo noer
echo "noer:kali" | chpasswd
# Настройка LightDM для автологина
cat <<EOF > /etc/lightdm/lightdm.conf.d/50-autologin.conf
[Seat:*]
autologin-user=noer
autologin-user-timeout=0
EOF

echo "=> Очистка мусора..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/*

echo "=> Кастомизация завершена успешно!"
