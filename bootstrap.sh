#!/bin/sh

bootstrapper_dialog() {
    DIALOG_RESULT=$(dialog --clear --stdout --backtitle "Arch bootstrapper" --no-shadow "$@" 2>/dev/null)
}

bootstrapper_dialog --title "WARNING" --msgbox "This script will NUKE /dev/sda from orbit.\nPress <Enter> to continue or <Esc> to cancel.\n" 6 60
[[ $? -ne 0 ]] && (bootstrapper_dialog --title "Cancelled" --msgbox "Script was cancelled at your request." 5 40; exit 0)

bootstrapper_dialog --title "Hostname" --inputbox "Please enter a name for this host.\n" 8 60
hostname="$DIALOG_RESULT"

bootstrapper_dialog --title "Root password" --passwordbox "Please enter a strong password for the root user.\n" 8 60
root_password="$DIALOG_RESULT"

bootstrapper_dialog --title "User name" --inputbox "Please enter a user name.\n" 8 60
user_name="$DIALOG_RESULT"

bootstrapper_dialog --title "$user_name password" --passwordbox "Please enter a strong password for ${user_name}.\n" 8 60
user_password="$DIALOG_RESULT"

reset

echo ';' | sfdisk /dev/sda
yes | mkfs.ext4 -L system /dev/sda1
mount /dev/sda1 /mnt

sed -n "/yandex/p" -i /etc/pacman.d/mirrorlist
yes '' | pacstrap /mnt base base-devel linux linux-firmware intel-ucode
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
echo "$hostname" > /etc/hostname
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
cat << EOF2 > /etc/hosts
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
127.0.1.1   $hostname
EOF2
pacman --noconfirm -S networkmanager dnscrypt-proxy zsh
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF2 > /etc/NetworkManager/conf.d/dns-servers.conf
[global-dns-domain-*]
servers=127.0.0.1
EOF2
mkinitcpio -P
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
echo "root:${root_password}" | chpasswd
useradd -m -g users -G audio,video,power,storage,wheel -s /bin/zsh $user_name
echo "${user_name}:${user_password}" | chpasswd
curl -L https://git.io/JvbT6 > /home/$user_name/config.sh
chown ${user_name}:users /home/$user_name/config.sh
chmod 0700 /home/$user_name/config.sh
EOF

arch-chroot /mnt /bin/bash <<EOF
pacman --noconfirm -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

umount /mnt
