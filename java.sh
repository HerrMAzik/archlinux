#!/bin/sh

yay -S --needed --noconfirm jdk-openjdk openjdk-src openjdk-doc
! type intellij-idea-ultimate-edition >/dev/null 2>&1 && yay -S --needed --noconfirm --removemake intellij-idea-ultimate-edition intellij-idea-ultimate-edition-jre
