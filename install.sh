#!/bin/sh


# Import installation variables
source ./install.config;







# Install EPEL
CODEREADY_REPO="codeready-builder-for-rhel-8-$(/bin/arch)-rpms"
subscription-manager repos --enable "${CODEREADY_REPO}"

rpm --import https://getfedora.org/static/fedora.gpg;
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm;

# Install basic packages
dnf -y install nano net-tools bind-utils unzip wget


# Install Mariadb
dnf -y install mariadb-server 
systemctl enable --now mariadb

#mysql_secure_installation
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${DB_ROOT_PASS}') WHERE User = 'root'";
mysql -e "DROP USER ''@'localhost'";
mysql -e "DROP USER ''@'$(hostname)'";
mysql -e "DROP DATABASE test";
mysql -e "FLUSH PRIVILEGES";

# Create db user
mysql -u root -p$DB_ROOT_PASS -e "CREATE USER IF NOT EXISTS '${XIPKI_DB_USER}'@'%' IDENTIFIED BY '${XIPKI_DB_PASS}';";

# Create db ocspcache
DB_OCSP_CACHE_NAME="ocspcache"
mysql -u root -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS ${DB_OCSP_CACHE_NAME} CHARSET utf8;";
mysql -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON ${DB_OCSP_CACHE_NAME}.* TO '${XIPKI_DB_USER}'@'%';";

# Create db ocspcrl
DB_OCSP_CRL_NAME="ocspcrl"
mysql -u root -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS ${DB_OCSP_CRL_NAME} CHARSET utf8;";
mysql -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON ${DB_OCSP_CRL_NAME}.* TO '${XIPKI_DB_USER}'@'%';";
mysql -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;";




# Install Java
dnf -y install java-11-openjdk-devel 
#alternatives --config java
#alternatives --config javac

# Jboss Deps
dnf -y install apr selinux-policy-devel
yum remove tomcatjss


# Install JBoss Web Application Server
JWS_APP_DIR="./jws"
# JWS_TOMCAT_DIR="$JWS_APP_DIR/jws-*/tomcat"
JWS_TOMCAT_DIR="$JWS_APP_DIR"
rm -rf $TOMCAT_DIR
cp -R $JWS_TOMCAT_DIR $TOMCAT_DIR
rm -rf $TOMCAT_WEBAPP_ROOT_WAR_DIR
rm -rf TOMCAT_WEBAPP_ROOT_WAR="${TOMCAT_WEBAPP_DIR}/ROOT.war"


echo "org.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true" >> $TOMCAT_PROPERTIES
echo "Edit $TOMCAT_PROPERTIES: tomcat.util.scan.StandardJarScanFilter.jarsToSkip"
echo "bcprov-*.jar,\
bcpkix-*.jar,\
bcutil-*.jar,\
datasource-*.jar,\
fastjson-*.jar,\
HikariCP-*.jar,\
log4j-*.jar,\
mariadb-java-client-*.jar,\
ocsp-*.jar,\
password-*.jar,\
postgresql-*.jar,\
security-*.jar,\
slf4j-*.jar,\
sunpkcs11-wrapper-*.jar,\
*-tinylog.jar,\
tinylog*.jar,\
util-*.jar"

rm -f /.postinstall.done

chmod +x $TOMCAT_DIR/.postinstall.systemd
cd $TOMCAT_DIR
sh $TOMCAT_DIR/.postinstall.systemd
cd $WORK_DIR
rm -f $TOMCAT_DIR/.postinstall.systemd

chmod +x $TOMCAT_DIR/.postinstall.selinux
cd $TOMCAT_DIR
sh $TOMCAT_DIR/.postinstall.selinux
cd $WORK_DIR
rm -f $TOMCAT_DIR/.postinstall.selinux
# selinux
semanage port -a -t http_port_t -p tcp 8080
cd $WORK_DIR


# Tomcat User
groupadd -g 53 -r $TOMCAT_USER
useradd -c $TOMCAT_USER -u 53 -g $TOMCAT_USER -s /sbin/nologin -r $TOMCAT_USER



# Download XiPKI DB Tool
wget $XIPKI_DBTOOL_URL
unzip $WORK_DIR/xipki-dbtool-*.zip
mv -f $WORK_DIR/xipki-dbtool-*/ $WORK_DIR/xipki-dbtool

# Download XiPKI OCSP Server
wget $XIPKI_OCSP_URL
unzip $WORK_DIR/xipki-ocsp-*.zip
mv -f $WORK_DIR/xipki-ocsp-*/ $WORK_DIR/xipki-ocsp



# Install XiPKI to Tomcat dir
cp -r $WORK_DIR/xipki-ocsp/bin/* $TOMCAT_DIR/bin/
echo "export JAVA_HOME=/usr/lib/jvm/jre" >> $TOMCAT_BIN_DIR/setenv.sh
echo "export JWS_HOME=$TOMCAT_DIR" >> $TOMCAT_BIN_DIR/setenv.sh
cp -r $WORK_DIR/xipki-ocsp/lib/* $TOMCAT_DIR/lib/
# ./webapps
cp -r $WORK_DIR/xipki-ocsp/webapps/* $TOMCAT_WEBAPP_DIR/
rm -rf $TOMCAT_WEBAPP_DIR/ROOT
rm -rf $TOMCAT_WEBAPP_DIR/ROOT.war
mv $TOMCAT_WEBAPP_DIR/ocsp.war $TOMCAT_WEBAPP_DIR/ROOT.war
# ./xipki
cp -r $WORK_DIR/xipki-ocsp/xipki $TOMCAT_XIPKI_DIR/



# Database setup
# ocsp-cache-db.properties
if [ -f $MY_DB_CONF_CACHE ] ; then
	# if we provide a prop file then copy that to the directory
	cp $MY_DB_CONF_CACHE $XIPKI_DB_CONF_CACHE
else
	# if nothing is provided move the example file into place
	cp $EXAMPLE_DB_CONF_CACHE $XIPKI_DB_CONF_CACHE
	sed -i "s~^dataSource.databaseName\s\=.*$~dataSource.databaseName = ${DB_OCSP_CACHE_NAME}~" $XIPKI_DB_CONF_CACHE
	sed -i "s~^dataSource.user\s\=.*$~dataSource.user = ${XIPKI_DB_USER}~" $XIPKI_DB_CONF_CACHE
	sed -i "s~^dataSource.password\s\=.*$~dataSource.password = ${XIPKI_DB_PASS}~" $XIPKI_DB_CONF_CACHE
fi
# need to use relative path
cd $WORK_DIR
# init the ocspcache db
$WORK_DIR/xipki-dbtool/bin/initdb.sh -f --db-schema $XIPKI_DBTOOL_CACHE_SCHEMA --db-conf $XIPKI_DB_CONF_CACHE

# ocsp-crl-db.properties
if [ -f $MY_DB_CONF_CRL ] ; then
	# if we provide a prop file then copy that to the directory
	cp $MY_DB_CONF_CRL $XIPKI_DB_CONF_CRL
else
	# if nothing is provided move the example file into place
	cp $EXAMPLE_DB_CRL_CACHE $XIPKI_DB_CONF_CRL
	sed -i "s~^dataSource.databaseName\s\=.*$~dataSource.databaseName = ${DB_OCSP_CRL_NAME}~" $XIPKI_DB_CONF_CRL
	sed -i "s~^dataSource.user\s\=.*$~dataSource.user = ${XIPKI_DB_USER}~" $XIPKI_DB_CONF_CRL
	sed -i "s~^dataSource.password\s\=.*$~dataSource.password = ${XIPKI_DB_PASS}~" $XIPKI_DB_CONF_CRL
fi
# need to use relative path
cd $WORK_DIR
# init the ocspcrl db
$WORK_DIR/xipki-dbtool/bin/initdb.sh -f --db-schema $XIPKI_DBTOOL_CRL_SCHEMA --db-conf $XIPKI_DB_CONF_CRL



# ocsp-responder.json
if [ -f $MY_OCSP_CONF ] ; then
	# if we provide a conf file then copy that to the directory
	cp $MY_OCSP_CONF $XIPKI_OCSP_CONF
else
	# if we dont provide a conf file, then copy the example version for a SINGLE CA
	cp $EXAMPLE_OCSP_CONF $XIPKI_OCSP_CONF
	sed -i "s~request1~request-${MY_CA_ROOT_NAME}~" $XIPKI_OCSP_CONF
	sed -i "s~responder1~responder-${MY_CA_ROOT_NAME}~" $XIPKI_OCSP_CONF
	sed -i "s~signer1~signer-${MY_CA_ROOT_NAME}~" $XIPKI_OCSP_CONF
	sed -i "s~store1~store-${MY_CA_ROOT_NAME}~" $XIPKI_OCSP_CONF
	sed -i "s~datasource1~datasource-${MY_CA_ROOT_NAME}~" $XIPKI_OCSP_CONF
	sed -i "s~\"key\"\s?\:\s?\".*\"~\"key\"\:\"password\=${MY_CA_ROOT_P12_PASS}\,keystore\=file\:keycerts\/${MY_CA_ROOT_NAME}\-ocsp\.p12\"~" $XIPKI_OCSP_CONF
	sed -i "s~\"dir\"\s?\:\s?\".*\"~\"dir\":\"crls/crl-store-${MY_CA_ROOT_NAME}\"~" $XIPKI_OCSP_CONF
	sed -i "s~\"servletPaths\"\s?\:\s?\[\".*\"\]~\"servletPaths\"\:\[\"${MY_CA_ROOT_OCSP_URL}\"\]~" $XIPKI_OCSP_CONF
fi



# keystore ocsp signer p12
cp $MY_CA_ROOT_P12 $XIPKI_OCSP_ROOT_P12
cp $MY_CA_INTERMEDIATE_P12 $XIPKI_OCSP_INTERMEDIATE_P12




# build CRL directory structure

# crls/crl-store-root
mkdir -p $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME
# crls/crl-store-root/crl-root
mkdir -p $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME
# root ca.crt
cp $MY_CA_ROOT_CRT $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME/ca.crt
cp $MY_CA_ROOT_CRT $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME/issuer.crt
# root ca.crl -  must be DER format!
cp $MY_CA_ROOT_CRL $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME/ca.crl
# root crl.url
echo "${MY_CA_ROOT_OCSP_FULL_URL}" > $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME/crl.url
# copy template files
cp $XIPKI_CRL_TOP_DIR/template/README $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/README
cp $XIPKI_CRL_TOP_DIR/template/crl-*/README $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME/README
cp $XIPKI_CRL_TOP_DIR/template/crl-*/REVOCATION $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME/REVOCATION
cp $XIPKI_CRL_TOP_DIR/template/crl-*/UPDATEME $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_ROOT_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_ROOT_NAME/UPDATEME


# crls/crl-store-intermediate
mkdir -p $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME
# crls/crl-store-root/crl-intermediate
mkdir -p $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME
# intermediate ca.crt
cp $MY_CA_INTERMEDIATE_CRT $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME/ca.crt
# intermediate issuer.crt
cp $MY_CA_INTERMEDIATE_ISSUER_CRT $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME/issuer.crt
# intermediate ca.crl -  must be DER format!
cp $MY_CA_INTERMEDIATE_CRL $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME/ca.crl
# intermediate crl.url
echo "${MY_CA_INTERMEDIATE_OCSP_FULL_URL}" > $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME/crl.url
# copy template files
cp $XIPKI_CRL_TOP_DIR/template/README $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/README
cp $XIPKI_CRL_TOP_DIR/template/crl-*/README $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME/README
cp $XIPKI_CRL_TOP_DIR/template/crl-*/REVOCATION $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME/REVOCATION
cp $XIPKI_CRL_TOP_DIR/template/crl-*/UPDATEME $XIPKI_CRL_TOP_DIR/$XIPKI_CRL_STORE_PREFIX$MY_CA_INTERMEDIATE_NAME/$XIPKI_CRL_DIR_PREFIX$MY_CA_INTERMEDIATE_NAME/UPDATEME


rm -rf $XIPKI_CRL_TOP_DIR/template


# set env
chmod +x $TOMCAT_BIN_DIR/setenv.sh
$TOMCAT_BIN_DIR/setenv.sh



# set perms
chown -R tomcat:tomcat $TOMCAT_DIR
chmod -R u+X $TOMCAT_DIR
chmod -R +x $TOMCAT_DIR/bin



# set WorkingDirectory=$TOMCAT_DIR in /usr/lib/systemd/system/jws5-tomcat.service
systemctl disable --now fapolicyd
systemctl enable jws5-tomcat.service --now
systemctl disable --now fapolicyd


exit 0
