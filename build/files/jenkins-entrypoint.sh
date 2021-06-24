#!/bin/bash

BASE_PEM_DIR=${BASE_PEM_DIR:-/var/lib/tls/ca}
ENCODED_PEM_FILE=${ENCODED_PEM_FILE:-}
KEYSTORE="${JAVA_HOME}/jre/lib/security/cacerts"
PASSWORD=changeit
PEM_FILES=$(ls -tr $BASE_PEM_DIR/$ENCODED_PEM_FILE 2>/dev/null | xargs)
PEM_WORK_DIR=/tmp/chains
mkdir -p $PEM_WORK_DIR
for pem in ${PEM_FILES}; do
    PEM_FILE=$pem
    PEM_BASENAME=$(basename $PEM_FILE)
    DECODED_FILE="${PEM_WORK_DIR}/${PEM_BASENAME}"
    if [ -f $PEM_FILE ]; then
        echo processing $pem
        if [ "x${ENCODED_PEM_FILE}" != "x" ]; then
            cat $PEM_FILE| base64 -d > ${DECODED_FILE}
        else
            cat $PEM_FILE > ${DECODED_FILE}
        fi
        # number of certs in the PEM file
        CERTS=$(grep 'END CERTIFICATE' $DECODED_FILE| wc -l| xargs)

        # For every cert in the PEM file, extract it and import into the JKS keystore
        # awk command: step 1, if line is in the desired cert, print the line
        #              step 2, increment counter when last line of cert is found
        if [[ $CERTS -gt 0 ]]; then
            for N in $(seq 0 $(($CERTS - 1))); do
                echo "Found Certificate in chain, $PEM_BASENAME:$N, importing.."
                ALIAS="${PEM_BASENAME%.*}-$N"
                cat $DECODED_FILE | \
                    awk "n==$N { print }; /END CERTIFICATE/ { n++ }" \
                        > ${DECODED_FILE}_extracted
                    
                    keytool -noprompt -import -trustcacerts -file ${DECODED_FILE}_extracted \
                        -alias $ALIAS -keystore $KEYSTORE -storepass $PASSWORD 2>&1
            done
        else
            echo File is not a pem certificate chain, skipping.
        fi
    fi
done

if [[ "x${JAVA_EXTRA_OPTS}" != "x" ]]; then
	JAVA_OPTS="${JAVA_OPTS} ${JAVA_EXTRA_OPTS}"
fi

exec "$@"
