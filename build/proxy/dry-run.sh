#!/usr/bin/env bash

certbot certonly \
    --standalone \
    -w /usr/share/nginx/html \
    -d $DOMAIN \
    -m $ADMIN_EMAIL \
    --agree-tos \
    --dry-run