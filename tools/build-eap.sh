#!/bin/bash -e



###########################
# Build/download eap #
###########################

echo "EAP from [download]: $EAP_DIST"

cd /opt/jboss/

curl -O http://192.168.252.128/repos/jboss-eap-7.2.0.zip
curl -O http://192.168.252.128/repos/jboss-eap-7.2.3-patch.zip


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
bin/jboss-cli.sh "patch apply /opt/jboss/jboss-eap-7.2.3-patch.zip"


bin/jboss-cli.sh --file=/opt/jboss/tools/cli/standalone-configuration.cli
rm -rf /opt/jboss/eap/standalone/configuration/standalone_xml_history

bin/jboss-cli.sh --file=/opt/jboss/tools/cli/standalone-ha-configuration.cli
rm -rf /opt/jboss/eap/standalone/configuration/standalone_xml_history

###################
# Set permissions #
###################

chown -R jboss:0 /opt/jboss/eap
chmod -R g+rw /opt/jboss/eap
