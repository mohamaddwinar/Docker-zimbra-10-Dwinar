####################################################################
# Dockerfile to build Zimbra 10.1 Network Edition on Rocky Linux 9
####################################################################

FROM rockylinux:9

LABEL org.opencontainers.image.title="Docker Zimbra 10 Dwinar"
LABEL org.opencontainers.image.description="Docker image for Zimbra 10.1 Network Edition on Rocky Linux 9 for lab and testing."
LABEL org.opencontainers.image.source="https://github.com/mohamaddwinar/Docker-zimbra-10-Dwinar"
LABEL org.opencontainers.image.licenses="MIT"

ENV container=docker
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm

RUN set -eux; \
    dnf -y clean all; \
    dnf -y makecache; \
    dnf -y install dnf-plugins-core; \
    dnf -y install epel-release || true; \
    dnf config-manager --set-enabled crb || true; \
    dnf -y makecache; \
    dnf -y --setopt=install_weak_deps=False install \
      bash \
      bash-completion \
      bind \
      bind-utils \
      ca-certificates \
      chrony \
      cronie \
      curl-minimal \
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
    dnf clean all; \
    rm -rf /var/cache/dnf /var/tmp/* /tmp/*

VOLUME ["/opt/zimbra"]

EXPOSE 22 25 465 587 110 143 993 995 80 443 8080 8443 7071 9071

COPY opt /opt/

RUN sed -i 's/\r$//' /opt/start.sh && chmod +x /opt/start.sh

CMD ["/bin/bash", "/opt/start.sh", "-d"]
