#!/bin/bash -e

DB_VENDOR=$1

cd /opt/jboss/eap

bin/jboss-cli.sh --file=/opt/jboss/tools/cli/databases/$DB_VENDOR/standalone-configuration.cli
rm -rf /opt/jboss/eap/standalone/configuration/standalone_xml_history

bin/jboss-cli.sh --file=/opt/jboss/tools/cli/databases/$DB_VENDOR/standalone-ha-configuration.cli
rm -rf standalone/configuration/standalone_xml_history/current/*