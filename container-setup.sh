#! /bin/bash

# Composer install
cd /siteroot && composer install

# This seems to be navitas only blocks/navint, if this exists, need to run composer install inside it.
if [[ -d "/siteroot/blocks/navint/" ]]; then
    cd /siteroot/blocks/navint/ && composer install && cd /siteroot/
fi

# Init phpunit.
/usr/bin/php admin/tool/phpunit/cli/init.php

# Run commandline DB Install.
/usr/bin/php admin/cli/install_database.php --adminpass=soMePass123_ --agree-license --adminemail=admin@dummy.org --fullname=AdminPerson --shortname=admin

# Export variable for XDEBUG.
export XDEBUG_CONFIG="remote_host=172.17.0.1 remote_port=9000"
export PHP_IDE_CONFIG="serverName=http://localhost"
