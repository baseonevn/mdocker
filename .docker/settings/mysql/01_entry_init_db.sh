#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Execute sql script, passed via stdin
# usage: docker_process_sql [--dont-use-mysql-root-password] [mysql-cli-args]
#    ie: docker_process_sql --database=mydb <<<'INSERT ...'
#    ie: docker_process_sql --dont-use-mysql-root-password --database=mydb <my-file.sql
docker_process_sql_multi() {
	passfileArgs=()
	if [ '--dont-use-mysql-root-password' = "$1" ]; then
		passfileArgs+=( "$1" )
		shift
	fi
	# # args sent in can override this db, since they will be later in the command
	# if [ -n "$MYSQL_DATABASE" ]; then
	# 	set -- --database="$MYSQL_DATABASE" "$@"
	# fi

	mysql --defaults-extra-file=<( _mysql_passfile "${passfileArgs[@]}") --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" --comments "$@"
}

# usage: process_init_file FILENAME MYSQLCOMMAND...
#    ie: process_init_file foo.sh mysql -uroot
# (process a single initializer file, based on its extension. we define this
# function here, so that initializer scripts (*.sh) can use the same logic,
# potentially recursively, or override the logic used in subsequent calls)
process_init_file_multi() {
	local f="$1"; shift
	filename="${f##*/}"
	case "$f" in
		*.sql) 
			local database="${filename%.sql}"; 
			local mysql=( "docker_process_sql_multi" --database="$database" ); 
			mysql_note "Creating database ${MYSQL_DATABASE}"
			docker_process_sql --database=mysql <<<"CREATE DATABASE IF NOT EXISTS \`$database\` ;"
			mysql_note "Giving user ${MYSQL_USER} access to schema ${MYSQL_DATABASE}"
			docker_process_sql --database=mysql <<<"GRANT ALL ON \`${database//_/\\_}\`.* TO '$MYSQL_USER'@'%' ;"
			echo "$0: running $f import database: $database"; "${mysql[@]}" < "$f"; 
			echo ;;
		*.sql.gz)
			local database="${filename%.sql.gz}"; 
			local mysql=( "docker_process_sql_multi" --database="$database" ); 
			mysql_note "Creating database ${MYSQL_DATABASE}"
			docker_process_sql --database=mysql <<<"CREATE DATABASE IF NOT EXISTS \`$database\` ;"
			mysql_note "Giving user ${MYSQL_USER} access to schema ${MYSQL_DATABASE}"
			docker_process_sql --database=mysql <<<"GRANT ALL ON \`${database//_/\\_}\`.* TO '$MYSQL_USER'@'%' ;"
			echo "$0: running $f import database: $database"; gunzip -c "$f" | "${mysql[@]}";
			echo ;;
		*)        
			echo "$0: ignoring $f" ;;
	esac
	echo
}

ls /docker-entrypoint-initdb.d/ > /dev/null
for f in /docker-entrypoint-initdb-multi.d/*; do
	process_init_file_multi "$f"
done