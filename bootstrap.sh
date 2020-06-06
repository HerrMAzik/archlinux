#!/bin/sh

bootstrapper_dialog() {
    DIALOG_RESULT=$(dialog --clear --stdout --backtitle "Arch bootstrapper" --no-shadow "$@" 2>/dev/null)
}

WARN_END=" (cannot be omitted ot empty)"

OLDIFS=$IFS
IFS=":"
DISKS=$(lsblk --nodeps -n -o path,size -I8,259 | awk '{print $1":"$2}' ORS=':')
bootstrapper_dialog --title "Device" --menu "Please select a device from the following list to use for Linux installation." 13 70 3 $DISKS
[ $? -ne 0 ] || [ -z $DIALOG_RESULT ] && echo 'No device selected' && exit 0
IFS=$OLDIFS
DEVICE=$DIALOG_RESULT

bootstrapper_dialog --title "WARNING" --msgbox "This script will NUKE $DEVICE from orbit.\nPress <Enter> to continue or <Esc> to cancel.\n" 6 60
[ $? -ne 0 ] && (bootstrapper_dialog --title "Cancelled" --msgbox "Script was cancelled at your request." 5 40; exit 0)
bootstrapper_dialog --title "Hostname" --inputbox "Please enter a name for this host.\n" 8 60
HOSTNAME="$DIALOG_RESULT"

TITLE="Root password"
while : ; do
    [ -z $title ] && title=$TITLE
    bootstrapper_dialog --title "$title" --passwordbox "Please enter a strong password for the root user.\n" 8 60
    [ $? -eq 0 ] && [ ! -z $DIALOG_RESULT ] && unset title && break
    title="$TITLE$WARN_END"
done
ROOT_PASSWORD="$DIALOG_RESULT"

TITLE="User name"
while : ; do
    [ -z $title ] && title=$TITLE
    bootstrapper_dialog --title "$title" --inputbox "Please enter a user name.\n" 8 60
    [ $? -eq 0 ] && [ ! -z $DIALOG_RESULT ] && unset title && break
    title="$TITLE$WARN_END"
done
USERNAME="$DIALOG_RESULT"

TITLE="$USERNAME password"
while : ; do
    [ -z $title ] && title=$TITLE
    bootstrapper_dialog --title "$title" --passwordbox "Please enter a strong password for $USERNAME.\n" 8 60
    [ $? -eq 0 ] && [ ! -z $DIALOG_RESULT ] && unset title && break
    title="$TITLE$WARN_END"
done
USER_PASSWORD="$DIALOG_RESULT"

reset

export LANG=en_US.UTF-8

echo ';' | sfdisk /dev/sda
yes | mkfs.ext4 -L system /dev/sda1
mount /dev/sda1 /mnt

sed -n "/yandex/p" -i /etc/pacman.d/mirrorlist
yes '' | pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

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
cat << EOF2 > /etc/hosts
127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF2
pacman --noconfirm -S networkmanager fish
mkinitcpio -P
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
echo "root:$ROOT_PASSWORD" | chpasswd
useradd -m -g users -G audio,video,power,storage,wheel -s /bin/fish $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd
curl -L https://raw.githubusercontent.com/HerrMAzik/archlinux/master/system.sh > /home/$USERNAME/system.sh
chown $USERNAME:users /home/$USERNAME/system.sh
chmod 0700 /home/$USERNAME/system.sh
EOF

arch-chroot /mnt /bin/sh <<EOF
pacman --noconfirm -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

umount /mnt
