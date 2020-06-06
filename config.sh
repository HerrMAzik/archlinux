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
#    echo 'enter keybase account name:'
#    read -ers z
#    curl -L https://${z}.keybase.pub/kdb --output /tmp/kdb
    while : ; do
        test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase
        link=$(echo 'jA0ECQMCItwerSoXDA3o0lYBs5LFklMXCSTWb9FFsTdqXcPlVoFAHK6q6dZc7OF04lhUcFiKpCgpUgSde+CuPhSqIcGzdD7dyizdgu4aA91oX+QdhN7KLdiJSp7YJ7QyQTbYY2Smaw==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")
        [ $? -eq 0 ] && echo $link && break
        unset passphrase
    done

    resp=$(curl -sSL "https://cloud-api.yandex.net/v1/disk/public/resources?public_key=$link")
    error=$(echo $resp | jq -r .error)
    [ "$error" != "null" ] && echo "Error: $error" && exit -1
    link=$(echo $resp | jq -r .file)
    [ "$link" == "null" ] && echo "No link found:" && echo $resp | jq . && exit -1
    curl -sSL --output /tmp/kdbx $link

    hash=$(echo $resp | jq -r .sha256)
    sha256=$(sha256sum /tmp/kdbx | awk '{print $1}')
    [ "$hash" != "$sha256" ] && echo "Wrong hashes:" && echo $hash && echo $sha256 && exit -1
    echo "kdbx has been downloaded"
    
    while : ; do
        echo 'enter password for kdb archive:' && read -ers z
        gpg --passphrase "$z" --batch --quiet --decrypt /tmp/kdbx | xz -d > $MAN_KDB
        [ $? -eq 0 ] && break
	rm -rf $MAN_KDB
    done
fi
[ ! -f $MAN_KDB ] && echo 'KDBX is not ready' && exit -1

while : ; do
    hash=$(test -f $HOME/.sanctum.sanctorum && sha512sum $HOME/.sanctum.sanctorum | awk '{ print $1 }' || echo 0)
    hash=${hash:0:64}
    test $hash = 'da78e04ead69bdff7f9a9d5eb12e8e9cc7439ac347c697b6093eba4f1b727c7a' && break
    echo 'enter sanctum sanctorum content:'
    sh -c "IFS= ;read -N 34 -s -a z; echo \$z > $HOME/.sanctum.sanctorum"
done
chmod 0400 $HOME/.sanctum.sanctorum

if [ ! -d "$(chezmoi source-path)" ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase
    
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB dots.secret | base64 --decode | gpg --passphrase $passphrase --decrypt --batch --quiet --output $HOME/.dots.secret
    chmod 0400 $HOME/.dots.secret

    git clone https://github.com/HerrMAzik/dots.git "$(chezmoi source-path)"
    sh -c "cd $(chezmoi source-path); git crypt unlock $HOME/.dots.secret"
    
    chezmoi apply
    sh -c 'cd $(chezmoi source-path); git remote set-url origin git@github.com:HerrMAzik/dots.git'
fi

systemctl --user enable ssh-agent.service

if [ ! gpg --list-keys prime > /dev/null 2>&1 ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/pgp-private  | awk NF | gpg --pinentry-mode loopback --passphrase $(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/gpg) --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/pgp-public | awk NF | gpg --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/pgp-trust | awk NF | gpg --import-ownertrust
fi

sh -c 'cd $HOME/repo/archlinux; git remote set-url origin git@github.com:HerrMAzik/archlinux.git'

if [ ! -d $HOME/repo/pass ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    git clone https://HerrMAzik:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB Repositories/GitHub)@github.com/HerrMAzik/pass.git $HOME/repo/pass
    sh -c 'cd $HOME/repo/pass; git remote set-url origin git@github.com:HerrMAzik/pass.git'
fi
test ! -L $HOME/.password-store && ln -s $HOME/repo/pass $HOME/.password-store
! pass > /dev/null 2>&1 && echo 'Wrong password store link'

if [ ! -d $HOME/repo/settings ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    git clone https://HerrMAzik:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB Repositories/GitHub)@github.com/HerrMAzik/settings.git $HOME/repo/settings
    sh -c 'cd $HOME/repo/settings; git remote set-url origin git@github.com:HerrMAzik/settings.git'
fi

rustup default stable

if [ ! -d $HOME/.mozilla/firefox/*HerrMAN ]; then
    firefox -CreateProfile HerrMAN
    firefox -P HerrMAN --headless &
    sleep 2
    pkill firefox
fi

nvim -c ':PlugInstall' -c ':q' -c ':q'

# yay
! type yay >/dev/null 2>&1 && sh $CONFIGDIR/yay.sh

! type vscodium >/dev/null 2>&1 && yay --needed --noconfirm -S vscodium-bin
vscodium --install-extension matklad.rust-analyzer
vscodium --install-extension bmalehorn.vscode-fish
vscodium --install-extension mechatroner.rainbow-csv

! type intellij-idea-ultimate-edition >/dev/null 2>&1 && yay -S --needed --noconfirm intellij-idea-ultimate-edition intellij-idea-ultimate-edition-jre
! type clion >/dev/null 2>&1 && yay -S --needed --noconfirm clion clion-jre
! type goland >/dev/null 2>&1 && yay -S --needed --noconfirm goland goland-jre
