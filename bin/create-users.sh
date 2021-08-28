#!/bin/bash

test -f /etc/users.list || exit 0

while read id gid username hash; do
        # Skip, if user already exists
        grep ^$username /etc/passwd && continue
        # Create user
        useradd -m -ou $id -s /bin/fish -g $gid $username
        # Set password
        echo "$username:$hash" | /usr/sbin/chpasswd -e
        # Copy launchers
        mkdir /home/$username/Desktop
        cp /usr/share/RenameMyTVSeries/RenameMyTVSeries.desktop /home/$username/Desktop/RenameMyTVSeries.desktop
done < /etc/users.list
