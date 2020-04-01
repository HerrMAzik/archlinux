#!/bin/bash

sudo systemctl enable --now NetworkManager.service
sudo systemctl disable --now NetworkManager-wait-online.service
sudo systemctl enable --now dnscrypt-proxy.service

nmtui

# figure out how to enable multilib in /etc/pacman.conf using cli
sudo pacman --noconfirm -Syyuu

sudo pacman --noconfirm -S zsh

sudo useradd -m -g users -G audio,video,power,storage,wheel -s /bin/zsh azat
sudo passwd azat

sudo sh <<EOF
cat <<EOF2 > /etc/modprobe.d/blacklist.conf
blacklist bluetooth
blacklist btusb
blacklist uvcvideo
EOF2
echo 'vm.swappiness = 10' > /etc/sysctl.d/90-swappiness.conf
EOF

sudo pacman --needed --noconfirm -S alsa-utils pulseaudio-alsa pulsemixer
sudo pacman --needed --noconfirm -S xorg-server xorg-xprop picom bspwm sxhkd
sudo pacman --needed --noconfirm -S mpv
sudo pacman --needed --noconfirm -S ttf-jetbrains-mono
sudo pacman --needed --noconfirm -S ranger pass oath-toolkit mc curl wget
sudo pacman --needed --noconfirm -S exa ripgrep fd bat
sudo pacman --needed --noconfirm -S systemd-swap redshift
sudo pacman --needed --noconfirm -S unzip zip p7zip pigz pbzip2 xz
sudo pacman --needed --noconfirm -S git gcc gdb cmake

# yay
curl -L https://git.io/Jvd0P | bash

# figure out how to adjust the /etc/makepkg.conf

yay -S polybar --needed --noconfirm
