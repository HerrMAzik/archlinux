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
sudo pacman --needed --noconfirm -S base-devel intel-ucode dnscrypt-proxy chezmoi
sudo pacman --needed --noconfirm -S noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji
sudo pacman --needed --noconfirm -S ttf-jetbrains-mono ttf-font-awesome
sudo pacman --needed --noconfirm -S alsa-utils pulseaudio-alsa pulsemixer
sudo pacman --needed --noconfirm -S xorg-server xorg-xsetroot xorg-xrdb xdg-user-dirs
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

#*******************************************************************************
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


systemctl --user enable redshift.service


rm $HOME/.bashrc 2> /dev/null
rm $HOME/.bash_{logout,profile} 2> /dev/null
echo > $HOME/.zshrc

touch $HOME/.profile
cat <<EOF > $HOME/.zprofile
source $HOME/.profile
export XDG_CONFIG_HOME="\$HOME/.config"
export EDITOR="nvim"
export VISUAL="codium"
export BROWSER="firefox"
export TERMINAL="alacritty"
EOF

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
if ! hash yay 2>/dev/null; then
    cd $CONFIGDIR
    sh yay.sh
    cd $HOME
fi

if ! hash polybar 2>/dev/null; then
    yay --needed --noconfirm -S polybar
fi

if ! hash vscodium 2>/dev/null; then
    yay --needed --noconfirm -S vscodium-bin
fi

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

cat <<EOF > $HOME/.Xresources
!!! Gruvbox theme
! hard contrast: *background: #1d2021
*background: #282828
! soft contrast: *background: #32302f
*foreground: #ebdbb2
! Black + DarkGrey
*color0:  #282828
*color8:  #928374
! DarkRed + Red
*color1:  #cc241d
*color9:  #fb4934
! DarkGreen + Green
*color2:  #98971a
*color10: #b8bb26
! DarkYellow + Yellow
*color3:  #d79921
*color11: #fabd2f
! DarkBlue + Blue
*color4:  #458588
*color12: #83a598
! DarkMagenta + Magenta
*color5:  #b16286
*color13: #d3869b
! DarkCyan + Cyan
*color6:  #689d6a
*color14: #8ec07c
! LightGrey + White
*color7:  #a89984
*color15: #ebdbb2

EOF

mkdir -p $XDG_CONFIG_HOME/picom
cat <<EOF > $XDG_CONFIG_HOME/picom/picom.conf
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;
shadow = true;
shadow-radius = 5;
shadow-offset-x = -5;
shadow-offset-y = -5;
shadow-opacity = 0.5;
shadow-exclude = [
    "! name~=''",
    "name = 'Notification'",
    "name = 'Plank'",
    "name = 'Docky'",
    "name = 'Kupfer'",
    "name = 'xfce4-notifyd'",
    "name *= 'VLC'",
    "name *= 'compton'",
    "name *= 'picom'",
    "name *= 'Chromium'",
    "name *= 'Chrome'",
    "class_g = 'Firefox' && argb",
    "class_g = 'Conky'",
    "class_g = 'Kupfer'",
    "class_g = 'Synapse'",
    "class_g ?= 'Notify-osd'",
    "class_g ?= 'Cairo-dock'",
    "class_g ?= 'Xfce4-notifyd'",
    "class_g ?= 'Xfce4-power-manager'",
    "_GTK_FRAME_EXTENTS@:c",
    "_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
];
shadow-ignore-shaped = false;
inactive-opacity = 1;
active-opacity = 1;
frame-opacity = 1;
inactive-opacity-override = false;
blur-background-fixed = false;
blur-background-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'"
];
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-exclude = [ ];
mark-wmwin-focused = true;
mark-ovredir-focused = true;
use-ewmh-active-win = true;
detect-rounded-corners = true;
detect-client-opacity = true;
refresh-rate = 0;
vsync = true;
dbe = false;
unredir-if-possible = false;
focus-exclude = [ ];
detect-transient = true;
detect-client-leader = true;
wintypes:
{
    tooltip =
    {
        fade = true;
        shadow = false;
        opacity = 0.85;
        focus = true;
    };
};
xrender-sync-fence = true;

EOF

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
    \$VISUAL
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

mkdir -p $XDG_CONFIG_HOME/ranger
git clone https://github.com/HerrMAzik/ranger-colorschemes.git $XDG_CONFIG_HOME/ranger/colorschemes
cat <<EOF > $XDG_CONFIG_HOME/ranger/rc.conf
set show_hidden true
set colorscheme gruvbox
EOF

mkdir -p $XDG_CONFIG_HOME/polybar
cat <<EOF > $XDG_CONFIG_HOME/polybar/launch.sh
killall -q polybar
echo "----------" | tee -a /tmp/polybar1.log
polybar bar1 >> /tmp/polybar1.log 2>&1 &
EOF
chmod +x $XDG_CONFIG_HOME/polybar/launch.sh

cat <<EOF > $XDG_CONFIG_HOME/polybar/config

EOF

mkdir -p $XDG_CONFIG_HOME/bspwm
cat <<EOF > $XDG_CONFIG_HOME/bspwm/bspwmrc
#!/bin/sh
picom -b
xrdb -load \$HOME/.Xresources
sxhkd &
feh --no-fehbg --bg-scale "\$HOME/repo/archlinux/lancer.jpg"
setxkbmap -model pc105 -layout us,ru -option grp:toggle
xorg-xsetroot -cursor_name left_ptr
$XDG_CONFIG_HOME/polybar/launch.sh

### Gaps ###
bspc config top_padding        2
bspc config bottom_padding     2
bspc config left_padding       2
bspc config right_padding      2
bspc config border_width       2
bspc config window_gap         4

### Focusing behavior ###
bspc config focus_follows_pointer true
bspc config history_aware_focus true
bspc config focus_by_distance true

bspc monitor -d 1 2 3 4 5 6 7 8

bspc config split_ratio          0.5
bspc config borderless_monocle   true
bspc config gapless_monocle      true

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

# vim gruvbox
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
mkdir -p $XDG_CONFIG_HOME/nvim
cat <<EOF > $XDG_CONFIG_HOME/nvim/init.vim
call plug#begin(stdpath('data') . '/plugged')

Plug 'morhetz/gruvbox'

call plug#end()

EOF
nvim -c ':PlugInstall' -c ':q' -c ':q'
echo 'colorscheme gruvbox' >> $XDG_CONFIG_HOME/nvim/init.vim
