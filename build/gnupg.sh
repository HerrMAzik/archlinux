#!/bin/sh

build=$PWD

# Werner Koch (gnupg)
gpg --list-keys 528897B826403ADA || gpg --keyserver=pool.sks-keyservers.net --receive-keys 528897B826403ADA
cd $HOME/build
asp update gnupg
asp export gnupg
cd gnupg

cp $build/gnupg/* ./
makepkg --syncdeps --install --noconfirm --needed

sed -i 's/#pinentry-title/pinentry-title/g' $HOME/.gnupg/gpg-agent.conf
