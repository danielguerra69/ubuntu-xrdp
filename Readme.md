## Ububtu 16.04 Multi User Remote Desktop Server

Fully implemented Multi User xrdp with xorgxrdp and pulseaudio on Ubuntu 16.04.
Copy/Paste and sound is working. Users can re-login in the same session.
Xfce4, Firefox are pre installed.

## Usage

Start the rdp server

```bash
docker run -d --name uxrdp --hostname terminalserver --shm-size 1g -p 3389:3389 danielguerra/ubuntu-xrdp
```
*note if you allready use a rdp server on 3389 change -p <my-port>:3389

Connect with your remote desktop client to the docker server.
Use the Xorg session (leave as it is), user and pass.

## Sample user

There is a sample user with sudo rights

Username : ubuntu
Password : ubuntu

You can change your password in the rdp session in a terminal

```bash
passwd
```

## Add new users

docker exec -ti uxrdp adduser mynewuser

