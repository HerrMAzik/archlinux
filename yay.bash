#!/bin/bash

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -ris --noconfirm
cd ..
rm -rf yay
