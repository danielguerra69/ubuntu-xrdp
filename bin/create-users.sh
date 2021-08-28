#!/bin/bash

test -f /etc/users.list || exit 0

while read id gid username hash; do
        # Skip, if user already exists
        grep ^$username /etc/passwd && continue
        # Create user
        useradd -m -ou $id -s /bin/bash -g $gid $username
        # Set password
        echo "$username:$hash" | /usr/sbin/chpasswd -e
done < /etc/users.list
