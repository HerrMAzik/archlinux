#!/bin/sh

# openssl passwd -6 <password>

KERNEL="linux-lts"
DEVICE="/dev/sda"
HOSTNAME="man"
USERNAME="azat"

systemctl stop reflector.service
timedatectl set-ntp true

sgdisk --zap-all $DEVICE
sgdisk -o $DEVICE
sgdisk -n 1:0:+256M -t 1:ef00 -N 2 -t 2:8300 $DEVICE
yes | mkfs.fat -F32 "${DEVICE}1"
yes | mkfs.ext4 -L system "${DEVICE}2"
mount "${DEVICE}2" /mnt
mkdir -p /mnt/boot
mount "${DEVICE}1" /mnt/boot

echo 'Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

yes '' | pacstrap /mnt base base-devel "$KERNEL" "${KERNEL}-headers" linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

ROOT_PASSWORD='$6$6bmFd/d4LyAR2iMq$a8gqrfAzUDggFB1G4uYuYzuzlhdanEUIwt13/8gs7Q3.wFEAKR9K8guWqCjQg0PcA5hSyx8d/NmRhXLkZANaZ1'
USER_PASSWORD='$6$6bmFd/d4LyAR2iMq$a8gqrfAzUDggFB1G4uYuYzuzlhdanEUIwt13/8gs7Q3.wFEAKR9K8guWqCjQg0PcA5hSyx8d/NmRhXLkZANaZ1'

arch-chroot /mnt /bin/bash <<EOF
echo "$HOSTNAME" > /etc/hostname

cat << EOF2 > /etc/locale.gen
en_US.UTF-8 UTF-8
en_GB.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8
EOF2

locale-gen
export LANG=en_US.UTF-8
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
ln -s /usr/share/zoneinfo/Europe/Samara /etc/localtime
hwclock --systohc --utc

cat << EOF2 > /etc/hosts
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF2

pacman --noconfirm -S networkmanager fish

echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
echo 'root:$ROOT_PASSWORD' | chpasswd -e
useradd -m -g users -G audio,video,power,storage,wheel,scanner -p '$USER_PASSWORD' -s /bin/fish $USERNAME

curl -L https://raw.githubusercontent.com/devrtc0/archlinux/master/01_system.sh > /home/$USERNAME/01_system.sh
chown $USERNAME:users /home/$USERNAME/01_system.sh
chmod 0700 /home/$USERNAME/01_system.sh
EOF

root_uuid=$(blkid -s UUID -o value "${DEVICE}2")
OPTIONS="root=UUID=$root_uuid mitigations=off"
sed -i -e "s/^HOOKS=(.*$/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block filesystems fsck)/" /mnt/etc/mkinitcpio.conf

arch-chroot /mnt /bin/sh <<EOF
    bootctl install

cat <<EOF2 > /boot/loader/loader.conf
default arch.conf
editor 0
EOF2

cat <<EOF2 > /boot/loader/entries/arch.conf
title Arch
linux /vmlinuz-$KERNEL
initrd /initramfs-${KERNEL}.img
options $OPTIONS
EOF2

    mkinitcpio -P
EOF

umount -R /mnt
