#!/bin/sh

rm $HOME/.bashrc
rm $HOME/.bash_{logout,profile}

sudo sh <<EOF
systemctl enable --now NetworkManager.service
systemctl disable --now NetworkManager-wait-online.service
systemctl enable --now dnscrypt-proxy.service
systemctl enable --now fstrim.timer
EOF

nmtui

sudo pacman --needed --noconfirm -Syyuu unzip zip p7zip pigz pbzip2 xz

sudo sh <<EOF
cat <<EOF2 > /etc/modprobe.d/blacklist.conf
blacklist bluetooth
blacklist btusb
blacklist uvcvideo
blacklist nouveau
EOF2
echo 'vm.swappiness = 10' > /etc/sysctl.d/90-swappiness.conf
EOF

sudo sh <<EOF
pacman --needed --noconfirm -S alsa-utils pulseaudio-alsa
pacman --needed --noconfirm -S xorg-server xorg-xprop bspwm sxhkd xdg-user-dirs feh sddm
pacman --needed --noconfirm -S mpv
pacman --needed --noconfirm -S ttf-jetbrains-mono
pacman --needed --noconfirm -S ranger pass oath-toolkit mc curl wget
pacman --needed --noconfirm -S exa ripgrep fd sd bat alacritty
pacman --needed --noconfirm -S systemd-swap redshift
pacman --needed --noconfirm -S git gcc gdb cmake git
EOF

systemctl --user enable --now redshift.service
sudo systemctl enable sddm.service

sudo sed -i 's/^[\s\t]*COMPRESSION\s*=\s*"/#COMPRESSION="/g' /etc/mkinitcpio.conf
sudo sed -i 's/^#COMPRESSION="lz4/COMPRESSION="lz4/g' /etc/mkinitcpio.conf
sudo mkinitcpio -P

mkdir -p $XDG_CONFIG_HOME/pacman
cat <<EOF > $XDG_CONFIG_HOME/pacman/makepkg.conf
CFLAGS="-march=native -O2 -pipe -fstack-protector-strong -fno-plt"
CXXFLAGS="\${CFLAGS}"
MAKEFLAGS="-j\$(nproc)"
COMPRESSGZ=(pigz -c -f -n)
COMPRESSBZ2=(pbzip2 -c -f)
COMPRESSXZ=(xz -c -z - --threads=0)
COMPRESSZST=(zstd -c -z -q - --threads=0)
EOF

# yay
mkdir -p $HOME/repo
git clone https://github.com/HerrMAzik/arch-setup.git $HOME/repo/arch-setup
cd $HOME/repo/arch-setup
sh yay.sh

yay --needed --noconfirm -S polybar

sudo sh <<EOF
cat <<EOF2 > /etc/systemd/swap.conf.d/swap.conf
swapfc_force_preallocated=1
swapfc_enabled=1
EOF2
systemctl enable systemd-swap.service
EOF

echo 'SSH_AUTH_SOCK DEFAULT="${XDG_RUNTIME_DIR}/ssh-agent.socket"' > $HOME/.pam_environment
mkdir -p $XDG_CONFIG_HOME/systemd/user
cat <<EOF > $XDG_CONFIG_HOME/systemd/user/ssh-agent.service
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=$(which ssh-agent) -D -a \$SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF
systemctl --user enable --now ssh-agent.service

feh --bg-scale $HOME/repo/arch-setup/lancer.jpg

yay --needed --noconfirm -S sddm-theme-clairvoyance
# sudo sd -f mc '(^\[Theme\][^\[]*Current=)(\w*)([^\[]*\[?)' '${1}clairvoyance$3' /etc/sddm.conf
sudo sh <<EOF
mkdir -p /etc/sddm.conf.d
cat <<EOF2 > /etc/sddm.conf.d/sddm.conf
[Theme]
Current=clairvoyance
EOF2
EOF

sudo sed -i 's/relatime/noatime/' /etc/fstab

