#!/bin/sh

sudo echo 'Preparing:'

! type git >/dev/null && echo 'install git at first running system.sh' && exit -1
test ! -d $HOME/repo/archlinux && echo 'run system.sh before configuring' && exit -1

test -z $XDG_CONFIG_HOME && XDG_CONFIG_HOME="$HOME/.config"
test -z $ARCHLINUX && ARCHLINUX=$HOME/repo/archlinux
MAN_KDB="$HOME/repo/man.kdbx"

rm -rf $HOME/.bashrc
rm -rf $HOME/.bash_{logout,profile}

mkdir -p $HOME/build
mkdir -p $HOME/repo

if [ ! -f $MAN_KDB ]; then
    while : ; do
        test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase
        link=$(echo 'jA0ECQMCItwerSoXDA3o0lYBs5LFklMXCSTWb9FFsTdqXcPlVoFAHK6q6dZc7OF04lhUcFiKpCgpUgSde+CuPhSqIcGzdD7dyizdgu4aA91oX+QdhN7KLdiJSp7YJ7QyQTbYY2Smaw==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")
        [ $? -eq 0 ] && echo $link && break
        unset passphrase
    done

    resp=$(curl -sSL "https://cloud-api.yandex.net/v1/disk/public/resources?public_key=$link")
    error=$(echo $resp | jq -r .error)
    [ "$error" != "null" ] && echo "Error: $error"
    link=$(echo $resp | jq -r .file)
    [ "$link" == "null" ] || [ $? -ne 0 ] && link=$(echo 'jA0ECQMCXOfwQMLRH93p0lkBXcQzC1SyWhccifyEn1QGeU7VS7Q7+aJLuI5iP7EiOBkKGaMteZ68aF6bbuVGjjZLw4L/BB3br6CK+4yF0/0nRREXoQyEee1AVoE1OaDG/kqq7oa/QFy3Kg==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")

    curl -sSL --output /tmp/kdbx $link
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
    test $hash = 'da78e04ead69bdff7f9a9d5eb12e8e9cc7439ac347c697b6093eba4f1b727c7a' && chmod 0400 $HOME/.sanctum.sanctorum && break
    echo 'enter sanctum sanctorum content:'
    sh -c "IFS= ;read -N 34 -s -a z; echo \$z > $HOME/.sanctum.sanctorum"
done

if [ ! -f $HOME/.dots.secret ]; then
    while : ; do
        test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

        yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB dots.secret | base64 --decode | gpg --passphrase $passphrase --decrypt --batch --quiet --output $HOME/.dots.secret
        [ $? -eq 0 ] && break
    done
    hash=$(test -f $HOME/.dots.secret && sha512sum $HOME/.dots.secret | awk '{ print $1 }' || echo 0)
    hash=${hash:0:64}
    [ $hash != 'd5f37e719c1af84da39fbef77908b8fb1b8e14737f7c02aa2206cc3adeb4e8be' ] && rm -rf $HOME/.dots.secret && echo 'wrong dots.secret file content' && exit -1
    chmod 0400 $HOME/.dots.secret
fi

if [ ! -d "$(chezmoi source-path)" ]; then
    git clone https://github.com/HerrMAzik/dots.git "$(chezmoi source-path)"
    chmod 0700 $(chezmoi source-path)
    sh -c "cd $(chezmoi source-path); git crypt unlock $HOME/.dots.secret"

    chezmoi apply
    sh -c 'cd $(chezmoi source-path); git remote set-url origin git@github.com:HerrMAzik/dots.git'
fi

sed -i 's/^pinentry-title/#pinentry-title/g' $HOME/.gnupg/gpg-agent.conf

if [ ! -f $XDG_CONFIG_HOME/keybase/*.mpack ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    mpack_filename=$(yes $passphrase | keepassxc-cli show -q -a UserName -s -k $HOME/.sanctum.sanctorum $MAN_KDB Programs/Keybase/mpack)
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB Programs/Keybase/mpack | base64 --decode > $XDG_CONFIG_HOME/keybase/$mpack_filename
    chmod 0600 $XDG_CONFIG_HOME/keybase/$mpack_filename
fi

systemctl --user enable --now ssh-agent.service

# GPG
if [ ! $(gpg --list-keys prime > /dev/null 2>&1) ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/keys/private | gpg --pinentry-mode loopback --passphrase $(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/gpg) --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/keys/public | gpg --import
    yes $passphrase | keepassxc-cli show -q -a Notes -s -k $HOME/.sanctum.sanctorum $MAN_KDB GPG/keys/trust | awk NF | gpg --import-ownertrust
fi

sh -c "cd $ARCHLINUX; git remote set-url origin git@github.com:HerrMAzik/archlinux.git"

if [ ! -d $HOME/repo/pass ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    git clone https://HerrMAzik:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB Repositories/GitHub/token)@github.com/HerrMAzik/pass.git $HOME/repo/pass
    sh -c 'cd $HOME/repo/pass; git remote set-url origin git@github.com:HerrMAzik/pass.git'
fi
[ ! -L $HOME/.password-store ] && ln -s $HOME/repo/pass $HOME/.password-store
! pass > /dev/null 2>&1 && echo 'Wrong password store link'

if [ ! -d $HOME/repo/settings ]; then
    test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase

    git clone https://HerrMAzik:$(yes $passphrase | keepassxc-cli show -q -a Password -s -k $HOME/.sanctum.sanctorum $MAN_KDB Repositories/GitHub/token)@github.com/HerrMAzik/settings.git $HOME/repo/settings
    sh -c 'cd $HOME/repo/settings; git remote set-url origin git@github.com:HerrMAzik/settings.git'
fi

rustup default stable

code --install-extension matklad.rust-analyzer
code --install-extension bmalehorn.vscode-fish
code --install-extension mechatroner.rainbow-csv
code --install-extension gulajavaministudio.mayukaithemevsc

VIM_PLUG=$HOME/.local/share/nvim/site/autoload/plug.vim
[ ! -f $VIM_PLUG ] && curl -fLo $VIM_PLUG --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim +PlugInstall +UpdateRemotePlugins +qa

# yay
! type yay >/dev/null 2>&1 && sh $ARCHLINUX/yay.sh

if [ ! -d $HOME/.mozilla/firefox/*HerrMAN ]; then
    firefox -CreateProfile HerrMAN
    firefox -P HerrMAN --headless &
    sleep 1
    pkill 'firefox|MainThread'
    sleep 1
    cp $HOME/repo/settings/user.js $HOME/.mozilla/firefox/*HerrMAN/
    firefox https://addons.mozilla.org/firefox/addon/ublock-origin/
    firefox https://addons.mozilla.org/firefox/addon/umatrix/
    firefox https://addons.mozilla.org/en-US/firefox/addon/ublacklist/
    firefox https://addons.mozilla.org/firefox/addon/keepassxc-browser/
    firefox https://addons.mozilla.org/ru/firefox/addon/tampermonkey/
fi
