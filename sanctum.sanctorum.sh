#!/usr/bin/env bash

test -z $SANCTUM_SANCTORUM && echo 'envvar SANCTUM_SANCTORUM is not set' && exit -1

! type gpg >/dev/null && sudo pacman -Sy gnupg --noconfirm --needed || exit -1
! type curl >/dev/null && sudo pacman -Sy curl --noconfirm --needed || exit -1
! type jq >/dev/null && sudo pacman -Sy jq --noconfirm --needed || exit -1

# cat 'text' | gpg --symmetric --cipher-algo AES256 --pinentry-mode=loopback --passphrase 'passphrase' | base64 | tr -d '\n'

if [ ! -f $SANCTUM_SANCTORUM ]; then
    # main repo
    while : ; do
        test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase
        link=$(echo 'jA0ECQMCbFuRczxVj1T00mIBMmmRtwiaycErI9Wqx4F1H+81ZMKzsWnwSXEMn0+TyY0TvYEXtRTB3ugZWFma6mF45Iu3AC5tVLuLZ75xNpqTrL+SZ7CPS7ZXTQRt3d/V7is3ttEmrgjO5ZnZWKBvFnSUNg==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")
        [ $? -eq 0 ] && echo $link && break
        unset passphrase
        unset link
    done

    # backup repo
    if [ -z $link ]; then
        test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase
        link=$(echo 'jA0ECQMCSfcT/Nh5o5r00nEB0pCiMS2BS65dIlnxNk70YPTKSB7TjatymYhHsMU3xNjan0iqwoDPt0rGC8B5kMWAfD7TOceXQcGDJ7T3imEx9nbkl0oPa2Gxaw7FiC/X1g2TrRUVWQ9OzISdYDvHIhRlZtVAyqmt0H/E+sx4lEKJ/A==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")
        [ $? -eq 0 ] && echo $link && break
        unset passphrase
        unset link
    fi

    if [ -z $link ]; then
        # yadi
        while : ; do
            test -z $passphrase && echo 'enter kdbx password:' && read -ers passphrase
            link=$(echo 'jA0ECQMCItwerSoXDA3o0lYBs5LFklMXCSTWb9FFsTdqXcPlVoFAHK6q6dZc7OF04lhUcFiKpCgpUgSde+CuPhSqIcGzdD7dyizdgu4aA91oX+QdhN7KLdiJSp7YJ7QyQTbYY2Smaw==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")
            [ $? -eq 0 ] && echo $link && break
            unset passphrase
        done
        resp=$(curl -sSL "https://cloud-api.yandex.net/v1/disk/public/resources?public_key=$link")
        error=$(echo $resp | jq -r .error)
        [ "$error" != "null" ] && echo "Error: $error"
        link=$(echo $resp | jq -r .file)
        if [ $? -ne 0 ] || [ -z $link ] || [ "$link" == "null" ]; then
            unset link
        fi
    fi

    # keybase
    [ -z $link ] && link=$(echo 'jA0ECQMCXOfwQMLRH93p0lkBXcQzC1SyWhccifyEn1QGeU7VS7Q7+aJLuI5iP7EiOBkKGaMteZ68aF6bbuVGjjZLw4L/BB3br6CK+4yF0/0nRREXoQyEee1AVoE1OaDG/kqq7oa/QFy3Kg==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")

    # download
    curl -sSL --output /tmp/kdbx $link
    echo "kdbx has been downloaded"

    while : ; do
        echo 'enter password for kdb archive:' && read -ers z
        gpg --passphrase "$z" --batch --quiet --decrypt /tmp/kdbx | xz -d > $SANCTUM_SANCTORUM
        [ $? -eq 0 ] && break
        rm -rf $SANCTUM_SANCTORUM
    done
fi
