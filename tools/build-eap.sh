#!/bin/bash -e



###########################
# Build/download eap #
###########################

echo "EAP from [download]: $EAP_DIST"

cd /opt/jboss/

curl -O $EAP_DIST
curl -O $EAP_PATCH


unzip jboss-eap-$EAP_VERSION.zip
mv jboss-eap-7.2 eap


#####################
# Create DB modules #
#####################

mkdir -p /opt/jboss/eap/modules/system/layers/base/com/mysql/jdbc/main
cd /opt/jboss/eap/modules/system/layers/base/com/mysql/jdbc/main
mv /opt/jboss/drivers/mysql-connector-java-$JDBC_MYSQL_VERSION.jar .
cp /opt/jboss/tools/databases/mysql/module.xml .

mkdir -p /opt/jboss/eap/modules/system/layers/base/com/oracle/jdbc/main
cd /opt/jboss/eap/modules/system/layers/base/com/oracle/jdbc/main
mv /opt/jboss/drivers/ojdbc8.jar ./
cp /opt/jboss/tools/databases/oracle/module.xml .


######################
# Configure EAP #
######################

cd /opt/jboss/eap

# To apply this update  
bin/jboss-cli.sh "patch apply /opt/jboss/jboss-eap-$EAP_PATCH_VERSION-patch.zip"

rm -f /opt/jboss/jboss-*.zip

# ADD password vault
mkdir /opt/jboss/eap/vault
keytool -genseckey -alias vault -storetype jceks -keyalg AES -keysize 128 -storepass vault-xiugaiwo -keypass vault-xiugaiwo -validity 730 -keystore /opt/jboss/eap/vault/vault.keystore
/opt/jboss/eap/bin/vault.sh -k /opt/jboss/eap/vault/vault.keystore  -p vault-xiugaiwo --alias vault -b vb -a password -x $DB_PASSWORD --enc-dir /opt/jboss/eap/vault/ --iteration 120 --salt qianhai1

bin/jboss-cli.sh --file=/opt/jboss/tools/cli/standalone-configuration.cli
rm -rf /opt/jboss/eap/standalone/configuration/standalone_xml_history


###################
# Set permissions #
###################

chown -R jboss:0 /opt/jboss/eap
chmod -R g+rw /opt/jboss/eap
