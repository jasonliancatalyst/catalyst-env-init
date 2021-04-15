#! /bin/bash

# Get the container ID from current directory's docker-compose instance.
webcont="$(docker-compose ps -q moodle)"

# If container ID does not exist, exit.
if [[ -z $webcont ]]; then
    echo "Docker compose container not found... "
    echo "Run this command when inside the directory that has docker-compose.xml file... "
    exit
fi

# Run php unit with extra paramters, or otherwise run the complete unit test.
if [[ ! -z $1 ]]; then
    echo "Running phpunit with additional paramters..."
    echo "docker exec -it $webcont /siteroot/vendor/bin/phpunit ${1} ${2}> $(pwd)/phpunit_${1}_`date +%d-%m-%Y_%H_%M_%S`.log"
    docker exec -it $webcont bash -c "vendor/bin/phpunit \"${1}\" ${2}" > $(pwd)/phpunit_${1}_`date +%d-%m-%Y_%H_%M_%S`.log
    exit
else
    echo "Command Args not found, running full phpunit test ..."
    # docker exec -i resrel bash -c \"cd /siteroot && vendor/bin/phpunit\" > ~/Documents/monash/resrel/phpunit.log
    echo "docker exec -it $webcont vendor/bin/phpunit > $(pwd)/phpunit_`date +%d-%m-%Y_%H_%M_%S`.log"
    docker exec -it $webcont vendor/bin/phpunit > $(pwd)/phpunit_`date +%d-%m-%Y_%H_%M_%S`.log
    exit
fi
