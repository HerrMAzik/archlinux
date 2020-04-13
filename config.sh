#!/bin/sh

XDG_CONFIG_HOME="$HOME/.config"

sudo systemctl enable --now NetworkManager.service
sudo systemctl disable --now NetworkManager-wait-online.service

nmtui

sudo pacman --needed --noconfirm -Syyuu git

mkdir -p $HOME/repo
if [ ! -d $HOME/repo/archlinux ]; then
    git clone https://github.com/HerrMAzik/archlinux.git $HOME/repo/archlinux
fi
CONFIGDIR=$HOME/repo/archlinux
sh -c "cd ${CONFIGDIR}; git pull"
sudo cp -f $CONFIGDIR/etc/pacman.conf /etc/pacman.conf

sudo pacman --needed --noconfirm -Syu unzip zip p7zip pigz pbzip2 xz
sudo pacman --needed --noconfirm -S intel-ucode dnscrypt-proxy chezmoi
sudo pacman --needed --noconfirm -S noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono
sudo pacman --needed --noconfirm -S brightnessctl powertop
sudo pacman --needed --noconfirm -S alsa-utils pulseaudio-alsa pulsemixer pamixer
sudo pacman --needed --noconfirm -S xorg-server xorg-xsetroot xorg-fonts-encodings xorg-xrdb xdg-user-dirs
sudo pacman --needed --noconfirm -S picom bspwm sxhkd rofi feh sddm
sudo pacman --needed --noconfirm -S mpv firefox flameshot zathura zathura-pdf-poppler zathura-djvu
sudo pacman --needed --noconfirm -S pass oath-toolkit
sudo pacman --needed --noconfirm -S ranger mc curl wget htop neovim
sudo pacman --needed --noconfirm -S exa ripgrep fd bat alacritty systemd-swap redshift
sudo pacman --needed --noconfirm -S git gcc gdb cmake git

: '
cat <<EOF | sudo pacman --needed --noconfirm -S -
adobe-source-code-pro-fonts
adobe-source-han-sans-otc-fonts
adobe-source-han-serif-otc-fonts
adobe-source-han-sans-cn-fonts
adobe-source-han-sans-tw-fonts
adobe-source-han-serif-tw-fonts
adobe-source-han-sans-hk-fonts
adobe-source-han-serif-cn-fonts
adobe-source-sans-pro-fonts
adobe-source-han-sans-jp-fonts
adobe-source-han-serif-jp-fonts
adobe-source-serif-pro-fonts
adobe-source-han-sans-kr-fonts
adobe-source-han-serif-kr-fonts
EOF
'

sudo sed -i 's/^[\s\t]*COMPRESSION\s*=\s*"/#COMPRESSION="/g' /etc/mkinitcpio.conf
sudo sed -i 's/^#COMPRESSION="lz4/COMPRESSION="lz4/g' /etc/mkinitcpio.conf
sudo mkinitcpio -P

sudo mkdir -p /etc/modprobe.d
sudo cp -f $CONFIGDIR/etc/modprobe.d/blacklist.conf /etc/modprobe.d/blacklist.conf

sudo mkdir -p /etc/dnscrypt-proxy
sudo cp -f $CONFIGDIR/etc/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo cp -f $CONFIGDIR/etc/dnscrypt-proxy/forwarding-rules.txt etc/dnscrypt-proxy/forwarding-rules.txt
sudo cp -f $CONFIGDIR/etc/NetworkManager/conf.d/dns-servers.conf /etc/NetworkManager/conf.d/dns-servers.conf
sudo systemctl enable dnscrypt-proxy.service

sudo sed -i 's/relatime/noatime/' /etc/fstab
sudo systemctl enable --now fstrim.timer

sudo mkdir -p /etc/sysctl.d
sudo cp -f $CONFIGDIR/etc/sysctl.d/90-swappiness.conf /etc/sysctl.d/90-swappiness.conf

sudo mkdir -p /etc/systemd/swap.conf.d
sudo cp -f $CONFIGDIR/etc/systemd/swap.conf.d/swap.conf /etc/systemd/swap.conf.d/swap.conf
sudo systemctl enable systemd-swap.service

sudo mkdir -p /etc/sddm.conf.d
sudo systemctl enable sddm.service

sudo cp -f $CONFIGDIR/etc/systemd/system/powertop.service /etc/systemd/system/powertop.service
sudo systemctl enable powertop.service

########################################################################################
rm $HOME/.bashrc 2> /dev/null
rm $HOME/.bash_{logout,profile} 2> /dev/null
rm $HOME/.zshrc

chezmoi init --apply https://github.com/HerrMAzik/dots.git

systemctl --user enable redshift.service
systemctl --user enable ssh-agent.service

# yay
if ! hash yay 2>/dev/null; then
    cd $CONFIGDIR
    sh yay.sh
    cd $HOME
fi

! hash polybar 2>/dev/null && yay --needed --noconfirm -S polybar
! hash vscodium 2>/dev/null && yay --needed --noconfirm -S vscodium-bin
! yay -Qi ttf-iosevka > /dev/null 2>&1 && yay --noconfirm --needed -S ttf-iosevka

sudo cp -f $CONFIGDIR/usr/share/fonts/TTF/icomoon.ttf /usr/share/fonts/TTF/icomoon.ttf
sudo sh <<EOF
fc-cache -f > /dev/null
mkfontscale /usr/share/fonts/TTF
mkfontdir /usr/share/fonts/TTF
EOF

nvim -c ':PlugInstall' -c ':q' -c ':q'
