#!/bin/sh

mkdir -p ./bak
mkdir -p ./src

echo ';' | sfdisk /dev/sdb
yes | mkfs.ext4 -L garbage /dev/sdb1
mount /dev/sdb1 ./bak
rm -rf ./bak/*

mount /dev/sda1 ./src

rsync -aAX --info=progress2 --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} ./src/ ./bak/src

umount ./src

echo ';' | sfdisk /dev/sda
echo ';' | sfdisk /dev/sdc

yes | mdadm --create --verbose --level=0 --metadata=1.2 --raid-devices=2 /dev/md0 /dev/sda1 /dev/sdc1

yes | mkfs.ext4 -v -L system -m 0.5 -b 4096 -E stride=16,stripe-width=32 /dev/md0
mount /dev/md0 ./src
rm -rf ./src/*

rsync -aAX --info=progress2 --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} ./bak/src/ ./src
umount ./bak

mdadm --detail --scan >> ./src/etc/mdadm.conf

genfstab -U ./src | sed 's/relatime/noatime/' > ./src/etc/fstab

arch-chroot ./src /bin/sh <<EOF
grub-install /dev/sda
grub-install /dev/sdc
grub-mkconfig -o /boot/grub/grub.cfg
EOF

umount ./src
