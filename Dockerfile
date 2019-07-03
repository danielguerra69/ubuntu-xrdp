FROM ubuntu:18.04 as builder
MAINTAINER Daniel Guerra

# Install packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -yy upgrade
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev libfuse-dev libpulse-dev libtool \
    xserver-xorg-dev"
RUN apt-get -yy install  sudo apt-utils software-properties-common $BUILD_DEPS

# Build xrdp

WORKDIR /tmp
RUN apt-get source pulseaudio
RUN apt-get build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-11.1
RUN dpkg-buildpackage -rfakeroot -uc -b
WORKDIR /tmp
RUN git clone --branch v0.9.10 --recursive https://github.com/neutrinolabs/xrdp.git
WORKDIR /tmp/xrdp
RUN ./bootstrap
RUN ./configure --enable-fuse
RUN make
RUN make install

# Build Pulse Audio module

WORKDIR /tmp
RUN git clone --branch v0.3 https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
WORKDIR /tmp/pulseaudio-module-xrdp
RUN ./bootstrap
# RUN ls /tmp
# RUN ls /tmp/pulseaudio-11.1
RUN ./configure PULSE_DIR=/tmp/pulseaudio-11.1
RUN make
RUN make install
RUN find -name \*.so

# Build XorgXrdp

WORKDIR /tmp
RUN git clone --branch v0.2.10 https://github.com/neutrinolabs/xorgxrdp.git
WORKDIR /tmp/xorgxrdp
RUN ./bootstrap
RUN ./configure XRDP_CFLAGS=-I/tmp/xrdp/common
RUN make
RUN make install

FROM ubuntu:18.04
ARG ADDITIONAL_PACKAGES=""
ENV ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES}

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt -y full-upgrade && apt install -y \
  ca-certificates \
  crudini \
  firefox \
  less \
  locales \
  openssh-server \
  pepperflashplugin-nonfree \
  pulseaudio \
  sudo \
  supervisor \
  uuid-runtime \
  vim \
  wget \
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
  xrdp \
  $ADDITIONAL_PACKAGES \
  && \
  rm -rf /var/cache/apt /var/lib/apt/lists && \
  mkdir -p /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /usr/lib/pulse-11.1/modules/module-xrdp-sink.so \
                    /usr/lib/pulse-11.1/modules/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer/
COPY --from=builder /usr/lib/xorg/modules/libxorgxrdp.so /usr/lib/xorg/modules/
COPY --from=builder /usr/lib/xorg/modules/drivers/xrdpdev_drv.so /usr/lib/xorg/modules/drivers/ \
                    /usr/lib/xorg/modules/input/xrdpkeyb_drv.so \
                    /usr/lib/xorg/modules/input/xrdpkeyb_drv.so \
                    /usr/lib/xorg/modules/input/xrdpmouse_drv.so /usr/lib/xorg/modules/input/

ADD bin /usr/bin
ADD etc /etc
ADD autostart /etc/xdg/autostart
#ADD pulse /usr/lib/pulse-10.0/modules/

# Configure
RUN mkdir /var/run/dbus && \
  cp /etc/X11/xrdp/xorg.conf /etc/X11 && \
  sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config && \
  sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini && \
  locale-gen en_US.UTF-8 && \
  echo "xfce4-session" > /etc/skel/.Xclients && \
  cp -r /etc/ssh /ssh_orig && \
  rm -rf /etc/ssh/* && \
  rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem

# Docker config
VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]
