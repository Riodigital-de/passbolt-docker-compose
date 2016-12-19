#!/bin/sh

echo "Replacing values in gpg-key.conf file"
envsubst < /gpg-key.conf.template > /gpg-key.conf

echo "starting haveged to allow gpg to collect enough entropy"
haveged

echo "starting key generation"
gpg --gen-key --batch gpg-key.conf

echo "exporting armored keys"
gpg --armor --export-secret-keys $GPG_EMAIL > /keys/gpg_server_key_private.key
gpg --armor --export $GPG_EMAIL > /keys/gpg_server_key_public.key
cp /root/.gnupg/secring.gpg /keys/secring.gpg
cp /root/.gnupg/pubring.gpg /keys/pubring.gpg 