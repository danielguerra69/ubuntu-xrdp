FROM ubuntu:20.10 as builder

# Install dev packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
RUN apt -y update && apt -yy upgrade
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev"
RUN apt -yy install sudo apt-utils software-properties-common $BUILD_DEPS

# Build xrdp and pulseaudio

WORKDIR /tmp
RUN apt source pulseaudio
RUN apt build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-13.99.2
RUN dpkg-buildpackage -rfakeroot -uc -b
WORKDIR /tmp
RUN git clone --branch devel --recursive https://github.com/neutrinolabs/xrdp.git
WORKDIR /tmp/xrdp
RUN ./bootstrap && ./configure
RUN make && make install
WORKDIR /tmp
RUN  apt -yy install libpulse-dev
RUN git clone --recursive https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /tmp/pulseaudio-module-xrdp
RUN ./bootstrap && ./configure PULSE_DIR=/tmp/pulseaudio-13.99.2
RUN make
RUN mkdir -p /tmp/so && cp src/.libs/*.so /tmp/so

# Build final ubuntu image

FROM ubuntu:20.10
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y software-properties-common apt-utils
RUN add-apt-repository "deb http://archive.canonical.com/ $(lsb_release -sc) partner" && apt-add-repository ppa:fish-shell/release-3 && apt update
RUN apt -y full-upgrade && apt install -y \
  adobe-flashplugin \
  ca-certificates \
  crudini \
  firefox \
  less \
  locales \
  openssh-server \
  pulseaudio \
  sudo \
  supervisor \
  uuid-runtime \
  vim \
  curl \
  fish \
  aria2 \
  vlc \
  wget \
  nano \
  mkvtoolnix \ 
  mkvtoolnix-gui \
  mediainfo \
  mediainfo-gui \
  filezilla \
  xauth \
  xautolock \
  xfce4 \
  xfce4-clipman-plugin \
  xfce4-cpugraph-plugin \
  xfce4-netload-plugin \
  xfce4-screenshooter \
  xfce4-taskmanager \
  xfce4-terminal \
  xfce4-xkb-plugin \
  xorgxrdp \
  xprintidle \
  xrdp && \
  apt remove -y light-locker xscreensaver && \
  apt autoremove -y && \
  rm -rf /var/cache/apt /var/lib/apt/lists && \
  mkdir -p /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-sink.so /var/lib/xrdp-pulseaudio-installer
ADD bin /usr/bin
ADD etc /etc
ADD autostart /etc/xdg/autostart

# Configure
RUN mkdir /var/run/dbus && \
  cp /etc/X11/xrdp/xorg.conf /etc/X11 && \
  sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config && \
  sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini && \
  locale-gen en_US.UTF-8 && \
  echo "pulseaudio -D --enable-memfd=True" > /etc/skel/.Xsession && \
  echo "xfce4-session" >> /etc/skel/.Xsession && \
  rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem
RUN sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config && service ssh restart

# Docker config
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]
