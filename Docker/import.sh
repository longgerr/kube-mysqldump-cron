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
DB_FILE=${DB_FILE}
DB_HOST=${DB_HOST:-${MYSQL_ENV_DB_HOST}}
ALL_DATABASES=${ALL_DATABASES}

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
	if [[ ${DB_FILE} == "" ]]; then
		echo "Missing DB_FILE env variable"
		exit 1
	fi
	mysql --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" "$@" "${DB_NAME}" < /mysqldump/"${DB_FILE}"
else
	cd /mysqldump
	databases=`for f in *.sql; do
    	printf '%s\n' "${f%.sql}"
	done`
for db in $databases; do

	IFS='_' # hyphen (-) is set as delimiter
	read -ra ADDR <<< "$db" # str is read into an array as tokens separated by IFS
	extract_name="${ADDR[0]}"
	IFS=' ' # reset to default value after usage

	if [[ "$db" != "information_schema.sql" ]] && [[ "$db" != "performance_schema.sql" ]] && [[ "$db" != "mysql.sql" ]] && [[ "$db" != _* ]]; then
		echo "Importing database: $extract_name"
		mysql --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" "$@" "$extract_name" < /mysqldump/$db.sql
	fi
done
fi
