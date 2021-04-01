#!/bin/sh

test -z $XDG_CONFIG_HOME && XDG_CONFIG_HOME="$HOME/.config"

! systemctl is-enabled NetworkManager.service > /dev/null && sudo systemctl enable --now NetworkManager.service
systemctl is-enabled NetworkManager-wait-online.service > /dev/null && sudo systemctl disable --now NetworkManager-wait-online.service

nmtui

sudo pacman --needed --noconfirm -Syyuu git

mkdir -p $HOME/repo
[ ! -d $HOME/repo/archlinux ] && git clone https://github.com/devrtc0/archlinux.git $HOME/repo/archlinux

test -z $CONFIGDIR && CONFIGDIR=$HOME/repo/archlinux
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
        $ucode dnscrypt-proxy chezmoi systemd-swap man
        noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji
        ttf-jetbrains-mono ttf-dejavu ttf-opensans
        xdg-user-dirs ntfs-3g exfat-utils bluez-utils xorg-xinput
        plasma-desktop plasma-nm sddm sddm-kcm konsole okular ark powerdevil dolphin
        bluedevil plasma-browser-integration kcalc kscreen kdialog
        pulseaudio-bluetooth plasma-pa
        gwenview kolourpaint flameshot spectacle zbar
        breeze-gtk kde-gtk-config
        jdk-openjdk openjdk-doc openjdk-src
        mpv youtube-dl firefox chromium ncdu qbittorrent
        neovim code qtcreator
        pass oath-toolkit keepassxc keybase kbfs gnupg
        mc curl wget htop jq expect
        exa ripgrep fd bat skim
        gcc gdb cmake clang lldb llvm rustup
        git-crypt asp
EOF2
    [ $? -eq 0 ] && break
done

sed -i 's/^[\s\t]*COMPRESSION\s*=\s*"/#COMPRESSION="/g' /etc/mkinitcpio.conf
sed -i 's/^#COMPRESSION="lz4/COMPRESSION="lz4/g' /etc/mkinitcpio.conf

mkdir -p /etc/modprobe.d
cp -f $CONFIGDIR/etc/modprobe.d/blacklist.conf /etc/modprobe.d/blacklist.conf

mkdir -p /etc/dnscrypt-proxy
cp -f $CONFIGDIR/etc/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
cp -f $CONFIGDIR/etc/dnscrypt-proxy/forwarding-rules.txt /etc/dnscrypt-proxy/forwarding-rules.txt

cp -f $CONFIGDIR/etc/NetworkManager/conf.d/dns-servers.conf /etc/NetworkManager/conf.d/dns-servers.conf

sed -i 's/relatime/noatime/' /etc/fstab

mkdir -p /etc/sysctl.d
cp -f $CONFIGDIR/etc/sysctl.d/90-swappiness.conf /etc/sysctl.d/90-swappiness.conf

mkdir -p /etc/systemd/swap.conf.d
cp -f $CONFIGDIR/etc/systemd/swap.conf.d/swap.conf /etc/systemd/swap.conf.d/swap.conf

sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

systemctl enable dnscrypt-proxy.service fstrim.timer systemd-swap.service bluetooth.service sddm.service
mkinitcpio -P

grep '^GRUB_CMDLINE_LINUX_DEFAULT=".*mitigations' /etc/default/grub || sed -i 's/\(^GRUB_CMDLINE_LINUX_DEFAULT=".*\)"$/\1 mitigations=off"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

timedatectl set-ntp true
EOF

rm -rf $HOME/01_system.sh
