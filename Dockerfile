FROM ubuntu:18.04 as base
LABEL maintainer="Daniel Guerra"

# Versions
ARG XRDP_VER="0.9.10"
ENV XRDP_VER=${XRDP_VER}
ARG XORGXRDP_VER="0.2.10"
ENV XORGXRDP_VER=${XORGXRDP_VER}
ARG XRDPPULSE_VER="0.3"
ENV XRDPPULSE_VER=${XRDPPULSE_VER}

FROM base as builder

# Install packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev libfuse-dev libpulse-dev libtool \
    xserver-xorg-dev wget ssl-cert"
RUN apt update && apt -y full-upgrade && apt install -y sudo apt-utils software-properties-common $BUILD_DEPS

# Build xrdp

WORKDIR /tmp
RUN apt build-dep -y xrdp
RUN wget https://github.com/neutrinolabs/xrdp/releases/download/v"${XRDP_VER}"/xrdp-"${XRDP_VER}".tar.gz
RUN tar -zxf xrdp-"${XRDP_VER}".tar.gz
COPY xrdp /tmp/xrdp-"${XRDP_VER}"/
WORKDIR /tmp/xrdp-"${XRDP_VER}"
RUN dpkg-buildpackage -rfakeroot -uc -b
RUN ls /tmp
RUN dpkg -i /tmp/xrdp_"${XRDP_VER}"-1_amd64.deb

WORKDIR /tmp
RUN apt build-dep -y xorgxrdp
RUN wget https://github.com/neutrinolabs/xorgxrdp/releases/download/v"${XORGXRDP_VER}"/xorgxrdp-"${XORGXRDP_VER}".tar.gz
RUN tar -zxf xorgxrdp-"$XORGXRDP_VER".tar.gz
COPY xorgxrdp /tmp/xorgxrdp-"${XORGXRDP_VER}"/
WORKDIR /tmp/xorgxrdp-"${XORGXRDP_VER}"
RUN dpkg-buildpackage -rfakeroot -uc -b
RUN dpkg -i /tmp/xorgxrdp_"${XORGXRDP_VER}"-1_amd64.deb

# Prepare Pulse Audio
WORKDIR /tmp
RUN apt-get source pulseaudio
RUN apt-get build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-11.1
RUN dpkg-buildpackage -rfakeroot -uc -b

# Build Pulse Audio module

WORKDIR /tmp
RUN wget https://github.com/neutrinolabs/pulseaudio-module-xrdp/archive/v"${XRDPPULSE_VER}".tar.gz -O pulseaudio-module-xrdp-"${XRDPPULSE_VER}".tar.gz
RUN tar -zxf pulseaudio-module-xrdp-"${XRDPPULSE_VER}".tar.gz
WORKDIR /tmp/pulseaudio-module-xrdp-"${XRDPPULSE_VER}"
RUN ./bootstrap
RUN ./configure PULSE_DIR=/tmp/pulseaudio-11.1
RUN make
RUN make install

FROM base
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
  ssl-cert \
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
  xprintidle \
  $ADDITIONAL_PACKAGES \
  && \
  rm -rf /var/cache/apt /var/lib/apt/lists && \
  mkdir -p /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /usr/lib/pulse-11.1/modules/module-xrdp-sink.so \
                    /usr/lib/pulse-11.1/modules/module-xrdp-source.so \
                    /var/lib/xrdp-pulseaudio-installer/
COPY --from=builder /tmp/xrdp_${XRDP_VER}-1_amd64.deb /tmp/xorgxrdp_${XORGXRDP_VER}-1_amd64.deb /tmp/
RUN dpkg -i /tmp/xrdp_"${XRDP_VER}"-1_amd64.deb /tmp/xorgxrdp_"${XORGXRDP_VER}"-1_amd64.deb && \
    rm -rf /tmp/xrdp_"${XRDP_VER}"-1_amd64.deb /tmp/xorgxrdp_"${XORGXRDP_VER}"-1_amd64.deb

COPY bin /usr/bin
COPY etc /etc
COPY autostart /etc/xdg/autostart

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
