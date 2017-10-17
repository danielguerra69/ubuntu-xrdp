#!/bin/bash

xrdp-keygen xrdp auto

# generate machine-id
uuidgen > /etc/machine-id

# set keyboard for all sh users
echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile


exec "$@"
