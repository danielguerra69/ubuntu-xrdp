FROM nvidia/cuda:10.2-devel-ubuntu18.04 as builder
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

FROM nvidia/cuda:10.2-devel-ubuntu18.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt -y full-upgrade && apt install -y \
  ca-certificates \
  less \
  locales \
  openssh-server \
  pulseaudio \
  sudo \
  supervisor \
  uuid-runtime \
  vim \
  wget \
  xauth \
  xautolock \
  xorgxrdp \
  xprintidle \
  xrdp \
  && \
  rm -rf /var/cache/apt /var/lib/apt/lists && \
  mkdir -p /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-sink.so /var/lib/xrdp-pulseaudio-installer
ADD bin /usr/bin
ADD etc /etc
ADD autostart /etc/xdg/autostart
#ADD pulse /usr/lib/pulse-10.0/modules/

# Configure

RUN cp /etc/X11/xrdp/xorg.conf /etc/X11
RUN sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config
RUN sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini
RUN locale-gen en_US.UTF-8
RUN echo "xfce4-session" > /etc/skel/.Xclients
RUN rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem

# Add sample user

RUN addgroup ubuntu
RUN useradd -m -s /bin/bash -g ubuntu ubuntu
RUN echo "ubuntu:ubuntu" | /usr/sbin/chpasswd
RUN echo "ubuntu    ALL=(ALL) ALL" >> /etc/sudoers
RUN cp -r /etc/ssh /ssh_orig && \
  rm -rf /etc/ssh/* && \
  rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem

RUN apt-get update && apt-get install wget -y
	RUN wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/libcudnn7_7.4.2.24-1+cuda10.0_amd64.deb
	RUN dpkg -i ./libcudnn7_7.4.2.24-1+cuda10.0_amd64.deb
	RUN wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/libcudnn7-dev_7.4.2.24-1+cuda10.0_amd64.deb
	RUN dpkg -i ./libcudnn7-dev_7.4.2.24-1+cuda10.0_amd64.deb

# Docker config
VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]
