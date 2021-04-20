#!/bin/sh

systemctl stop reflector.service

pacman -Sy --noconfirm --needed dialog jq

WARN_END=" (cannot be omitted or empty)"

bootstrapper_dialog() {
    DIALOG_RESULT=$(dialog --clear --stdout --backtitle "Arch bootstrapper" --no-shadow --no-cancel "$@" 2>/dev/null)
}

MODES="1 BIOS"
[ -d /sys/firmware/efi ] && MODES="$MODES 2 UEFI"
bootstrapper_dialog --title "MODE" --menu "Please select a boot mode from the following list" 13 70 3 $MODES
[ $? -ne 0 ] || [ -z $DIALOG_RESULT ] && MODE=1 || MODE=$DIALOG_RESULT

DISKS=$(lsblk -J -o path,size --nodeps -I8,259 | jq -r '.blockdevices | .[] | .path,.size')
bootstrapper_dialog --title "Device" --menu "Please select a device from the following list to use for Linux installation." 13 70 3 $DISKS
[ $? -ne 0 ] || [ -z $DIALOG_RESULT ] && echo 'No device selected' && exit 0
DEVICE=$DIALOG_RESULT

if [ $MODE -eq 2 ]; then
    while : ; do
        unset TMP_PASSWORD
        bootstrapper_dialog --title "$title" --cancel --passwordbox "Please enter a strong password for ROOT partition.\n" 8 60
        if [ $? -ne 0 ] || [ -z $DIALOG_RESULT ]; then
            break
        fi
        TMP_PASSWORD="$DIALOG_RESULT"
        bootstrapper_dialog --title "$title" --cancel --passwordbox "Repeat the password.\n" 8 60
        if [ $? -ne 0 ] || [ -z $DIALOG_RESULT ]; then
            break
        fi
        if [ "$TMP_PASSWORD" != "$DIALOG_RESULT" ]; then
            continue
        fi
        ROOT_PART_PASSWORD="$TMP_PASSWORD"
        break
    done
fi

bootstrapper_dialog --title "WARNING" --msgbox "This script will NUKE $DEVICE from orbit.\nPress <Enter> to continue or <Esc> to cancel.\n" 6 60
[ $? -ne 0 ] && (bootstrapper_dialog --title "Cancelled" --msgbox "Script was cancelled at your request." 5 40; exit 0)
bootstrapper_dialog --title "Hostname" --inputbox "Please enter a name for this host.\n" 8 60
HOSTNAME="$DIALOG_RESULT"

TITLE="Root password"
while : ; do
    [ -z $title ] && title=$TITLE
    bootstrapper_dialog --title "$title" --passwordbox "Please enter a strong password for the ROOT user.\n" 8 60
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

NETWORK_SETUP="nmtui"
bootstrapper_dialog --title "WiFi Network setup" --cancel --inputbox "Please enter SSID name.\n" 8 60
if [ $? -eq 0 ] && [ ! -z $DIALOG_RESULT ]; then
    NETWORK_SSID="$DIALOG_RESULT"
    bootstrapper_dialog --title "Network" --inputbox "Please enter '$NETWORK_SSID' password.\n" 8 60
    NETWORK_PASS="$DIALOG_RESULT"
    NETWORK_SETUP="nmcli device wifi connect $NETWORK_SSID password $NETWORK_PASS"
fi

reset

timedatectl set-ntp true

sgdisk --zap-all $DEVICE
sgdisk -o $DEVICE

if [ $MODE -eq 1 ]; then
    echo ';' | sfdisk $DEVICE
    ROOT_PART=$(lsblk -J -o path,name -I8,259  | jq -r ".blockdevices[] | select(.path == \"$DEVICE\") | .children | sort_by(.name) | .[0].path")
else
    sgdisk -n 1:0:+256M -t 1:ef00 -N 2 -t 2:8300 $DEVICE

    EFI_PART=$(lsblk -J -o path,name -I8,259  | jq -r ".blockdevices[] | select(.path == \"$DEVICE\") | .children | sort_by(.name) | .[0].path")
    ROOT_PART=$(lsblk -J -o path,name -I8,259  | jq -r ".blockdevices[] | select(.path == \"$DEVICE\") | .children | sort_by(.name) | .[1].path")

    yes | mkfs.fat -F32 $EFI_PART
fi

if [ ! -z $ROOT_PART_PASSWORD ]; then
    yes "$ROOT_PART_PASSWORD" | cryptsetup -q luksFormat $ROOT_PART
    yes "$ROOT_PART_PASSWORD" | cryptsetup -q --allow-discards open $ROOT_PART luks_root

    yes | mkfs.ext4 -L system /dev/mapper/luks_root
    mount /dev/mapper/luks_root /mnt

    luks_uuid=$(blkid -s UUID -o value /dev/mapper/luks_root)
else
    yes | mkfs.ext4 -L system $ROOT_PART
    mount $ROOT_PART /mnt
fi

if [ $MODE -eq 2 ]; then
    mkdir -p /mnt/boot
    mount $EFI_PART /mnt/boot
fi

type reflector >/dev/null 2>&1 && reflector --sort rate --country Russia -p https --save /etc/pacman.d/mirrorlist

cpu=$(cat /proc/cpuinfo | grep 'vendor' | uniq | awk '{ print $3 }')
case "$cpu" in
"GenuineIntel")
    ucode="intel-ucode"
    ;;
"AuthenticAMD")
    ucode="amd-ucode"
    ;;
*)
    ucode=""
    ;;
esac

yes '' | pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware $ucode
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
useradd -m -g users -G audio,video,power,storage,wheel,scanner -s /bin/fish $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd
curl -L https://raw.githubusercontent.com/devrtc0/archlinux/master/01_system.sh > /home/$USERNAME/01_system.sh
sed -i 's/^#NETWORKMANAGER$/$NETWORK_SETUP/' /home/$USERNAME/01_system.sh
chown $USERNAME:users /home/$USERNAME/01_system.sh
chmod 0700 /home/$USERNAME/01_system.sh
EOF

root_uuid=$(blkid -s UUID -o value $ROOT_PART)

if [ $MODE -eq 1 ]; then
arch-chroot /mnt /bin/sh <<EOF
    pacman -S --noconfirm grub
    grub-install $DEVICE
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
else

OPTIONS=""
if [ ! -z $ROOT_PART_PASSWORD ]; then
    sed -i -e "s/^HOOKS=(.*$/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)/" /mnt/etc/mkinitcpio.conf
    OPTIONS="luks.uuid=${root_uuid} luks.name=luks_root luks.options=allow-discards"
fi

arch-chroot /mnt /bin/sh <<EOF
    bootctl install
    echo 'default arch.conf' > /boot/loader/loader.conf
    echo 'editor 0' >> /boot/loader/loader.conf

    echo 'title Arch' > /boot/loader/entries/arch.conf
    echo 'linux /vmlinuz-linux-lts' >> /boot/loader/entries/arch.conf
    [ ! -z $ucode ] && echo 'initrd /${ucode}.img' >> /boot/loader/entries/arch.conf
    echo 'initrd /initramfs-linux-lts.img' >> /boot/loader/entries/arch.conf
    echo 'options $OPTIONS root=UUID=$luks_uuid rw' >> /boot/loader/entries/arch.conf

    mkinitcpio -P
EOF
fi

umount -R /mnt
