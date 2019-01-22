FROM ubuntu:18.04 as builder
MAINTAINER Daniel Guerra

# Install packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -yy upgrade
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev"
RUN apt-get -yy install  sudo apt-utils software-properties-common $BUILD_DEPS


# Build pulseaudio
WORKDIR /tmp
RUN apt-get source pulseaudio
RUN apt-get build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-11.1
RUN dpkg-buildpackage -rfakeroot -uc -b

# Build xrdp
WORKDIR /tmp
RUN git clone --branch v0.9.7 --recursive https://github.com/neutrinolabs/xrdp.git
WORKDIR /tmp/xrdp
RUN ./bootstrap
RUN ./configure
RUN make

# Finaly build the drivers
WORKDIR /tmp/xrdp/sesman/chansrv/pulse
RUN sed -i "s/\/tmp\/pulseaudio\-10\.0/\/tmp\/pulseaudio\-11\.1/g" Makefile
RUN make
RUN mkdir -p /tmp/so
RUN cp *.so /tmp/so

FROM ubuntu:18.04
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

# Docker config
VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]
