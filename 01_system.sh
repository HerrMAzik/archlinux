#!/usr/bin/env bash

[ -z "$XDG_CONFIG_HOME" ] && XDG_CONFIG_HOME="$HOME/.config"

! systemctl is-enabled NetworkManager.service > /dev/null && sudo systemctl enable --now NetworkManager.service
systemctl is-enabled NetworkManager-wait-online.service > /dev/null && sudo systemctl disable --now NetworkManager-wait-online.service

###NETWORKMANAGER###while :;do nmcli device wifi connect NETWORKMANAGER_SSID password NETWORKMANAGER_PASSWORD ;[ $? -eq 0 ] && break;sleep 1;done

sudo pacman --needed --noconfirm -Syyuu git

mkdir -p "$HOME/repo"
[ ! -d "$HOME/repo/archlinux" ] && git clone https://github.com/devrtc0/archlinux.git "$HOME/repo/archlinux"

[ -z "$CONFIGDIR" ] && CONFIGDIR="$HOME/repo/archlinux"
sh -c "cd ${CONFIGDIR}; git pull --ff-only"

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

cat <<EOF | sudo sh
cp -f $CONFIGDIR/etc/pacman.conf /etc/pacman.conf
pacman --needed --noconfirm -Syu

while : ; do

cat <<EOF2 | sed 's/\s/\n/g' | pacman --needed --noconfirm -S -
        unzip unrar zip p7zip pigz pbzip2 xz
        $ucode chezmoi zram-generator man
        ttf-jetbrains-mono ttf-dejavu ttf-opensans
        noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji
        xdg-user-dirs ntfs-3g exfat-utils bluez-utils xorg-xinput

        plasma-desktop plasma-nm sddm sddm-kcm konsole okular ark
        bluedevil plasma-browser-integration kcalc kscreen kdialog
        gwenview kolourpaint spectacle plasma-pa
        breeze-gtk kde-gtk-config dolphin powerdevil

        pulseaudio-bluetooth
        jdk-openjdk openjdk-doc openjdk-src
        firefox
        mpv youtube-dl ncdu qbittorrent
        neovim micro code qtcreator telegram-desktop
        pass oath-toolkit keepassxc keybase kbfs gnupg
        mc curl wget htop jq expect zbar
        gcc gdb cmake rustup
        git-crypt asp
EOF2
    [ $? -eq 0 ] && break
done

mkdir -p /etc/modprobe.d
cp -f "$CONFIGDIR/etc/modprobe.d/blacklist.conf" /etc/modprobe.d/blacklist.conf

sed -i 's/relatime/noatime/' /etc/fstab

mkdir -p /etc/sysctl.d
cp -f "$CONFIGDIR/etc/sysctl.d/90-swappiness.conf" /etc/sysctl.d/90-swappiness.conf

mkdir -p /etc/systemd
cp -f "$CONFIGDIR/etc/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf

mkdir -p /etc/systemd/system.conf.d
cp -f "$CONFIGDIR/etc/systemd/system.conf.d/timeout.conf" /etc/systemd/system.conf.d/timeout.conf

systemctl enable fstrim.timer bluetooth.service sddm.service
mkinitcpio -P

find /boot/loader/entries/ -type f -iname '*.conf' -exec sh -c 'grep -E "^initrd.*-ucode.img" {} || sed -i -e "/^linux.*vmlinuz-linux/a initrd \/${ucode}.img" {}' \;

timedatectl set-ntp true
EOF

rm -rf $HOME/01_system.sh
rm -rf $HOME/.config/fish/config.fish
