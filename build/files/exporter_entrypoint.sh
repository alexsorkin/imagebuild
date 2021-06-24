#!/bin/bash -e

set -o pipefail

LDAP_ADDRESS=${LDAP_ADDRESS:-localhost:389}
ROOTDN=${ROOTDN:-cn=monitoring,cn=Monitor}
ROOTPW=${ROOTPW:-changeit}
INTERVAL=${INTERVAL:-30s}
PROMPORT=${PROMPORT:-9330}

/usr/bin/openldap_exporter \
  -ldapAddr ${LDAP_ADDRESS} \
  -ldapUser ${ROOTDN} \
  -ldapPass ${ROOTPW} \
  -interval ${INTERVAL} \
  -promAddr 0.0.0.0:${PROMPORT}
