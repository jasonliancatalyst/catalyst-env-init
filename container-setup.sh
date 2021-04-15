#! /bin/bash

cd /siteroot

composer install

if [[ -d "/siteroot/blocks/navint/" ]]; then
    cd /siteroot/blocks/navint/ && composer install && cd /siteroot/
fi

php admin/tool/phpunit/cli/init.php

php admin/cli/install_database.php --adminpass=soMePass123_ --agree-license --adminemail=admin@dummy.org --fullname=AdminPerson --shortname=admin

export XDEBUG_CONFIG="remote_host=172.17.0.1 remote_port=9000"

export PHP_IDE_CONFIG="serverName=http://localhost"
