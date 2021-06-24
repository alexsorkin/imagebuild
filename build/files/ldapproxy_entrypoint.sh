#!/bin/bash -e

set -o pipefail

LDAP_ADDRESS="ldap:///"
LDAPS_ADDRESS="ldaps:///"
LDAPI_ADDRESS="ldapi:///"
SLAPD_CONF_FILE=${SLAPD_CONF_FILE:-/etc/openldap/config/slapd.conf}
LDAP_DEBUG=${DEBUG_LEVEL:-256}

MONITORING_ROOTDN=${MONITORING_ROOTDN:-cn=monitoring,cn=Monitor}
MONITORING_ROOTPW=${MONITORING_ROOTPW:-changeit}

if [[ -f "/etc/openldap/config/source/slapd.conf" ]]; then
  cat /etc/openldap/config/source/slapd.conf | sed "s#{ ROOTDN }#$MONITORING_ROOTDN#g" | sed "s#{ ROOTPW }#$MONITORING_ROOTPW#g" > ${SLAPD_CONF_FILE}
fi
if [[ -f "/etc/openldap/config/source/ldap.conf" ]]; then
  cat /etc/openldap/config/source/ldap.conf > /usr/local/etc/openldap/ldap.conf
fi
if [[ -d "/etc/openldap/ssl/ca" ]]; then
  for file in $(ls -tr /etc/openldap/ssl/ca/|xargs); do
    cat /etc/openldap/ssl/ca/$file > /usr/local/share/ca-certificates/$file
  done
  update-ca-certificates 2>/dev/null || true
fi

if [[ "x${LDAP_LISTEN_PROTOCOL}" == "xldaps" ]]; then
  LISTEN_URI="ldap://127.0.0.1 ${LDAPS_ADDRESS} ${LDAPI_ADDRESS}"
else
  LISTEN_URI="${LDAP_ADDRESS} ${LDAPI_ADDRESS}"
fi

slapd_cmd="/usr/local/libexec/slapd -u openldap -g openldap -f ${SLAPD_CONF_FILE} -h \"${LISTEN_URI}\" -d ${LDAP_DEBUG}"

echo $slapd_cmd

/usr/local/libexec/slapd -u openldap -g openldap -f ${SLAPD_CONF_FILE} -h "${LISTEN_URI}" -d ${LDAP_DEBUG}
