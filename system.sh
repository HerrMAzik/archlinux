#!/bin/sh

test -z $XDG_CONFIG_HOME && XDG_CONFIG_HOME="$HOME/.config"

! systemctl is-enabled NetworkManager.service > /dev/null && sudo systemctl enable --now NetworkManager.service
systemctl is-enabled NetworkManager-wait-online.service > /dev/null && sudo systemctl disable --now NetworkManager-wait-online.service

nmtui

sudo pacman --needed --noconfirm -Syyuu git

mkdir -p $HOME/repo
if [ ! -d $HOME/repo/archlinux ];then
    git clone https://github.com/HerrMAzik/archlinux.git $HOME/repo/archlinux
    sh -c 'cd $HOME/repo/archlinux; git remote set-url origin git@github.com:HerrMAzik/archlinux.git'
fi

test -z $CONFIGDIR && CONFIGDIR=$HOME/repo/archlinux
sh -c "cd ${CONFIGDIR}; git pull"

sudo cp -f $CONFIGDIR/etc/pacman.conf /etc/pacman.conf

sudo pacman --needed --noconfirm -Syu unzip zip p7zip pigz pbzip2 xz
sudo pacman --needed --noconfirm -S intel-ucode dnscrypt-proxy chezmoi systemd-swap powertop man
sudo pacman --needed --noconfirm -S noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji
sudo pacman --needed --noconfirm -S ttf-jetbrains-mono ttf-dejavu ttf-opensans
sudo pacman --needed --noconfirm -S xdg-user-dirs plasma-desktop sddm plasma-pa plasma-nm sddm-kcm
sudo pacman --needed --noconfirm -S konsole okular ark powerdevil gwenview dolphin kcalc kolourpaint
sudo pacman --needed --noconfirm -S mpv youtube-dl firefox flameshot ncdu 
sudo pacman --needed --noconfirm -S pass oath-toolkit keepassxc keybase kbfs gnupg
sudo pacman --needed --noconfirm -S mc curl wget htop neovim jq expect 
sudo pacman --needed --noconfirm -S exa ripgrep fd bat
sudo pacman --needed --noconfirm -S git-crypt gcc gdb cmake go go-tools

sudo sed -i 's/^[\s\t]*COMPRESSION\s*=\s*"/#COMPRESSION="/g' /etc/mkinitcpio.conf
sudo sed -i 's/^#COMPRESSION="lz4/COMPRESSION="lz4/g' /etc/mkinitcpio.conf
sudo mkinitcpio -P

sudo mkdir -p /etc/modprobe.d
sudo cp -f $CONFIGDIR/etc/modprobe.d/blacklist.conf /etc/modprobe.d/blacklist.conf

sudo mkdir -p /etc/dnscrypt-proxy
sudo cp -f $CONFIGDIR/etc/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
sudo cp -f $CONFIGDIR/etc/dnscrypt-proxy/forwarding-rules.txt /etc/dnscrypt-proxy/forwarding-rules.txt
sudo cp -f $CONFIGDIR/etc/NetworkManager/conf.d/dns-servers.conf /etc/NetworkManager/conf.d/dns-servers.conf
sudo systemctl enable dnscrypt-proxy.service

sudo sed -i 's/relatime/noatime/' /etc/fstab
sudo systemctl enable fstrim.timer

sudo mkdir -p /etc/sysctl.d
sudo cp -f $CONFIGDIR/etc/sysctl.d/90-swappiness.conf /etc/sysctl.d/90-swappiness.conf

sudo mkdir -p /etc/systemd/swap.conf.d
sudo cp -f $CONFIGDIR/etc/systemd/swap.conf.d/swap.conf /etc/systemd/swap.conf.d/swap.conf
sudo systemctl enable --now systemd-swap.service

sudo cp -f $CONFIGDIR/etc/systemd/system/powertop.service /etc/systemd/system/powertop.service
sudo systemctl enable powertop.service

sudo mkdir -p /etc/sddm.conf.d
sudo systemctl enable sddm.service

rm $HOME/system.sh
