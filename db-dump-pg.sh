#! /bin/bash

# Enable below if there's error message what does "bash:no job control in this shell"
# https://stackoverflow.com/questions/11821378/what-does-bashno-job-control-in-this-shell-mean
# set -m

dbcont="$(docker-compose ps -q db)"

fileName="dump_`date +%d-%m-%Y\"_\"%H_%M_%S`.sql.bz2"

echo "Export DB file to ./${fileName}"

echo "127.0.0.1:5432:moodle:moodle_user:password" > .pgpass

docker exec -t -e PGPASSWORD=password ${dbcont} pg_dump --username=moodle_user --dbname=moodle | lbzip2 -n 2 -9 > ${fileName}
