#! /bin/bash

echo "$1"

if [[ ! -z $1 ]]; then
    echo "Importing $1 ..."
else
    echo "You have to specify file path db-import-pg.sh <file_path> ..."
    exit
fi

echo "The file to import: ${1}"

dbcont="$(docker-compose ps -q db)" && \
lbzip2 -dc -n 2 ${1} > ${1}.sql && \
docker exec -i -e PGPASSWORD=password ${dbcont} psql -U moodle_user -d moodle < ${1}.sql
rm ${1}.sql
