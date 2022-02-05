



# Download Jboss web server
# https://access.redhat.com/jbossnetwork/restricted/listSoftware.html
# Need two items:
# 	Red Hat JBoss Web Server 5.6.0 Application Server for RHEL 8 x86_64
# 	Red Hat JBoss Web Server 5.6.0 Application Server




#fips-mode-setup --enable
#update-crypto-policies --set FIPS

systemctl enable open-vm-tools



CODEREADY_REPO="codeready-builder-for-rhel-8-$(/bin/arch)-rpms"
subscription-manager repos --enable "${CODEREADY_REPO}"
rpm --import https://getfedora.org/static/fedora.gpg;
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm;




dnf -y install nano net-tools dns-utils unzip wget selinux-policy-devel


XIPKI_OCSP_URL="https://github.com/xipki/xipki/releases/download/v5.3.14/ocsp-war-5.3.14.zip"
wget $XIPKI_OCSP_URL


dnf -y install mariadb-server java-11-openjdk-devel 
#alternatives --config java
#alternatives --config javac



#dnf -y install apr
yum remove tomcatjss


#unzip jws-5.5.0-application-server.zip -d /opt/
#unzip -o jws-5.6.0-application-server-RHEL8-x86_64.zip -d /opt/


#echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /opt/tomcat/bin/setenv.sh
#echo "export JWS_HOME=/opt" >> /opt/tomcat/bin/setenv.sh
#cd /opt
#/opt/tomcat/bin/setenv.sh

#cd /opt/tomcat
#sh ./.postinstall.systemd
#sh ./.postinstall.selinux
#semanage port -a -t http_port_t -p tcp 8080
#semanage port -a -t http_port_t -p tcp 8009
#semanage port -a -t http_port_t -p tcp 8443
#semanage port -a -t http_port_t -p tcp 8005


#groupadd -g 53 -r tomcat
#useradd -c "tomcat" -u 53 -g tomcat -s /sbin/nologin -r tomcat
#cd /opt
#chown -R tomcat:tomcat tomcat/
#chmod -R u+X tomcat/



#systemctl enable jws5-tomcat.service
#systemctl disable --now fapolicyd
#systemctl start jws5-tomcat.service





#echo "JAVA_OPTS=${JAVA_OPTS} =DXIPKI_BASE=${CATALINA_HOME/xipki}" >> /opt/tomcat/bin/setenv.sh
#cp -r /home/rmhcoadmin/xipki-ocsp/webapp /opt/tomcat
#cp -r /home/rmhcoadmin/xipki-ocsp/lib /opt/tomcat
#cp -r /home/rmhcoadmin/xipki-ocsp/xipki /opt/tomcat


#echo "org.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true" >> /opt/tomcat/conf/catalina.properties
