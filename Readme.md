## Ubuntu 20.10 Multi User Remote Desktop Server

:warning: This repository is related to something that I use on a private stuff, it is not aimed for a public usage. Use it at your risk!

Ubuntu 20.10 docker image with some tools needed for generic stuff related to multimedia handling.

It comes with MakeMKV, ffmpeg, aria2, vlc, mkvtoolnix and so on.

It is based on XFCE4 with XRDP and PulseAudio module.

## Usage

First build the image with
```bash
docker build . --name xrdpubuntu
```

Then run a container (WARNING: use the --shm-size 1g or firefox/chrome will crash)

```bash
docker run -d --name uxrdp --hostname terminalserver --shm-size 1g -p 3389:3389 -p 2222:22 xrdpubuntu:latest
```
*note if you already use a rdp server on 3389 change -p <my-port>:3389
	  -p 2222:22 is for ssh access ( ssh -p 2222 ubuntu@<docker-ip> )

Connect with your remote desktop client to the docker server.
Use the Xorg session (leave as it is), user and pass.

## Creation of users

:warning: The main objective is to create users like root (with UID and GID set to 0), it is a crazy and unsafe setting but it is needed for my work, so bear with it.

To automate the creation of users, supply a file users.list in the /etc directory of the container.
The format is as follows:

```bash
id gid username password-hash
```

The provided users.list file will create a sample root-like-user

Username: ubuntu
Password: ubuntu

To generate the password hash use the following line

```bash
openssl passwd -1 'newpassword'
```

Run the xrdp container with your file

```bash
docker run -d -v $PWD/users.list:/etc/users.list
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