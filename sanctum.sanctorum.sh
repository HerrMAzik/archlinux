#!/usr/bin/env bash

! type gpg >/dev/null && echo 'install gnupg' && exit -1
! type curl >/dev/null && echo 'install curl' && exit -1
! type jq >/dev/null && echo 'install jq' && exit -1

if [ ! -f $SANCTUM_SANCTORUM ]; then
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
    [ "$link" == "null" ] || [ $? -ne 0 ] && link=$(echo 'jA0ECQMCXOfwQMLRH93p0lkBXcQzC1SyWhccifyEn1QGeU7VS7Q7+aJLuI5iP7EiOBkKGaMteZ68aF6bbuVGjjZLw4L/BB3br6CK+4yF0/0nRREXoQyEee1AVoE1OaDG/kqq7oa/QFy3Kg==' | base64 --decode | gpg --decrypt --batch --quiet --passphrase "$passphrase")

    curl -sSL --output /tmp/kdbx $link
    echo "kdbx has been downloaded"

    while : ; do
        echo 'enter password for kdb archive:' && read -ers z
        gpg --passphrase "$z" --batch --quiet --decrypt /tmp/kdbx | xz -d > $SANCTUM_SANCTORUM
        [ $? -eq 0 ] && break
    rm -rf $SANCTUM_SANCTORUM
    done
fi
