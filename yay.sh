#!/bin/sh

git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -ris --noconfirm
cd ..
rm -rf yay-bin
