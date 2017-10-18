FROM ubuntu:16.04
MAINTAINER Daniel Guerra

# Install packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -yy upgrade
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev"
RUN apt-get -yy install \ 
	sudo apt-utils software-properties-common vim wget ca-certificates \
    xfce4 xfce4-terminal xfce4-screenshooter xfce4-taskmanager \
    xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-netload-plugin \
    xfce4-xkb-plugin xauth supervisor uuid-runtime pulseaudio locales \
    firefox pepperflashplugin-nonfree openssh-server \
    $BUILD_DEPS


# Build xrdp

WORKDIR /tmp
RUN apt-get source pulseaudio
RUN apt-get build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-8.0
RUN dpkg-buildpackage -rfakeroot -uc -b
WORKDIR /tmp
RUN git clone --branch v0.9.4 --recursive https://github.com/neutrinolabs/xrdp.git
WORKDIR /tmp/xrdp
RUN ./bootstrap
RUN ./configure
RUN make
RUN make install
WORKDIR /tmp/xrdp/sesman/chansrv/pulse
RUN sed -i "s/\/tmp\/pulseaudio\-10\.0/\/tmp\/pulseaudio\-8\.0/g" Makefile 
RUN make
RUN cp *.so /usr/lib/pulse-8.0/modules/

# Build xorgxrdp

WORKDIR /tmp
RUN git clone --branch v0.2.4 --recursive https://github.com/neutrinolabs/xorgxrdp.git
RUN apt-get -yy install xserver-xorg-dev
WORKDIR /tmp/xorgxrdp
RUN ./bootstrap
RUN ./configure
RUN make
RUN make install

# Clean 

WORKDIR /
RUN apt-get -yy remove xscreensaver
RUN apt-get -yy remove $BULD_DEPS
RUN apt-get -yy autoremove
RUN apt-get -yy clean
RUN rm -rf /tmp/*

# Configure

ADD bin /usr/bin
ADD etc /etc
#ADD pulse /usr/lib/pulse-10.0/modules/
RUN mkdir /var/run/dbus
RUN cp /etc/X11/xrdp/xorg.conf /etc/X11
#RUN sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config
RUN sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini
RUN locale-gen en_US.UTF-8
RUN echo "xfce4-session" > /etc/skel/.Xclients
RUN cp -r /etc/ssh /ssh_orig
RUN rm -rf /etc/ssh/*

# Add sample user

RUN addgroup ubuntu
RUN useradd -m -s /bin/bash -g ubuntu ubuntu
RUN echo "ubuntu:ubuntu" | /usr/sbin/chpasswd
RUN echo "ubuntu    ALL=(ALL) ALL" >> /etc/sudoers

# Docker config

VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]