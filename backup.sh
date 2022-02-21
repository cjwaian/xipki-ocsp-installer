#!/bin/sh

# Back up XiPKI OCSP Server


# Import installation variables
source ./install.config;



# ocsp-responder.json
if [ -f $XIPKI_OCSP_CONF ] ; then
	if [ -f $MY_OCSP_CONF ] ; then
		mv -f $MY_OCSP_CONF $MY_OCSP_CONF.old
	fi
	cp -f $XIPKI_OCSP_CONF $MY_OCSP_CONF
fi


# ocsp-cache-db.properties
if [ -f $XIPKI_DB_CONF_CACHE ] ; then
	if [ -f $MY_DB_CONF_CACHE ] ; then
		mv -f $MY_DB_CONF_CACHE $MY_DB_CONF_CACHE.old
	fi
	cp -f $XIPKI_DB_CONF_CACHE $MY_DB_CONF_CACHE
fi

# ocsp-crl-db.properties
if [ -f $XIPKI_DB_CONF_CRL ] ; then
	if [ -f $MY_DB_CONF_CRL ] ; then
		mv -f $MY_DB_CONF_CRL $MY_DB_CONF_CRL.old
	fi
	cp -f $XIPKI_DB_CONF_CRL $MY_DB_CONF_CRL
fi


# root .crl
if [ -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_ROOT_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_ROOT_NAME}/ca.crl" ] ; then
	if [ -f $MY_CA_ROOT_CRL ] ; then
		mv -f $MY_CA_ROOT_CRL $MY_CA_ROOT_CRL.old
	fi
	cp -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_ROOT_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_ROOT_NAME}/ca.crl" "${WORK_DIR}/${MY_CA_ROOT_NAME}-ca.crl"
fi

# root .crt
if [ -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_ROOT_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_ROOT_NAME}/ca.crt" ] ; then
	if [ -f $MY_CA_ROOT_CRT ] ; then
		mv -f $MY_CA_ROOT_CRT $MY_CA_ROOT_CRT.old
	fi
	cp -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_ROOT_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_ROOT_NAME}/ca.crt" "${WORK_DIR}/${MY_CA_ROOT_NAME}-ca.crt"
fi

#intermediate .crl
if [ -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_INTERMEDIATE_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_INTERMEDIATE_NAME}/ca.crl" ] ; then
	if [ -f $MY_CA_INTERMEDIATE_CRL ] ; then
		mv -f $MY_CA_INTERMEDIATE_CRL $MY_CA_INTERMEDIATE_CRL.old
	fi
	cp -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_INTERMEDIATE_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_INTERMEDIATE_NAME}/ca.crl" "${WORK_DIR}/${MY_CA_INTERMEDIATE_NAME}-ca.crl"
fi

# root .crt
if [ -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_INTERMEDIATE_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_INTERMEDIATE_NAME}/ca.crt" ] ; then
	if [ -f $MY_CA_INTERMEDIATE_CRT ] ; then
		mv -f $MY_CA_INTERMEDIATE_CRT $MY_CA_INTERMEDIATE_CRT.old
	fi
	cp -f "${XIPKI_CRL_TOP_DIR}/${XIPKI_CRL_STORE_PREFIX}${MY_CA_INTERMEDIATE_NAME}/${XIPKI_CRL_DIR_PREFIX}${MY_CA_INTERMEDIATE_NAME}/ca.crt" "${WORK_DIR}/${MY_CA_INTERMEDIATE_NAME}-ca.crt"
fi



# Root OCSP P12
if [ -f "${XIPKI_KEYSTORE_DIR}/${MY_CA_ROOT_NAME}-ocsp.p12" ] ; then
	if [ -f $MY_CA_ROOT_P12 ] ; then
		mv -f $MY_CA_ROOT_P12 $MY_CA_ROOT_P12.old
	fi
	cp -f "${XIPKI_KEYSTORE_DIR}/${MY_CA_ROOT_NAME}-ocsp.p12" $MY_CA_ROOT_P12
fi


# Intermediate OCSP P12
if [ -f "${XIPKI_KEYSTORE_DIR}/${MY_CA_INTERMEDIATE_NAME}-ocsp.p12" ] ; then
	if [ -f $MY_CA_INTERMEDIATE_P12 ] ; then
		mv -f $MY_CA_INTERMEDIATE_P12 $MY_CA_INTERMEDIATE_P12.old
	fi
	cp -f "${XIPKI_KEYSTORE_DIR}/${MY_CA_INTERMEDIATE_NAME}-ocsp.p12" $MY_CA_INTERMEDIATE_P12
fi


exit 0
