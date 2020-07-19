#!/bin/sh

build=$PWD

# Werner Koch (gnupg)
gpg --list-keys 249B39D24F25E3B6 || gpg --receive-keys 249B39D24F25E3B6
cd $HOME/build
asp update gnupg
asp export gnupg
cd gnupg

cp $build/gnupg/* ./
makepkg -s --noconfirm --needed
