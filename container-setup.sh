#! /bin/bash

echo "Container setup initiated..."

# Composer install
echo "cd /siteroot && composer install"
cd /siteroot && composer install

# This seems to be navitas only blocks/navint, if this exists, need to run composer install inside it.
if [[ -d "/siteroot/blocks/navint/" ]]; then
    echo "Found blocks/navint"
    cd /siteroot/blocks/navint
    composer install
    cd /siteroot
fi

# Init phpunit.
echo "Setting up phpunit: /usr/bin/php admin/tool/phpunit/cli/init.php"
/usr/bin/php admin/tool/phpunit/cli/init.php

# Run commandline DB Install.
echo "Setting up db install..."
/usr/bin/php admin/cli/install_database.php --adminpass=soMePass123_ --agree-license --adminemail=admin@dummy.org --fullname=AdminPerson --shortname=admin
