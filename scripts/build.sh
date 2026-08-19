#!/bin/bash
set -e
set -x

export DEBIAN_FRONTEND=noninteractive

# Устанавливаем переменные
CHROOT_DIR="custom-os"
IMAGE_NAME="CustomOS.iso"
STAGING_DIR="staging"

echo "[*] Step 1: Bootstrap Ubuntu 24.04 (Noble)"
# Скачиваем базовую систему Ubuntu
sudo debootstrap --arch=amd64 --variant=minbase noble $CHROOT_DIR http://archive.ubuntu.com/ubuntu/

echo "[*] Step 2: Mount virtual filesystems"
sudo mount --bind /dev $CHROOT_DIR/dev
sudo mount --bind /run $CHROOT_DIR/run
sudo mount -t proc /proc $CHROOT_DIR/proc
sudo mount -t sysfs /sys $CHROOT_DIR/sys

echo "[*] Step 3: Copy customization script and assets into chroot"
sudo cp scripts/customize.sh $CHROOT_DIR/tmp/
sudo chmod +x $CHROOT_DIR/tmp/customize.sh
sudo cp -r assets $CHROOT_DIR/tmp/

# Копируем настройки DNS, чтобы работал интернет внутри chroot
sudo cp /etc/resolv.conf $CHROOT_DIR/etc/

echo "[*] Step 4: Chroot and customize!"
sudo chroot $CHROOT_DIR /tmp/customize.sh

echo "[*] Step 5: Clean up virtual filesystems"
sudo umount $CHROOT_DIR/sys
sudo umount $CHROOT_DIR/proc
sudo umount $CHROOT_DIR/run
sudo umount $CHROOT_DIR/dev
sudo rm -rf $CHROOT_DIR/tmp/*

echo "[*] Step 6: Create SquashFS"
mkdir -p $STAGING_DIR/casper
sudo mksquashfs $CHROOT_DIR $STAGING_DIR/casper/filesystem.squashfs -b 1048576 -comp xz -Xdict-size 100%

echo "[*] Step 7: Prepare bootloader and kernel"
# Копируем ядро и initrd из chroot в staging
sudo cp $CHROOT_DIR/boot/vmlinuz-* $STAGING_DIR/casper/vmlinuz
sudo cp $CHROOT_DIR/boot/initrd.img-* $STAGING_DIR/casper/initrd

# Создаем GRUB конфиг
mkdir -p $STAGING_DIR/boot/grub
cat <<EOF | sudo tee $STAGING_DIR/boot/grub/grub.cfg
search --set=root --file /casper/vmlinuz
insmod all_video
set default="0"
set timeout=5
menuentry "Start Custom Hacker OS (Live)" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}
EOF

echo "[*] Step 8: Create ISO"
sudo grub-mkrescue -o $IMAGE_NAME $STAGING_DIR/

echo "[*] Done! $IMAGE_NAME has been created."
