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

echo "=> Установка полноценного рабочего стола XFCE и драйверов экрана..."
# xubuntu-core ставит правильные драйвера экрана, дисплейный менеджер и всё для XFCE
apt-get install -y xubuntu-core xserver-xorg-video-all xserver-xorg-input-all

echo "=> Установка хакерского софта..."
apt-get install -y nmap wireshark aircrack-ng git curl wget vim python3 python3-pip htop nano iproute2 net-tools unzip

echo "=> Установка Metasploit..."
curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall || echo "Ошибка при установке MSF, пропускаем..."
rm msfinstall

echo "=> Настройка внешнего вида (Greybird/Adwaita)..."
apt-get install -y greybird-gtk-theme adwaita-icon-theme xfce4-terminal lightdm-gtk-greeter-settings

# Переносим обои
mkdir -p /usr/share/backgrounds
if [ -f /tmp/assets/wallpaper.jpg ]; then
    cp /tmp/assets/wallpaper.jpg /usr/share/backgrounds/noer_wallpaper.jpg
    WALLPAPER_PATH="/usr/share/backgrounds/noer_wallpaper.jpg"
else
    WALLPAPER_PATH="#000000"
fi

# Меняем фиолетовый экран загрузки на наш стиль
cat <<EOF > /etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
background = $WALLPAPER_PATH
theme-name = Greybird-dark
icon-theme-name = Adwaita
hide-user-image = true
EOF

echo "=> Создание хакера-пользователя noer..."
useradd -m -s /bin/bash noer
usermod -aG sudo noer
echo "noer:kali" | chpasswd

echo "=> Настройка LightDM для автологина без пароля..."
mkdir -p /etc/lightdm/lightdm.conf.d
cat <<EOF > /etc/lightdm/lightdm.conf.d/50-autologin.conf
[Seat:*]
autologin-user=noer
autologin-user-timeout=0
user-session=xubuntu
EOF

echo "=> Настройка интерфейса XFCE для пользователя noer..."
mkdir -p /home/noer/.config/xfce4/xfconf/xfce-perchannel-xml/
mkdir -p /home/noer/.config/xfce4/terminal/

# Настройка тёмной темы XFCE
cat <<EOF > /home/noer/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird-dark"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
</channel>
EOF

# Настройка обоев рабочего стола
cat <<EOF > /home/noer/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/noer_wallpaper.jpg"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# Настройка прозрачного хакерского терминала
cat <<EOF > /home/noer/.config/xfce4/terminal/terminalrc
[Configuration]
ColorForeground=#ffffff
ColorBackground=#000000
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.85
FontName=Monospace 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=TRUE
EOF

# Выдаем права пользователю на его конфиги
chown -R noer:noer /home/noer/.config

echo "=> Очистка мусора..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/*

echo "=> Кастомизация завершена успешно!"
