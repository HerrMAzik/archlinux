#!/usr/bin/env sh

if [ $# -ne 2 ]; then
    echo 'wrong arguments number'
    exit -1
fi

CONFDIR=$(dirname "$0")

rm -f "$CONFDIR/plain_configuration"
cat "$CONFDIR/$2" | base64 --decode | gpg --passphrase "$1" --decrypt --batch --quiet --output "$CONFDIR/plain_configuration"
