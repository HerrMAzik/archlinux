#!/bin/bash

sudo sh <<EOF
systemctl enable --now NetworkManager.service
systemctl disable --now NetworkManager-wait-online.service
systemctl enable --now dnscrypt-proxy.service
systemctl enable --now fstrim.timer
EOF

nmtui

sudo pacman --needed --noconfirm -Syyuu unzip zip p7zip pigz pbzip2 xz python git

git clone https://github.com/HerrMAzik/arch-setup.git conf
cd conf
sudo python config.py
cd ..
rm -rf conf

sudo sh <<EOF
cat <<EOF2 > /etc/modprobe.d/blacklist.conf
blacklist bluetooth
blacklist btusb
blacklist uvcvideo
blacklist nouveau
EOF2
echo 'vm.swappiness = 10' > /etc/sysctl.d/90-swappiness.conf
EOF

sudo pacman --needed --noconfirm -S alsa-utils pulseaudio-alsa pulsemixer
sudo pacman --needed --noconfirm -S xorg-server xorg-xprop bspwm sxhkd xdg-user-dirs
sudo pacman --needed --noconfirm -S mpv
sudo pacman --needed --noconfirm -S ttf-jetbrains-mono
sudo pacman --needed --noconfirm -S ranger pass oath-toolkit mc curl wget
sudo pacman --needed --noconfirm -S exa ripgrep fd bat alacritty
sudo pacman --needed --noconfirm -S systemd-swap redshift
sudo pacman --needed --noconfirm -S git gcc gdb cmake

# yay
curl -L https://git.io/Jvd0P | bash

yay -S polybar --needed --noconfirm

sudo sh <<EOF
cp -f /etc/systemd/swap.conf /etc/systemd/swap.conf.bak
sed -i 's/^\(swapfc_force_preallocated=\)[[:digit:]]\(.*\)$/\11\2/' /etc/systemd/swap.conf
sed -i 's/\(swapfc_enabled=\)[[:digit:]]\(.*\)$/\11\2/' /etc/systemd/swap.conf
systemctl enable systemd-swap.service
EOF

echo 'SSH_AUTH_SOCK DEFAULT="${XDG_RUNTIME_DIR}/ssh-agent.socket"' > $HOME/.pam_environment
mkdir -p $HOME/.config/systemd/user
cat <<EOF > $HOME/.config/systemd/user/ssh-agent.service
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a \$SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF
systemctl --user enable --now ssh-agent.service
