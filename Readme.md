## Ubuntu 18.04/16.04  Multi User Remote Desktop Server

Fully implemented Multi User xrdp
with xorgxrdp and pulseaudio
on Ubuntu 16.04/18.04.
Copy/Paste and sound is working.
Users can re-login in the same session.
Xfce4, Firefox are pre installed.

# Tags

danielguerra/ubuntu-xrdp:16.04
danielguerra/ubuntu-xrdp:18.04  or latest

## Usage

Start the rdp server

```bash
docker run -d --name uxrdp --hostname terminalserver --shm-size 1g -p 3389:3389 -p 2222:22 danielguerra/ubuntu-xrdp
```
*note if you already use a rdp server on 3389 change -p <my-port>:3389
	  -p 2222:22 is for ssh access ( ssh -p 2222 ubuntu@<docker-ip> )

Connect with your remote desktop client to the docker server.
Use the Xorg session (leave as it is), user and pass.

## Sample user

There is a sample user with sudo rights

Username: ubuntu
Password: ubuntu


You can set a PASSWORDHASH

First create a password hash

```bash
openssl passwd -1 'newpassword'
```

Run the xrdp container with your hash

```bash
docker run -d -e PASSWORDHASH='$1$Cm8EQjXg$7dJeRsw6TLvgxsl3.pBRZ1'
```

You can change your password in the rdp session in a terminal

```bash
passwd
```

## Add new users

No configuration is needed for new users just do

```bash
docker exec -ti uxrdp adduser mynewuser
```

After this the new user can login

## Add new services

To make sure all processes are working supervisor is installed.
The location for services to start is /etc/supervisor/conf.d

Example: Add mysql as a service

```bash
apt-get -yy install mysql-server
echo "[program:mysqld] \
command= /usr/sbin/mysqld \
user=mysql \
autorestart=true \
priority=100" > /etc/supervisor/conf.d/mysql.conf
supervisorctl update
```

## Volumes
This image uses two volumes:
1. `/etc/ssh/` holds the sshd host keys and config
2. `/home/` holds the `ubuntu/` default user home directory

When bind-mounting `/home/`, make sure it contains a folder `ubuntu/` with proper permission, otherwise no login will be possible.
```
mkdir -p ubuntu
chown 999:999 ubuntu
```

## To run with docker-compose
```bash
git clone https://github.com/danielguerra69/ubuntu-xrdp.git
cd ubuntu-xrdp/
docker-compose up -d
```
