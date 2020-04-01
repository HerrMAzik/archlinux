#!/bin/bash

bootstrapper_dialog() {
    DIALOG_RESULT=$(dialog --clear --stdout --backtitle "Arch bootstrapper" --no-shadow "$@" 2>/dev/null)
}

bootstrapper_dialog --title "WARNING" --msgbox "This script will NUKE /dev/sda from orbit.\nPress <Enter> to continue or <Esc> to cancel.\n" 6 60
[[ $? -ne 0 ]] && (bootstrapper_dialog --title "Cancelled" --msgbox "Script was cancelled at your request." 5 40; exit 0)

bootstrapper_dialog --title "Hostname" --inputbox "Please enter a name for this host.\n" 8 60
hostname="$DIALOG_RESULT"

bootstrapper_dialog --title "Root password" --passwordbox "Please enter a strong password for the root user.\n" 8 60
root_password="$DIALOG_RESULT"

reset

echo ';' | sfdisk /dev/sda
yes | mkfs.ext4 -L system /dev/sda1
mount /dev/sda1 /mnt

sed -i "/yandex/p" -i /etc/pacman.d/mirrorlist
yes '' | pacstrap /mnt base base-devel linux linux-firmware intel-ucode
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
echo "$hostname" > /etc/hostname
echo 'en_US.UTF-8 UTF-8\nen_GB.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8' > /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
ln -s /usr/share/zoneinfo/Europe/Samara /etc/localtime
echo '127.0.0.1   localhost' > /etc/hosts
echo '::1         localhost ip6-localhost ip6-loopback' >> /etc/hosts
echo "127.0.1.1   $hostname" >> /etc/hosts
pacman --noconfirm -S wpa_supplicant dhcpcd
mkinitcpio -P
echo "root:${root_password}" | chpasswd
EOF

arch-chroot /mnt /bin/bash <<EOF
pacman --noconfirm -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

umount /mnt
reboot

