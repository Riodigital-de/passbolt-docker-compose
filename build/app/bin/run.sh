#!/usr/bin/env bash

if [ ! -e /var/www/passbolt/index.php ]; then
    echo "Couldn't find any files for passbolt, downloading new files"
    mkdir -p /var/www/passbolt
    cd /var/www/passbolt
    curl -L https://github.com/passbolt/passbolt_api/archive/v1.3.0.tar.gz -o /home/www-data/passbolt.tar.gz
    echo "extracting..."
    tar -xzf /home/www-data/passbolt.tar.gz -C /var/www/passbolt --strip-components=1
    chown -R www-data /var/www
    
    cp -a /var/www/passbolt/app/Config/app.php.default /var/www/passbolt/app/Config/app.php
    cp -a /var/www/passbolt/app/Config/core.php.default /var/www/passbolt/app/Config/core.php
    # cp -a /var/www/passbolt/app/webroot/js/app/config/config.json.default /var/www/passbolt/app/webroot/js/app/config/config.json
    chown -R www-data /var/www

    # gpg
    GPG_SERVER_KEY_FINGERPRINT=`gpg -n --with-fingerprint /home/www-data/gpg_server_key_public.key | awk -v FS="=" '/Key fingerprint =/{print $2}' | sed 's/[ ]*//g'`
    /var/www/passbolt/app/Console/cake passbolt app_config write GPG.serverKey.fingerprint $GPG_SERVER_KEY_FINGERPRINT
    /var/www/passbolt/app/Console/cake passbolt app_config write GPG.serverKey.public /home/www-data/gpg_server_key_public.key
    /var/www/passbolt/app/Console/cake passbolt app_config write GPG.serverKey.private /home/www-data/gpg_server_key_private.key

    # cake alwys writes strings...
    #/var/www/passbolt/app/Console/cake passbolt app_config write App.ssl.force false
    sed -i  "/'force' => true,/c\'force' => false," /var/www/passbolt/app/Config/app.php

    chown www-data:www-data /home/www-data/gpg_server_key_public.key
    chown www-data:www-data /home/www-data/gpg_server_key_private.key
    chown -R www-data /var/www

    # overwrite the core configuration
    /var/www/passbolt/app/Console/cake passbolt core_config gen-cipher-seed
    /var/www/passbolt/app/Console/cake passbolt core_config gen-security-salt
    /var/www/passbolt/app/Console/cake passbolt core_config write App.fullBaseUrl http://${HOST_NAME}
    chown -R www-data /var/www
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
    
    # email config
    sed -i "/\s*public \$default = array(/,/\s*);/s/'transport' => 'Smtp',/'transport' => '$APP_EMAIL_TRANSPORT',/" /var/www/passbolt/app/Config/email.php
    sed -i "/\s*public \$default = array(/,/\s*);/s/'from' => array('contact@passbolt.com' => 'Passbolt'),/'from' => array('$APP_EMAIL_FROM_ADDRESS' => '$APP_EMAIL_FROM_NAME'),/" /var/www/passbolt/app/Config/email.php
    sed -i "/\s*public \$default = array(/,/\s*);/s/'host' => 'smtp.mandrillapp.com',/'host' => '$APP_EMAIL_HOST',/" /var/www/passbolt/app/Config/email.php
    sed -i "/\s*public \$default = array(/,/\s*);/s/'port' => 587,/'port' => $APP_EMAIL_PORT,/" /var/www/passbolt/app/Config/email.php
    sed -i "/\s*public \$default = array(/,/\s*);/s/'timeout' => 30,/'timeout' => $APP_EMAIL_TIMEOUT,/" /var/www/passbolt/app/Config/email.php
    sed -i "/\s*public \$default = array(/,/\s*);/s/'username' => '',/'username' => '$APP_EMAIL_USERNAME',/" /var/www/passbolt/app/Config/email.php
    sed -i "/\s*public \$default = array(/,/\s*);/s/'password' => '',/'password' => '$APP_EMAIL_PASSWORD',/" /var/www/passbolt/app/Config/email.php
    # the interaction between bash an sed is really weird, i had to triple escape the first tab
    sed -i "/\s*'password' => '$APP_EMAIL_PASSWORD',/a \\\t\t'tls' => true," /var/www/passbolt/app/Config/email.php

    # depending on the users system, the db container can take some time to start up, 10 seconds should give it enough time to be ready to handle connections
    echo "Waiting 10 seconds for mysql container to finish initializing"
    sleep 10
    chown -R www-data /var/www
    echo "Installing"
    su -s /bin/bash -c "/var/www/passbolt/app/Console/cake install --no-admin" www-data
    echo "Registering admin with credentials - email: ${ADMIN_EMAIL} - firstname: ${ADMIN_FIRSTNAME} - lastname: ${ADMIN_LASTNAME}"
    echo "########################################################################################################################"
    echo "########################################################################################################################"
    su -s /bin/bash -c "/var/www/passbolt/app/Console/cake passbolt register_user -u  ${ADMIN_EMAIL} -f ${ADMIN_FIRSTNAME} -l ${ADMIN_LASTNAME} -r admin" www-data
    echo "########################################################################################################################"
    echo "########################################################################################################################"
    echo "We are all set. Have fun with Passbolt !"

fi
echo "Starting supervisor"
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf