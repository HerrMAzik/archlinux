#!/usr/bin/env bash

CONFIGDIR=$(dirname "$0")

cat <<EOF | sudo sh
    pacman -S dnscrypt-proxy

    mkdir -p /etc/dnscrypt-proxy
    cp -f $CONFIGDIR/etc/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    cp -f $CONFIGDIR/etc/dnscrypt-proxy/forwarding-rules.txt /etc/dnscrypt-proxy/forwarding-rules.txt

    cp -f $CONFIGDIR/etc/NetworkManager/conf.d/dns-servers.conf /etc/NetworkManager/conf.d/dns-servers.conf

    systemctl enable dnscrypt-proxy.service
EOF
