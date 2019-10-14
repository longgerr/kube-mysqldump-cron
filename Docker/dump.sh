#!/bin/sh

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		mysql_error "Both $var and $fileVar are set (but are exclusive)"
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

file_env 'DB_PASS'

DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}
DB_HOST=${DB_HOST:-${MYSQL_ENV_DB_HOST}}
ALL_DATABASES=${ALL_DATABASES}
IGNORE_DATABASE=${IGNORE_DATABASE}


if [[ ${DB_USER} == "" ]]; then
	echo "Missing DB_USER env variable"
	exit 1
fi
if [[ ${DB_PASS} == "" ]]; then
	echo "Missing DB_PASS env variable"
	exit 1
fi
if [[ ${DB_HOST} == "" ]]; then
	echo "Missing DB_HOST env variable"
	exit 1
fi

if [[ ${ALL_DATABASES} == "" ]]; then
	if [[ ${DB_NAME} == "" ]]; then
		echo "Missing DB_NAME env variable"
		exit 1
	fi
	mysqldump --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" "$@" "${DB_NAME}" > /mysqldump/"${DB_NAME}"_$(date +%Y%m%d-%H%M%S).sql
else
	databases=`mysql --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] && [[ "$db" != "$IGNORE_DATABASE" ]]; then
        echo "Dumping database: $db"
        mysqldump --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" --databases $db > /mysqldump/"$db"_$(date +%Y%m%d-%H%M%S).sql
    fi
done
fi
