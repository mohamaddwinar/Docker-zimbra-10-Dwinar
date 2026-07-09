#!/usr/bin/env bash
set -euo pipefail

MODE="${1:- -d}"
PASSWORD="${PASSWORD:-ChangeMe123!}"
TIMEZONE="${TIMEZONE:-Asia/Jakarta}"
DNS_FORWARDER_1="${DNS_FORWARDER_1:-8.8.8.8}"
DNS_FORWARDER_2="${DNS_FORWARDER_2:-1.1.1.1}"
ZIMBRA_INSTALLER_URL="${ZIMBRA_INSTALLER_URL:-https://files.zimbra.com/downloads/10.1.0_GA/zcs-NETWORK-10.1.0_GA_4688.RHEL9_64.20240911074203.tgz}"
ZIMBRA_INSTALLER_ARCHIVE="/opt/zimbra-install/zimbra-rocky9.tgz"
ZIMBRA_INSTALLER_DIR="/opt/zimbra-install/zcs-NETWORK-10.1.0_GA_4688.RHEL9_64.20240911074203"

mkdir -p /opt/zimbra-install /run/named /var/named /var/log
chown -R named:named /run/named /var/named || true

get_fqdn() {
  hostname -f 2>/dev/null || hostname
}

FQDN="$(get_fqdn)"
SHORT_HOST="${FQDN%%.*}"
DOMAIN="${FQDN#*.}"
if [[ "$DOMAIN" == "$FQDN" || -z "$DOMAIN" ]]; then
  DOMAIN="localdomain"
  FQDN="${SHORT_HOST}.${DOMAIN}"
fi

CONTAINER_IP="$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')"
if [[ -z "${CONTAINER_IP}" ]]; then
  CONTAINER_IP="$(hostname -I | awk '{print $1}')"
fi

RANDOMHAM="$(date +%s%N | sha256sum | base64 | head -c 10)"
RANDOMSPAM="$(date +%s%N | sha256sum | base64 | head -c 10)"
RANDOMVIRUS="$(date +%s%N | sha256sum | base64 | head -c 10)"
SYSTEMMEMORY="$(free -m | awk 'NR==2{printf "%.1f", $2/1024}')"
MAILBOXDMEMORY="$(free -m | awk 'NR==2{print int($2*0.25)}')"
[[ "$MAILBOXDMEMORY" -lt 512 ]] && MAILBOXDMEMORY=512

log() {
  echo "[$(date '+%F %T')] $*"
}

configure_hosts() {
  cat > /etc/hosts <<HOSTS
127.0.0.1 localhost.localdomain localhost
${CONTAINER_IP} ${FQDN} ${SHORT_HOST}
HOSTS
}

configure_resolv() {
  cat > /etc/resolv.conf <<RESOLV
search ${DOMAIN}
nameserver 127.0.0.1
nameserver ${DNS_FORWARDER_1}
nameserver ${DNS_FORWARDER_2}
RESOLV
}

configure_named() {
  cat > /etc/named.conf <<NAMEDCONF
options {
  directory "/var/named";
  listen-on port 53 { 127.0.0.1; };
  listen-on-v6 { none; };
  allow-query { localhost; 127.0.0.1; ${CONTAINER_IP}; };
  recursion yes;
  allow-recursion { localhost; 127.0.0.1; ${CONTAINER_IP}; };
  forwarders {
    ${DNS_FORWARDER_1};
    ${DNS_FORWARDER_2};
  };
  dnssec-validation no;
  auth-nxdomain no;
};

zone "${DOMAIN}" IN {
  type master;
  file "db.${DOMAIN}";
  allow-update { none; };
};
NAMEDCONF

  cat > "/var/named/db.${DOMAIN}" <<ZONE
\$TTL 86400
@   IN SOA ${FQDN}. admin.${DOMAIN}. (
        $(date +%Y%m%d%H) ; serial
        3600       ; refresh
        1800       ; retry
        604800     ; expire
        86400 )    ; minimum

@             IN NS  ${FQDN}.
@             IN MX 10 ${FQDN}.
${SHORT_HOST} IN A   ${CONTAINER_IP}
@             IN A   ${CONTAINER_IP}
ZONE

  chown named:named /etc/named.conf "/var/named/db.${DOMAIN}" || true
  named-checkconf /etc/named.conf
  named-checkzone "${DOMAIN}" "/var/named/db.${DOMAIN}"
}

start_base_services() {
  log "Starting named"
  pkill named >/dev/null 2>&1 || true
  /usr/sbin/named -u named -c /etc/named.conf || true
  sleep 2

  log "Starting rsyslog/crond if available"
  rsyslogd >/dev/null 2>&1 || true
  crond >/dev/null 2>&1 || true
}

create_answer_file() {
  cat > /opt/zimbra-install/installZimbra-keystrokes <<'ANSWERS'
y
y
y
y
y
n
y
y
y
y
y
y
y
y
y
y
y
y
y
y
y
ANSWERS
}

create_config_file() {
  cat > /opt/zimbra-install/installZimbraScript <<CONFIG
AVDOMAIN="${DOMAIN}"
AVUSER="admin@${DOMAIN}"
CREATEADMIN="admin@${DOMAIN}"
CREATEADMINPASS="${PASSWORD}"
CREATEDOMAIN="${DOMAIN}"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="${FQDN}"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPBESSEARCHSET="set"
LDAPHOST="${FQDN}"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="${MAILBOXDMEMORY}"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="yes"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@${DOMAIN}"
SMTPHOST="${FQDN}"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@${DOMAIN}"
SNMPNOTIFY="yes"
SNMPTRAPHOST="${FQDN}"
SPELLURL="http://${FQDN}:7780/aspell.php"
STARTSERVERS="yes"
STRICTSERVERNAMEENABLED="FALSE"
SYSTEMMEMORY="${SYSTEMMEMORY}"
TRAINSAHAM="ham.${RANDOMHAM}@${DOMAIN}"
TRAINSASPAM="spam.${RANDOMSPAM}@${DOMAIN}"
UIWEBAPPS="yes"
UPGRADE="yes"
USEEPHEMERALSTORE="no"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.${RANDOMVIRUS}@${DOMAIN}"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="${PASSWORD}"
ldap_dit_base_dn_config="cn=zimbra"
LDAPROOTPASS="${PASSWORD}"
LDAPADMINPASS="${PASSWORD}"
LDAPPOSTPASS="${PASSWORD}"
LDAPREPPASS="${PASSWORD}"
LDAPAMAVISPASS="${PASSWORD}"
ldap_nginx_password="${PASSWORD}"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="${PASSWORD}"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/common/lib/jvm/java/lib/security/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="TRUE"
zimbraMtaMyNetworks="127.0.0.0/8 ${CONTAINER_IP}/32 [::1]/128 [fe80::]/64"
zimbraPrefTimeZoneId="${TIMEZONE}"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckNotificationEmail="admin@${DOMAIN}"
zimbraVersionCheckNotificationEmailFrom="admin@${DOMAIN}"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="TRUE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-license-daemon zimbra-store zimbra-apache zimbra-spell zimbra-convertd zimbra-memcached zimbra-proxy zimbra-archiving zimbra-onlyoffice zimbra-patch zimbra-mta-patch zimbra-proxy-patch zimbra-ldap-patch"
CONFIG
}

download_installer() {
  if [[ ! -f "${ZIMBRA_INSTALLER_ARCHIVE}" ]]; then
    log "Downloading Zimbra installer: ${ZIMBRA_INSTALLER_URL}"
    curl -fL --retry 5 --retry-delay 10 --connect-timeout 30 \
      -o "${ZIMBRA_INSTALLER_ARCHIVE}.part" "${ZIMBRA_INSTALLER_URL}"
    mv "${ZIMBRA_INSTALLER_ARCHIVE}.part" "${ZIMBRA_INSTALLER_ARCHIVE}"
  fi

  if [[ ! -d "${ZIMBRA_INSTALLER_DIR}" ]]; then
    log "Extracting installer"
    tar xzf "${ZIMBRA_INSTALLER_ARCHIVE}" -C /opt/zimbra-install/
  fi
}

install_zimbra() {
  log "Update dnf cache"
  dnf -y makecache || true

  create_answer_file
  create_config_file
  download_installer

  log "Phase 1: install Zimbra packages"
  cd "${ZIMBRA_INSTALLER_DIR}"
  ./install.sh --skip-activation-check -s < /opt/zimbra-install/installZimbra-keystrokes | tee /opt/zimbra-install/install.log

  log "Phase 2: configure Zimbra"
  /opt/zimbra/libexec/zmsetup.pl -c /opt/zimbra-install/installZimbraScript | tee /opt/zimbra-install/zmsetup.log

  log "Set trusted IP"
  su - zimbra -c "/opt/zimbra/bin/zmprov mcf +zimbraMailTrustedIP 127.0.0.1 +zimbraMailTrustedIP ${CONTAINER_IP}" || true

  log "Restart Zimbra"
  su - zimbra -c "zmcontrol restart" || true
}

start_existing_zimbra() {
  log "Starting existing Zimbra installation"
  su - zimbra -c "zmcontrol start" || true
  sleep 30
  su - zimbra -c "zmcontrol status" || true
}

main() {
  log "Container FQDN=${FQDN} DOMAIN=${DOMAIN} IP=${CONTAINER_IP}"

  configure_hosts
  configure_named
  configure_resolv
  start_base_services

  log "DNS check"
  getent hosts "${FQDN}" || true
  getent hosts files.zimbra.com || true
  getent hosts repo.zimbra.com || true

  if [[ -x /opt/zimbra/bin/zmcontrol ]]; then
    start_existing_zimbra
  else
    install_zimbra
  fi

  log "Final status"
  su - zimbra -c "zmcontrol -v" || true
  su - zimbra -c "zmcontrol status" || true

  if [[ "${MODE}" == "-bash" ]]; then
    exec /bin/bash
  fi

  if [[ "${MODE}" == "-d" ]]; then
    log "Keep container running"
    while true; do
      sleep 3600
    done
  fi
}

main "$@"
