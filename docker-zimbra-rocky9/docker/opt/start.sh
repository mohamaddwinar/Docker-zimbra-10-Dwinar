#!/usr/bin/env bash
set -euo pipefail

MODE="${1:--d}"
PASSWORD="${PASSWORD:-ChangeMe123!}"
TIMEZONE="${TIMEZONE:-Asia/Jakarta}"
DNS_FORWARDER_1="${DNS_FORWARDER_1:-8.8.8.8}"
DNS_FORWARDER_2="${DNS_FORWARDER_2:-1.1.1.1}"

ZIMBRA_INSTALLER_URL="${ZIMBRA_INSTALLER_URL:-https://files.zimbra.com/downloads/10.1.0_GA/zcs-NETWORK-10.1.0_GA_4688.RHEL9_64.20240911074203.tgz}"
ZIMBRA_INSTALLER_ARCHIVE="/opt/zimbra-install/zimbra-rocky9.tgz"
ZIMBRA_INSTALLER_DIR="/opt/zimbra-install/zcs-NETWORK-10.1.0_GA_4688.RHEL9_64.20240911074203"
PHASE2_MARKER="/opt/zimbra/.docker_zimbra_phase2_done"

log() {
  echo "[$(date '+%F %T')] $*"
}

get_fqdn() {
  hostname -f 2>/dev/null || hostname
}

random_string() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "${1:-12}" || true
}

FQDN="$(get_fqdn)"
SHORT_HOST="${FQDN%%.*}"
DOMAIN="${FQDN#*.}"

if [[ "${DOMAIN}" == "${FQDN}" || -z "${DOMAIN}" ]]; then
  DOMAIN="localdomain"
  FQDN="${SHORT_HOST}.${DOMAIN}"
fi

CONTAINER_IP="$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')"
if [[ -z "${CONTAINER_IP}" ]]; then
  CONTAINER_IP="$(hostname -I | awk '{print $1}')"
fi

RANDOM_1="$(random_string 9)"
RANDOM_2="$(random_string 14)"
SYSTEM_MEMORY_MB="$(free -m | awk 'NR==2{print int($2)}')"
MAILBOXD_MEMORY_MB="$(free -m | awk 'NR==2{print int($2*0.25)}')"
[[ "${MAILBOXD_MEMORY_MB}" -lt 512 ]] && MAILBOXD_MEMORY_MB=512

mkdir -p /opt/zimbra-install /run/named /var/named /var/log
chown -R named:named /run/named /var/named 2>/dev/null || true

configure_hosts() {
  log "Configuring hosts and resolver"
  cat > /etc/hosts <<HOSTS
127.0.0.1 localhost.localdomain localhost
${CONTAINER_IP} ${FQDN} ${SHORT_HOST}
HOSTS

  cat > /etc/resolv.conf <<RESOLV
search ${DOMAIN}
nameserver 127.0.0.1
nameserver ${DNS_FORWARDER_1}
nameserver ${DNS_FORWARDER_2}
RESOLV
}

configure_dns() {
  log "Configuring local BIND DNS"
  cat > /etc/named.conf <<NAMED
options {
  directory "/var/named";
  listen-on port 53 { 127.0.0.1; ${CONTAINER_IP}; };
  listen-on-v6 { none; };
  allow-query { any; };
  recursion yes;
  forwarders { ${DNS_FORWARDER_1}; ${DNS_FORWARDER_2}; };
  dnssec-validation no;
};

zone "${DOMAIN}" IN {
  type master;
  file "db.${DOMAIN}";
  allow-update { none; };
};
NAMED

  cat > "/var/named/db.${DOMAIN}" <<ZONE
\$TTL 86400
@   IN SOA ${FQDN}. root.${DOMAIN}. (
        $(date +%Y%m%d%H) ; serial
        3600       ; refresh
        1800       ; retry
        604800     ; expire
        86400 )    ; minimum

@             IN NS   ${FQDN}.
@             IN MX 10 ${FQDN}.
@             IN A    ${CONTAINER_IP}
${SHORT_HOST} IN A    ${CONTAINER_IP}
ZONE

  named-checkconf || true
  named-checkzone "${DOMAIN}" "/var/named/db.${DOMAIN}" || true
  pkill named 2>/dev/null || true
  /usr/sbin/named -u named -c /etc/named.conf || true
  sleep 3

  getent hosts "${FQDN}" || true
  getent hosts files.zimbra.com || true
}

start_base_services() {
  log "Starting base services"
  rsyslogd >/dev/null 2>&1 || true
  crond >/dev/null 2>&1 || true
}

create_answer_file() {
  log "Creating Zimbra answer file"
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
n
y
y
y
y
y
y
ANSWERS
}

create_config_file() {
  log "Creating Zimbra config file"
  cat > /opt/zimbra-install/installZimbraScript <<CONFIG
AVDOMAIN="${DOMAIN}"
AVUSER="admin@${DOMAIN}"
CREATEADMIN="admin@${DOMAIN}"
CREATEADMINPASS="${PASSWORD}"
CREATEDOMAIN="${DOMAIN}"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
ENABLEDEFAULTBACKUP="yes"
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
LDAPDEFAULTSLOADED="1"
LDAPHOST="${FQDN}"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
LDAPROOTPASS="${RANDOM_2}"
LDAPADMINPASS="${RANDOM_2}"
LDAPPOSTPASS="${RANDOM_2}"
LDAPREPPASS="${RANDOM_2}"
LDAPAMAVISPASS="${RANDOM_2}"
ldap_bes_searcher_password="${RANDOM_2}"
ldap_nginx_password="${RANDOM_2}"
MAILBOXDMEMORY="${MAILBOXD_MEMORY_MB}"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
ONLYOFFICEHOSTNAME="${FQDN}"
ONLYOFFICESTANDALONE="no"
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
STRICTSERVERNAMEENABLED="TRUE"
SYSTEMMEMORY="${SYSTEM_MEMORY_MB}"
TRAINSAHAM="ham.${RANDOM_1}@${DOMAIN}"
TRAINSASPAM="spam.${RANDOM_1}@${DOMAIN}"
VIRUSQUARANTINE="virus-quarantine.${RANDOM_1}@${DOMAIN}"
UIWEBAPPS="yes"
UPGRADE="yes"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
ZIMBRA_REQ_SECURITY="yes"
ldap_dit_base_dn_config="cn=zimbra"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="${RANDOM_2}"
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
zimbraMtaMyNetworks="127.0.0.0/8 [::1]/128 ${CONTAINER_IP}/32"
zimbraPrefTimeZoneId="${TIMEZONE}"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckInterval="1d"
zimbraVersionCheckNotificationEmail="admin@${DOMAIN}"
zimbraVersionCheckNotificationEmailFrom="admin@${DOMAIN}"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="TRUE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
zimbra_server_hostname="${FQDN}"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-store zimbra-apache zimbra-spell zimbra-convertd zimbra-memcached zimbra-proxy zimbra-archiving zimbra-onlyoffice zimbra-license-daemon zimbra-snmp"
CONFIG
}

download_installer() {
  if [[ ! -f "${ZIMBRA_INSTALLER_ARCHIVE}" ]]; then
    log "Downloading Zimbra installer"
    curl -fL --retry 5 --retry-delay 10 --connect-timeout 30 \
      -o "${ZIMBRA_INSTALLER_ARCHIVE}.part" "${ZIMBRA_INSTALLER_URL}"
    mv "${ZIMBRA_INSTALLER_ARCHIVE}.part" "${ZIMBRA_INSTALLER_ARCHIVE}"
  fi

  if [[ ! -d "${ZIMBRA_INSTALLER_DIR}" ]]; then
    log "Extracting Zimbra installer"
    tar -xzf "${ZIMBRA_INSTALLER_ARCHIVE}" -C /opt/zimbra-install
  fi
}

install_phase1() {
  if [[ ! -x /opt/zimbra/libexec/zmsetup.pl ]]; then
    log "Running Zimbra installer phase 1"
    (
      cd "${ZIMBRA_INSTALLER_DIR}"
      ./install.sh --skip-activation-check -s < /opt/zimbra-install/installZimbra-keystrokes | tee /opt/zimbra-install/install.log
    )
  else
    log "Phase 1 already completed"
  fi
}

install_phase2() {
  if [[ ! -f "${PHASE2_MARKER}" ]]; then
    log "Running Zimbra installer phase 2"
    /opt/zimbra/libexec/zmsetup.pl -c /opt/zimbra-install/installZimbraScript | tee /opt/zimbra-install/zmsetup.log
    touch "${PHASE2_MARKER}"
  else
    log "Phase 2 already completed"
  fi
}

post_install() {
  log "Post install restart and validation"
  su - zimbra -c "zmprov mcf +zimbraMailTrustedIP 127.0.0.1 +zimbraMailTrustedIP ${CONTAINER_IP}" || true
  su - zimbra -c "zmcontrol restart" || true
  sleep 60
  su - zimbra -c "zmcontrol status" || true
  su - zimbra -c "zmcontrol -v" || true
}

main() {
  configure_hosts
  configure_dns
  start_base_services

  if [[ -x /opt/zimbra/bin/zmcontrol && -f "${PHASE2_MARKER}" ]]; then
    log "Zimbra already installed. Starting services."
    su - zimbra -c "zmcontrol start" || true
    tail -f /dev/null
  fi

  create_answer_file
  create_config_file
  download_installer
  install_phase1
  install_phase2
  post_install

  if [[ "${MODE}" == "-d" ]]; then
    log "Container ready. Keeping foreground process alive."
    tail -f /dev/null
  fi
}

main "$@"
