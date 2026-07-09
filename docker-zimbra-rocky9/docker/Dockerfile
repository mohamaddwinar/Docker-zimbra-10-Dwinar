####################################################################
# Dockerfile to build Zimbra 10.1 Network Edition on Rocky Linux 9
####################################################################

FROM rockylinux:9

ENV container=docker
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm

RUN set -eux; \
    dnf -y clean all; \
    dnf -y makecache; \
    dnf -y install dnf-plugins-core; \
    dnf -y install epel-release || true; \
    dnf config-manager --set-enabled crb || true; \
    dnf -y makecache; \
    for pkg in \
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
      zip; \
    do \
      echo "===== Installing $pkg ====="; \
      dnf -y --setopt=install_weak_deps=False install "$pkg"; \
    done; \
    dnf clean all; \
    rm -rf /var/cache/dnf /var/tmp/* /tmp/*

VOLUME ["/opt/zimbra"]

EXPOSE 22 25 465 587 110 143 993 995 80 443 8080 8443 7071 9071

COPY opt /opt/

RUN chmod +x /opt/start.sh

CMD ["/bin/bash", "/opt/start.sh", "-d"]