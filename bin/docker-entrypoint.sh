#!/bin/bash


# Add sample user
# sample user uses uid 999 to reduce conflicts with user ids when mounting an existing home dir
# the below has represents the password 'ubuntu'
# run `openssl passwd -1 'newpassword'` to create a custom hash
if [ ! $PASSWORDHASH ]; then
    export PASSWORDHASH='$1$1osxf5dX$z2IN8cgmQocDYwTCkyh6r/'
fi

addgroup --gid 999 ubuntu && \
useradd -m -u 999 -s /bin/bash -g ubuntu ubuntu
echo "ubuntu:$PASSWORDHASH" | /usr/sbin/chpasswd -e
echo "ubuntu    ALL=(ALL) ALL" >> /etc/sudoers
unset PASSWORDHASH

# Add the ssh config if needed

if [ ! -f "/etc/ssh/sshd_config" ];
	then
		cp /ssh_orig/sshd_config /etc/ssh
fi

if [ ! -f "/etc/ssh/ssh_config" ];
	then
		cp /ssh_orig/ssh_config /etc/ssh
fi

if [ ! -f "/etc/ssh/moduli" ];
	then
		cp /ssh_orig/moduli /etc/ssh
fi

# generate fresh rsa key if needed
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ];
	then 
		ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi

# generate fresh dsa key if needed
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ];
	then 
		ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

#prepare run dir
mkdir -p /var/run/sshd

# generate xrdp key
if [ ! -f "/etc/xrdp/rsakeys.ini" ];
	then
		xrdp-keygen xrdp auto
fi

# generate machine-id
uuidgen > /etc/machine-id

# set keyboard for all sh users
echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile


exec "$@"
