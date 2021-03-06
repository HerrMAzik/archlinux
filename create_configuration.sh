#!/usr/bin/env sh

# openssl passwd -6 <password>

if [ $# -ne 2 ]; then
    echo 'wrong arguments number'
    exit -1
fi

CONFDIR=$(dirname "$0")

HASH=$(echo "$1" | sha512sum - | awk '{ print $1 }')
echo $HASH
HASH=${HASH:0:64}
if [ $HASH != '37b58cddf70324beb55651768cf5e41dd9feea7f99c0ee83b4db8df13dbbc58b' ]; then
    echo 'wrong argument #1'
    exit -1
fi

echo "Password: $1"

cat "$CONFDIR/plain_configuration" | gpg --symmetric --cipher-algo AES256 --pinentry-mode=loopback --passphrase "$1" | base64 | tr -d '\n' > "$CONFDIR/$2"
