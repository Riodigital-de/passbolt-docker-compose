#!/usr/bin/env bash

if [ ! -e /var/www/passbolt/index.php ]; then
    echo "Couldn't find any files for passbolt, downloading new files"
    mkdir -p /var/www/passbolt
    cd /var/www/passbolt
    git clone https://github.com/passbolt/passbolt.git .
    chown -R www-data /var/www

    cp -a /var/www/passbolt/app/Config/app.php.default /var/www/passbolt/app/Config/app.php
    cp -a /var/www/passbolt/app/Config/core.php.default /var/www/passbolt/app/Config/core.php
    # cp -a /var/www/passbolt/app/webroot/js/app/config/config.json.default /var/www/passbolt/app/webroot/js/app/config/config.json

    # gpg
    GPG_SERVER_KEY_FINGERPRINT=`gpg -n --with-fingerprint /home/www-data/gpg_server_key_public.key | awk -v FS="=" '/Key fingerprint =/{print $2}' | sed 's/[ ]*//g'`
    /var/www/passbolt/app/Console/cake passbolt app_config write GPG.serverKey.fingerprint $GPG_SERVER_KEY_FINGERPRINT
    /var/www/passbolt/app/Console/cake passbolt app_config write GPG.serverKey.public /home/www-data/gpg_server_key_public.key
    /var/www/passbolt/app/Console/cake passbolt app_config write GPG.serverKey.private /home/www-data/gpg_server_key_private.key
    chown www-data:www-data /home/www-data/gpg_server_key_public.key
    chown www-data:www-data /home/www-data/gpg_server_key_private.key

    # overwrite the core configuration
    /var/www/passbolt/app/Console/cake passbolt core_config gen-cipher-seed
    /var/www/passbolt/app/Console/cake passbolt core_config gen-security-salt
    /var/www/passbolt/app/Console/cake passbolt core_config write App.fullBaseUrl http://${HOST_NAME}

    # overwrite the database configuration
    # @TODO based on the cake task DbConfigTask implement a task to manipulate the dabase configuration
    #/var/www/passbolt/app/Console/cake passbolt db_config ${MYSQL_HOST} ${MYSQL_USERNAME} ${MYSQL_PASSWORD} ${MYSQL_DATABASE}

    DATABASE_CONF=/var/www/passbolt/app/Config/database.php
    # Set configuration in file
    cat > $DATABASE_CONF << EOL
        <?php
        class DATABASE_CONFIG {
            public \$default = array(
                'datasource' => 'Database/Mysql',
                'persistent' => false,
                'host' => '${MYSQL_HOST}',
                'login' => '${MYSQL_USERNAME}',
                'password' => '${MYSQL_PASSWORD}',
                'database' => '${MYSQL_DATABASE}',
                'prefix' => '',
                'encoding' => 'utf8',
            );
        };
EOL
    echo "Installing"
    su -s /bin/bash -c "/var/www/passbolt/app/Console/cake install --admin-username ${ADMIN_USERNAME} --admin-first-name=${ADMIN_FIRST_NAME} --admin-last-name=${ADMIN_LAST_NAME}" www-data
    echo "We are all set. Have fun with Passbolt !"

fi
echo "Starting supervisor"
/usr/bin/supervisord