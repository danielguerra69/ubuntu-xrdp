FROM ubuntu:18.04 as builder
MAINTAINER Daniel Guerra

# Install packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -yy upgrade
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev libfuse-dev"
RUN apt-get -yy install  sudo apt-utils software-properties-common $BUILD_DEPS


# Build xrdp

WORKDIR /tmp
RUN apt-get source pulseaudio
RUN apt-get build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-11.1
RUN dpkg-buildpackage -rfakeroot -uc -b
WORKDIR /tmp
RUN git clone --recursive --branch v0.9.7 https://github.com/neutrinolabs/xrdp.git
#ADD clipboard_file.c /sesman/chansrv/clipboard_file.c
WORKDIR /tmp/xrdp
RUN ./bootstrap
RUN ./configure --enable-fuse
RUN make
RUN make install
WORKDIR /tmp/xrdp/sesman/chansrv/pulse
RUN sed -i "s/\/tmp\/pulseaudio\-10\.0/\/tmp\/pulseaudio\-11\.1/g" Makefile
RUN make
RUN mkdir -p /tmp/so
RUN cp *.so /tmp/so

FROM ubuntu:18.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update
RUN apt install -yy vim wget ca-certificates xorgxrdp pulseaudio \
  xfce4 xfce4-terminal xfce4-screenshooter xfce4-taskmanager \
  xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-netload-plugin \
  xfce4-xkb-plugin xauth uuid-runtime locales \
  firefox pepperflashplugin-nonfree openssh-server make gcc \
  libssl-dev libpam0g-dev libx11-dev  libxfixes-dev libxrandr-dev \
  libfuse-dev sudo chromium-browser

COPY --from=builder /tmp/xrdp /tmp/xrdp
WORKDIR /tmp/xrdp
RUN make install && rm -rf /tmp/xrdp
WORKDIR /
COPY --from=builder /tmp/so/module-xrdp-source.so /usr/lib/pulse-11.1/modules
COPY --from=builder /tmp/so/module-xrdp-sink.so /usr/lib/pulse-11.1/modules
ADD bin /usr/bin
ADD etc /etc


# Configure
RUN mkdir /var/run/dbus
RUN cp /etc/X11/xrdp/xorg.conf /etc/X11
RUN sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config
RUN sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini
RUN locale-gen en_US.UTF-8
RUN echo "xfce4-session" > /etc/skel/.Xclients
RUN cp -r /etc/ssh /ssh_orig
RUN rm -rf /etc/ssh/*
RUN rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem
RUN echo "user_allow_other" > /etc/fuse.conf
RUN addgroup xrdp
RUN useradd -m -s /bin/false -g xrdp xrdp
RUN touch /var/log/xrdp.log
RUN chown xrdp:xrdp /var/log/xrdp.log
RUN touch /var/log/xrdp-sesman.log
RUN update-rc.d -f xrdp defaults
RUN update-rc.d -f x11-common defaults
# Add sample user
RUN addgroup ubuntu
RUN useradd -m -s /bin/bash -g ubuntu ubuntu
RUN echo "ubuntu:ubuntu" | /usr/sbin/chpasswd
RUN echo "ubuntu    ALL=(ALL) ALL" >> /etc/sudoers
# generate xrdp key
RUN xrdp-keygen xrdp auto
# set startup xrdp
RUN ln -s /lib/systemd/system/xrdp.service /etc/systemd/system/multi-user.target.wants/xrdp.service
# generate machine-id
RUN uuidgen > /etc/machine-id
# set keyboard for all sh users
RUN echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile
VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["/sbin/init"]
