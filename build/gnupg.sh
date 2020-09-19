#!/bin/sh

build=$PWD

# Werner Koch (gnupg)
gpg --list-keys 249B39D24F25E3B6 || gpg --keyserver=pool.sks-keyservers.net --receive-keys 249B39D24F25E3B6
cd $HOME/build
asp update gnupg
asp export gnupg
cd gnupg

cp $build/gnupg/* ./
makepkg -s --noconfirm --needed

sed -i 's/#pinentry-title/pinentry-title/g' $HOME/.gnupg/gpg-agent.conf
