#!/bin/sh

sudo sed -i 's/relatime/noatime/' /etc/fstab

sudo sh <<EOF
systemctl enable --now NetworkManager.service
systemctl disable --now NetworkManager-wait-online.service
systemctl enable --now dnscrypt-proxy.service
systemctl enable --now fstrim.timer
EOF

rm $HOME/.bashrc 2> /dev/null
rm $HOME/.bash_{logout,profile} 2> /dev/null

cat <<EOF > $HOME/.zprofile
source $HOME/.profile
export XDG_CONFIG_HOME="\$HOME/.config"
EOF

XDG_CONFIG_HOME="$HOME/.config"

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
xorg-xsetroot
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
neovim

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

mkdir -p $HOME/repo
git clone https://github.com/HerrMAzik/arch-setup.git $HOME/repo/arch-setup

# yay
if ! hash polybar 2>/dev/null; then
    cd $HOME/repo/arch-setup
    sh yay.sh
    cd $HOME
fi

if ! hash polybar 2>/dev/null; then
    yay --needed --noconfirm -S polybar
fi

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

sudo mkdir -p /etc/sddm.conf.d
sudo systemctl enable sddm.service

cat <<EOF > $HOME/.fehbg
#!/bin/sh
feh --no-fehbg --bg-scale '$HOME/repo/arch-setup/lancer.jpg'
EOF
chmod 0754 $HOME/.fehbg

mkdir -p $XDG_CONFIG_HOME/sxhkd
cat <<EOF > $XDG_CONFIG_HOME/sxhkd/sxhkdrc
# terminal emulator
super + Return
    alacritty
# program launcher
super + @space
    rofi -show run
# make sxhkd reload its configuration files:
super + Escape
    pkill -USR1 -x sxhkd
# alternate between the tiled and monocle layout
super + m
    bspc desktop -l next
# close and kill
super + {_,shift + }w
	bspc node -{c,k}
# focus the node in the given direction
super + {_,shift + }{h,j,k,l}
	bspc node -{f,s} {west,south,north,east}
# swap the current node and the biggest node
super + g
	bspc node -s biggest
# focus or send to the given desktop
super + {_,shift + }{1-9,0}
	bspc {desktop -f,node -d} '^{1-9,10}'
EOF

mkdir -p $XDG_CONFIG_HOME/bspwm
cat <<EOF > $XDG_CONFIG_HOME/bspwm/bspwmrc
#!/bin/sh
sxhkd &
$HOME/.fehbg &
xorg-xsetroot -cursor_name left_ptr &
bspc monitor -d I II III IV V VI VII VIII IX X
EOF
chmod 0755 $XDG_CONFIG_HOME/bspwm/bspwmrc

mkdir -p $XDG_CONFIG_HOME/alacritty
cat <<EOF > $XDG_CONFIG_HOME/alacritty/alacritty.yml
# Colors (Gruvbox dark)
colors:
  # Default colors
  primary:
    # hard contrast: background = '#1d2021'
    background: '#282828'
    # soft contrast: background = '#32302f'
    foreground: '#ebdbb2'

  # Normal colors
  normal:
    black:   '#282828'
    red:     '#cc241d'
    green:   '#98971a'
    yellow:  '#d79921'
    blue:    '#458588'
    magenta: '#b16286'
    cyan:    '#689d6a'
    white:   '#a89984'

  # Bright colors
  bright:
    black:   '#928374'
    red:     '#fb4934'
    green:   '#b8bb26'
    yellow:  '#fabd2f'
    blue:    '#83a598'
    magenta: '#d3869b'
    cyan:    '#8ec07c'
    white:   '#ebdbb2'
EOF

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# vim gruvbox
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir $XDG_CONFIG_HOME/nvim
cat <<EOF > $XDG_CONFIG_HOME/nvim/init.vim
call plug#begin(stdpath('data') . '/plugged')

Plug 'morhetz/gruvbox'

call plug#end()

colorscheme gruvbox
EOF
nvim -c ':PlugInstall' -c ':q' -c ':q'
