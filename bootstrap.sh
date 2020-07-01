#!/bin/sh

WARN_END=" (cannot be omitted or empty)"

bootstrapper_dialog() {
    DIALOG_RESULT=$(dialog --clear --stdout --backtitle "Arch bootstrapper" --no-shadow --no-cancel "$@" 2>/dev/null)
}

MODES="1 BIOS"
[ -d /sys/firmware/efi ] && MODES="$MODES 2 UEFI"
bootstrapper_dialog --title "MODE" --menu "Please select a boot mode from the following list" 13 70 3 $MODES
[ $? -ne 0 ] || [ -z $DIALOG_RESULT ] && MODE=1 || MODE=$DIALOG_RESULT

DISKS=$(lsblk --nodeps -n -o path,size -I8,259 | awk '{print $1" "$2}' ORS=' ')
bootstrapper_dialog --title "Device" --menu "Please select a device from the following list to use for Linux installation." 13 70 3 $DISKS
[ $? -ne 0 ] || [ -z $DIALOG_RESULT ] && echo 'No device selected' && exit 0
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

DESKTOP_ENVS="gnome GNOME kde KDE"
bootstrapper_dialog --title "DE" --menu "Please select a desktop environment" 13 70 3 $DESKTOP_ENVS
[ $? -ne 0 ] || [ -z $DIALOG_RESULT ] && DESKTOP_ENV=gnome || DESKTOP_ENV=$DIALOG_RESULT

reset

timedatectl set-ntp true

if [ $MODE -eq 1 ]; then
    echo ';' | sfdisk $DEVICE
    yes | mkfs.ext4 -L system "${DEVICE}1"
    mount "${DEVICE}1" /mnt
else
    sgdisk --zap-all $DEVICE
    sgdisk -o $DEVICE
    sgdisk -n 1:0:+128M -t 1:ef00 $DEVICE
    sgdisk -N 2 -t 2:8300 $DEVICE

    mkfs.fat -F32 "${DEVICE}1"
    mkfs.ext4 -L system "${DEVICE}2"

    mount "${DEVICE}2" /mnt
fi

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
hwclock --systohc --utc
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
sed -i "s/##${DESKTOP_ENV}##//g" /home/$USERNAME/system.sh
chown $USERNAME:users /home/$USERNAME/system.sh
chmod 0700 /home/$USERNAME/system.sh
EOF

arch-chroot /mnt /bin/sh <<EOF
pacman --noconfirm -S grub
[ $MODE -eq 2 ] && pacman --noconfirm -S efibootmgr
[ $MODE -eq 2 ] && mkdir -p /ife && mount "${DEVICE}1" /ife
[ $MODE -eq 1 ] && grub-install
[ $MODE -eq 2 ] && grub-install --target=x86_64-efi --efi-directory=/ife --bootloader-id=GRUB --removable
grub-mkconfig -o /boot/grub/grub.cfg
EOF

umount -R /mnt
