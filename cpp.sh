#!/bin/sh

yay -S --needed --noconfirm gcc gdb cmake
! type clion >/dev/null 2>&1 && yay -S --needed --noconfirm --removemake clion clion-jre clion-lldb clion-gdb clion-cmake
