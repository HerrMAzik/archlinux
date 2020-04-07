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
export EDITOR="nvim"
export BROWSER="firefox"
export TERMINAL="alacritty"
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
pulsemixer

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
flameshot
zathura
zathura-pdf-poppler
zathura-djvu
calcurse

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
if [ ! -d $HOME/repo/arch-setup ]; then
    git clone https://github.com/HerrMAzik/arch-setup.git $HOME/repo/arch-setup
fi

# yay
if ! hash polybar 2>/dev/null; then
    cd $HOME/repo/arch-setup
    sh yay.sh
    cd $HOME
fi

if ! hash polybar 2>/dev/null; then
    yay --needed --noconfirm -S polybar
fi

if ! hash vscodium 2>/dev/null; then
    yay --needed --noconfirm -S vscodium-bin
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

mkdir -p $XDG_CONFIG_HOME/sxhkd
cat <<EOF > $XDG_CONFIG_HOME/sxhkd/sxhkdrc
### BSPWM config ###
# Close window
super + w
    bspc node -c

# Leave bspwm
super + control + 0
    bspc quit

# Make sxhkd reload its configuration files:
super + Escape
    pkill -USR1 -x sxhkd

# Close and kill
super + {_,shift + }w
    bspc node -{c,k}

# Change window in focus
super + {h, l}
    bspc node -f {west, east}

# Focus the next/previous node in the current desktop
super + {j, k}
    bspc node -f {next,prev}.local

# Move window
super + control + {h, j, k, l}
    bspc node -s {west, south, north, east} --follow

# Change to desktop x
super + {1-8}
    bspc desktop -f ^{1-8}

# Move x to desktop y
super + shift + {1-8}
    bspc node -d ^{1-8}

# Resize window
super + {y, u, i, o}
    bspc node -z {left -10 0, bottom 0 10, top 0 -10, right 10 0}

super + control + {y, u, i, o}
    bspc node -z {right -10 0, top 0 10,,bottom 0 -10, left 10 0}

# Toggle monocle layout
super + Tab
    bspc desktop -l next

# Toggle floating window
super + control + space
    bspc node -t "~floating"

# Make focused window fullscreen
super + f
    bspc node -t "~fullscreen"

### Keybindings for programs ###
# Launch terminal file manager
super + v
    \$TERMINAL -e ranger
# Launch calendar app
super + c
    \$TERMINAL -e calcurse
# Launch network manager
super + n
    \$TERMINAL -e nmtui
# Launch application launcher
super + r
    rofi -show run
# Launch terminal
super + Return
    \$TERMINAL
# Launch web browser
super + F2
    \$BROWSER
# Launch code editor
super + F3
    vscodium
# Launch system monitor
super + F4
    \$TERMINAL -e htop

### Screenshot ###
# Take a full screenshot and copy to clipboard
Print
    flameshot full -c
# Select an area and take a screenshot
shift + Print
    flameshot gui

### Volume Control ###
super + {Up, Down}
    pulsemixer {--change-volume +5, --change-volume -5}

EOF

mkdir -p $XDG_CONFIG_HOME/bspwm
cat <<EOF > $XDG_CONFIG_HOME/bspwm/bspwmrc
#!/bin/sh
sxhkd &
feh --no-fehbg --bg-scale "\$HOME/repo/arch-setup/lancer.jpg"
setxkbmap -model pc105 -layout us,ru -option grp:toggle
xorg-xsetroot -cursor_name left_ptr

### Gaps ###
bspc config top_padding        2
bspc config bottom_padding     2
bspc config left_padding       2
bspc config right_padding      2
bspc config border_width       2
bspc config window_gap         8

### Focusing behavior ###
bspc config focus_follows_pointer true
bspc config history_aware_focus true
bspc config focus_by_distance true

bspc monitor -d 1 2 3 4 5 6 7 8

bspc config split_ratio          0.5
bspc config borderless_monocle   true
bspc config gapless_monocle      true

# Colors
bspc config normal_border_color "#44475a"
bspc config active_border_color "#6272a4"
bspc config focused_border_color "#6272a4"
EOF
chmod 0755 $XDG_CONFIG_HOME/bspwm/bspwmrc

mkdir -p $XDG_CONFIG_HOME/alacritty
cat <<EOF > $XDG_CONFIG_HOME/alacritty/alacritty.yml
font:
  normal:
    family: Jetbrains Mono
    style: Regular

  bold:
    family: Jetbrains Mono
    style: Bold

  italic:
    family: Jetbrains Mono
    style: Bold Italic
    
  bold_italic:
    family: Jetbrains Mono
    style: Italic

  size: 11.0

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

background_opacity: 0.95

EOF

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# vim gruvbox
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p $XDG_CONFIG_HOME/nvim
cat <<EOF > $XDG_CONFIG_HOME/nvim/init.vim
call plug#begin(stdpath('data') . '/plugged')

Plug 'morhetz/gruvbox'

call plug#end()

colorscheme gruvbox
EOF
nvim -c ':PlugInstall' -c ':q' -c ':q'
