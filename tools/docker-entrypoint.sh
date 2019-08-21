#!/bin/bash

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}
 

########################
# JGroups bind options #
########################

#if [ -z "$BIND" ]; then
#    BIND=$(hostname --all-ip-addresses)
#fi
#if [ -z "$BIND_OPTS" ]; then
#    for BIND_IP in $BIND
#    do
#        BIND_OPTS+=" -Djboss.bind.address=$BIND_IP -Djboss.bind.address.private=$BIND_IP "
#    done
#fi
#SYS_PROPS+=" $BIND_OPTS"

#################
# Configuration #
#################

# If the server configuration parameter is not present, append the standalone profile.
if echo "$@" | egrep -v -- '-c |-c=|--server-config |--server-config='; then
    SYS_PROPS+=" -c=standalone.xml"
fi

############
# DB setup #
############

file_env 'DB_USER'
file_env 'DB_PASSWORD'

# Lower case DB_VENDOR
DB_VENDOR=`echo $DB_VENDOR | tr A-Z a-z`

# Detect DB vendor from default host names
if [ "$DB_VENDOR" == "" ]; then
	if (getent hosts mysql &>/dev/null); then
        export DB_VENDOR="mysql"
    elif (getent hosts oracle &>/dev/null); then
        export DB_VENDOR="oracle"
    fi
fi

# Detect DB vendor from legacy `*_ADDR` environment variables
if [ "$DB_VENDOR" == "" ]; then
    if (printenv | grep '^MYSQL_ADDR=' &>/dev/null); then
        export DB_VENDOR="mysql"
    elif (printenv | grep '^ORACLE_ADDR=' &>/dev/null); then
        export DB_VENDOR="oracle"
    fi
fi

# Default to MYSQL if DB type not detected
if [ "$DB_VENDOR" == "" ]; then
    export DB_VENDOR="mysql"
fi

# Set DB name
case "$DB_VENDOR" in
    mysql)
        DB_NAME="MySQL";;
    oracle)
        DB_NAME="Oracle";;
    *)
        echo "Unknown DB vendor $DB_VENDOR"
        exit 1
esac

# Append '?' in the beggining of the string if JDBC_PARAMS value isn't empty
export JDBC_PARAMS=$(echo ${JDBC_PARAMS} | sed '/^$/! s/^/?/')

# Convert deprecated DB specific variables
function set_legacy_vars() {
  local suffixes=(ADDR DATABASE USER PASSWORD PORT)
  for suffix in "${suffixes[@]}"; do
    local varname="$1_$suffix"
    if [ ${!varname} ]; then
      echo WARNING: $varname variable name is DEPRECATED replace with DB_$suffix
      export DB_$suffix=${!varname}
    fi
  done
}
set_legacy_vars `echo $DB_VENDOR | tr a-z A-Z`

# if the DB_VENDOR is postgres then append port to the DB_ADDR
function append_port_db_addr() {
  local db_host_regex='^[a-zA-Z0-9]([a-zA-Z0-9]|-|.)*:[0-9]{4,5}$'
  IFS=',' read -ra addresses <<< "$DB_ADDR"
  DB_ADDR=""
  for i in "${addresses[@]}"; do
    if [[ $i =~ $db_host_regex ]]; then
        DB_ADDR+=$i;
     else
        DB_ADDR+="${i}:${DB_PORT}";
     fi
        DB_ADDR+=","
  done
  DB_ADDR=$(echo $DB_ADDR | sed 's/.$//') # remove the last comma
}

# Configure DB

echo "========================================================================="
echo ""
echo "  Using $DB_NAME database"
echo ""
echo "========================================================================="
echo ""

if [ "$DB_VENDOR" != "h2" ]; then
    /bin/sh /opt/jboss/tools/databases/change-database.sh $DB_VENDOR
fi


/opt/jboss/tools/autorun.sh

##################
# Start APP #
##################


exec /opt/jboss/eap/bin/standalone.sh $SYS_PROPS $@
exit $?
