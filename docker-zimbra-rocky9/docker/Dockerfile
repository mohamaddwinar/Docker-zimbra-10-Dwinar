####################################################################
# Dockerfile to build Zimbra 10.1 Network Edition on Rocky Linux 9
# Based on the old docker-zimbra-8_8_15-dwinar flow:
# - prepare DNS inside container
# - download Zimbra installer
# - run install.sh -s with answer file
# - run zmsetup.pl with generated config
####################################################################

FROM rockylinux:9

ENV container=docker
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm

RUN dnf -y install dnf-plugins-core epel-release && \
    dnf config-manager --set-enabled crb || true && \
    dnf -y update && \
    dnf -y install \
      bash \
      bash-completion \
      bind \
      bind-utils \
      ca-certificates \
      chrony \
      cronie \
      curl \
      diffutils \
      findutils \
      glibc-langpack-en \
      gzip \
      hostname \
      iproute \
      iputils \
      less \
      libaio \
      libxcrypt-compat \
      lsof \
      nc \
      net-tools \
      nmap-ncat \
      openssh-clients \
      openssl \
      perl \
      perl-core \
      procps-ng \
      rsync \
      rsyslog \
      shadow-utils \
      sudo \
      tar \
      tmux \
      unzip \
      vim-minimal \
      wget \
      which \
      xz \
      zip && \
    dnf clean all && \
    rm -rf /var/cache/dnf

VOLUME ["/opt/zimbra"]

EXPOSE 22 25 465 587 110 143 993 995 80 443 8080 8443 7071 9071

COPY opt /opt/
COPY etc /etc/

RUN chmod +x /opt/start.sh

CMD ["/bin/bash", "/opt/start.sh", "-d"]
