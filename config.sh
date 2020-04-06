#!/bin/sh

sudo sh <<EOF
systemctl enable --now NetworkManager.service
systemctl disable --now NetworkManager-wait-online.service
systemctl enable --now dnscrypt-proxy.service
systemctl enable --now fstrim.timer
EOF

rm $HOME/.bashrc
rm $HOME/.bash_{logout,profile}

cat <<EOF | sudo tee /etc/pacman.conf
[options]
HoldPkg      = pacman glibc
Architecture = auto
Color
ILoveCandy

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

nmtui

sudo pacman --needed --noconfirm -Syyuu unzip zip p7zip pigz pbzip2 xz

cat <<EOF | sudo tee /etc/modprobe.d/blacklist.conf
blacklist bluetooth
blacklist btusb
blacklist uvcvideo
blacklist nouveau
EOF

cat <<EOF | sudo tee /etc/sysctl.d/90-swappiness.conf
vm.swappiness = 10
EOF

cat <<EOF | sudo pacman --needed --noconfirm -S -
alsa-utils
pulseaudio-alsa

xorg-server
xdg-user-dirs
bspwm
sxhkd
rofi
dunst
feh
sddm

mpv
firefox

ranger
pass
oath-toolkit
mc
curl
wget
htop

exa
ripgrep
fd
sd
bat
alacritty

systemd-swap
redshift

git
gcc
gdb
cmake
git
EOF

cat <<EOF | sudo pacman --needed --noconfirm -S -
ttf-jetbrains-mono
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

sudo mkdir -p /etc/systemd/swap.conf.d
cat <<EOF | sudo tee /etc/systemd/swap.conf.d/swap.conf
swapfc_force_preallocated=1
swapfc_enabled=1
EOF
sudo systemctl enable systemd-swap.service

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
# sudo rm -rf /etc/sddm.conf
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/sddm.conf
[Theme]
Current=clairvoyance
EOF

sudo sed -i 's/relatime/noatime/' /etc/fstab

