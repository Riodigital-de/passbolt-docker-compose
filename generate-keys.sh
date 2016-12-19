#!/bin/sh

echo "### Reading values for gpg key generation from .env ###"
. ./.env

echo "Name: " $gpg_name
if [ -n "$gpg_comment" ]; then
    echo "Comment: "  $gpg_comment
else
    echo "Comment: (None)" 
fi
echo "Email: " $gpg_email
echo "Key-Type: " $gpg_key_type
echo "Key-Length: " $gpg_key_length
if [ "$gpg_expire_date" = "0" ]; then
    echo "Expire-Date: 0 - The keys will never expire"
else
    echo "Expire-Date: " $gpg_expire_date
fi

# shouldn't we name this image Celebrimbor?
echo "### Building image for docker container to generate keys as 'passbolt-key-gen' ###"
docker build -t passbolt-key-gen ./build/key-gen
echo "### Starting container ###"
docker run \
    --rm \
    --privileged \
    -v $PWD/build/app/keys:/keys \
    -e GPG_NAME="$gpg_name" \
    -e GPG_COMMENT="$gpg_comment" \
    -e GPG_EMAIL="$gpg_email" \
    -e GPG_KEY_TYPE="$gpg_key_type" \
    -e GPG_KEY_LENGTH="$gpg_key_length" \
    -e GPG_EXPIRE_DATE="$gpg_expire_date" \
    passbolt-key-gen
echo "### Removing passbolt-key-gen image ###"
docker rmi -f passbolt-key-gen

echo "### Key generation finished succesfully"
echo "### keys have been saved in $PWD/build/app/keys ###"
