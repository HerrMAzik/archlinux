#!/bin/sh

! type git >/dev/null && echo 'install git at first running system.sh' && exit -1
test ! -d $HOME/repo/archlinux && echo 'run system.sh before configuring' && exit -1

test -z $XDG_CONFIG_HOME && XDG_CONFIG_HOME="$HOME/.config"
test -z $CONFIGDIR && CONFIGDIR=$HOME/repo/archlinux
MAN_KDB="$HOME/repo/man.kdbx"

rm $HOME/.bashrc 2> /dev/null
rm $HOME/.bash_{logout,profile} 2> /dev/null

mkdir -p $HOME/go/src
mkdir -p $HOME/repo

if [ ! -f $MAN_KDB ]; then
    echo 'enter keybase account name:'
    read -ers z
    curl -L https://${z}.keybase.pub/kdb --output /tmp/kdb
    echo 'enter password for kdb archive:'
    read -ers z
    7za e -o$HOME/repo/ -p$z /tmp/kdb
fi

while : ; do
    hash=$(test -f $HOME/.sanctum.sanctorum && sha512sum $HOME/.sanctum.sanctorum | awk '{ print $1 }' || echo 0)
    hash=${hash:0:100}
    test $hash = 'da78e04ead69bdff7f9a9d5eb12e8e9cc7439ac347c697b6093eba4f1b727c7a02e3a53969ff035da204ba19df33445b8acf' && break
    echo 'enter sanctum sanctorum content:'
    sh -c "IFS= ;read -N 34 -s -a z; echo \$z > $HOME/.sanctum.sanctorum"
done
chmod 0400 $HOME/.sanctum.sanctorum

if [ ! -d "$(chezmoi source-path)" ]; then
    test -z $passphrase && echo 'enter password:' && read -ers passphrase
    
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB dots.secret | base64 --decode | gpg --passphrase $passphrase --decrypt --batch --cipher-algo AES256 --quiet --output $HOME/.dots.secret
    chmod 0400 $HOME/.dots.secret

    git clone https://github.com/HerrMAzik/dots.git "$(chezmoi source-path)"
    sh -c "cd $(chezmoi source-path); git crypt unlock $HOME/.dots.secret"
    
    chezmoi apply
    sh -c 'cd $(chezmoi source-path); git remote set-url origin git@github.com:HerrMAzik/dots.git'
fi

systemctl --user enable ssh-agent.service

if [ ! gpg --list-keys prime > /dev/null 2>&1 ]; then
    test -z $passphrase && echo 'enter password:' && read -ers passphrase

    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/pgp-private  | awk NF | gpg --pinentry-mode loopback --passphrase $(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/gpg) --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/pgp-public | awk NF | gpg --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/pgp-trust | awk NF | gpg --import-ownertrust
fi

if [ ! -d $HOME/repo/pass ]; then
    test -z $passphrase && echo 'enter password:' && read -ers passphrase

    git clone https://HerrMAzik:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB Repositories/GitHub)@github.com/HerrMAzik/pass.git $HOME/repo/pass
    sh -c 'cd $HOME/repo/pass; git remote set-url origin git@github.com:HerrMAzik/pass.git'
fi
test ! -L $HOME/.password-store && ln -s $HOME/repo/pass $HOME/.password-store
! pass > /dev/null 2>&1 && echo 'Wrong password store link'

if [ ! -d $HOME/repo/settings ]; then
    test -z $passphrase && echo 'enter password:' && read -ers passphrase

    git clone https://HerrMAzik:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB Repositories/GitHub)@github.com/HerrMAzik/settings.git $HOME/repo/settings
    sh -c 'cd $HOME/repo/settings; git remote set-url origin git@github.com:HerrMAzik/settings.git'
fi

rustup default stable

# yay
! type yay >/dev/null 2>&1 && sh $CONFIGDIR/yay.sh

! type vscodium >/dev/null 2>&1 && yay --needed --noconfirm -S vscodium-bin

! type rust-analyzer >/dev/null 2>&1 && yay --needed --noconfirm -S rust-analyzer-bin

nvim -c ':PlugInstall' -c ':q' -c ':q'

if [ ! -d $HOME/.mozilla/firefox/*HerrMAN ]; then
    firefox -CreateProfile HerrMAN
    firefox -P HerrMAN --headless &
    sleep 2
    pkill -15 firefox
fi

! type intellij-idea-ultimate-edition >/dev/null 2>&1 && yay -S --needed --noconfirm intellij-idea-ultimate-edition intellij-idea-ultimate-edition-jre
! type clion >/dev/null 2>&1 && yay -S --needed --noconfirm clion clion-jre
! type goland >/dev/null 2>&1 && yay -S --needed --noconfirm goland goland-jre

vscodium --install-extension matklad.rust-analyzer
