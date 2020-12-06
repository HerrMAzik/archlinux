#!/bin/sh

PKGVER=2.2.25
PKGREL=1
build=$PWD

# Werner Koch (gnupg)
gpg --list-keys 528897B826403ADA || gpg --keyserver=pool.sks-keyservers.net --receive-keys 528897B826403ADA
cd $HOME/build && rm -rf gnupg || echo 'old package folder removing failed' && exit -1
asp update gnupg
asp export gnupg
cd gnupg

rg "^pkgver${PKGVER}$" PKGBUILD >/dev/null && rg "^pkgrel=${PKGREL}$" PKGBUILD >/dev/null && echo 'Package not updated' && exit 0

cp $build/gnupg/pinentry-title.patch ./
makepkg --syncdeps --install --noconfirm --needed

sed -i 's/#pinentry-title/pinentry-title/g' $HOME/.gnupg/gpg-agent.conf
