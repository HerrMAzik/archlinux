#!/usr/bin/env sh

PKGVER=2.2.27
PKGREL=1
build=$PWD

# Werner Koch (gnupg)
gpg --list-keys 528897B826403ADA || gpg --keyserver=pool.sks-keyservers.net --receive-keys 528897B826403ADA
cd $HOME/build && rm -rf gnupg || (echo 'old package folder removing failed' && exit -1)
asp update gnupg
asp export gnupg
cd gnupg

PKG_INSTALLED_VER=$(yay -Qi gnupg | grep 'Version' | awk -F: '{gsub(/[[:space:]]*/,"",$2);print $2}')

([ "$PKGVER-$PKGREL" == "$PKG_INSTALLED_VER" ] && rg "^pkgver=${PKGVER}$" PKGBUILD >/dev/null && rg "^pkgrel=${PKGREL}$" PKGBUILD >/dev/null && echo 'Package is up-to-date') && exit 0

cp $build/pinentry-title.patch ./
cat PKGBUILD | sd --flags cms 'prepare\(\)(.+)./autogen.sh' 'prepare()${1}patch -p1 -i ../pinentry-title.patch\n./autogen.sh' | sd --flags cms 'source=\(([^\)]+)' 'source=(${1}\n'\''pinentry-title.patch'\''' | sd --flags cms 'sha256sums=\(([^\)]+)' 'sha256sums=(${1}\n'\''13bc1103c3340478f9f3e72ef95f4024739200aa86226742e743b56a113b04ca'\''' > 1 && mv 1 PKGBUILD
makepkg --syncdeps --install --noconfirm --needed || exit -1

sd '^#pinentry-title' 'pinentry-title' $HOME/.gnupg/gpg-agent.conf
