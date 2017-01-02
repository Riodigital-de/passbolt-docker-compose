# passbolt docker-compose stack #

[Passbolt](https://www.passbolt.com "Passbolt Homepage") is a web based password manager for teams build around [gpg](https://www.gnupg.org/ "GnuPG Homepage"). This repository aims to provide a basis to use passbolt in production via docker and docker-compose.

## Requirements ##

* docker >= 1.10
* docker-compose >= 1.8
* for LetsEncrypt: A domain pointing to the public IP address of the server intended to run the docker-compose stack for passbolt
* a server publicly reachable on ports 80 and 443

## How to use / Setup ##

1. Clone this repository
    ```bash
    git clone https://github.com/Riodigital-de/passbolt-docker-compose.git /path/to/where/youWant/theFilesToSit
    ```

2. Make sure you have docker and docker-compose up and running

3. Open the .env file in the projects root directory with your favored editorand change the values to your needs
    Have a look at [the section on the contens of .env](#contents-of-.env) to see what every entry does

4. Unless you already have a set of gpg keys you want to use, generate a key pair. From the root directory of the project run
    ```bash
    sh .\generate-keys.sh
    ```
    This will read the variables you edited in the previous step and generate a gpg key pair in a privileged docker container. If successful the keys will be placed in the .\build\app\keys directory. You might want to backup the files in that directory.
    
    Alternatively, if you already have a key pair you want to use for your passbolt instance, you can place they keypair and ASCII armored exported keys in .\build\app\keys. The files should be named the follwoing way:
    * **secring.gpg**: the secret gpg keyring file
    * **pubring.gpg**: the public gpg keyring file
    * **gpg_server_key_private.key**: the ASCII armored exported private key
    * **gpg_server_key_public.key**: the ASCII armored exported public key

5. Build the images for the compose stack
    ```bash
    docker-compose build
    ```
6. Make sure the DNS records for the domain you want your passbolt instace to be reachable by are setup properly and point to the public IP of the machine hosting the docker-compose stack

7. Start the (nginx-reverse-)proxy container in interactive mode while overriding the default command to bash and mapping port 80 and 443 explicitly:
    ```bash
    docker-compose run -ti -p 80:80 -p 443:443 proxy bash
    ```
    Depending on the hardware specs and available bandwidth of your machine, the startup may take a couple of minutes the first time. The proxy container depends on the app container, which depends on the database container, so these two are started first. The app container will download the passbolt sources during its first run, the database container will initialize the database for passbolt. Just give it a minute and go get another cup of coffee ;)

    During its first run, the app container will also setup the admin user for passbolt. You should see a link to finalize the setup of the admins account in the console output. If you setup the variables for your email server correctly, the admin user will also recieve an email containing the same link.

8. **From inside the proxy container**, perform a dry run of the included letsencrypt helper scripts
    ```bash
    sh \dry-run.sh
    ```

9. If everything checks out, actually obtain the letsencrypt certificates:
    ```bash
    sh \get-cert.sh
    ```

10. Exit the container
    ```bash
    exit
    ```

11. Identify the name of the run instance of the proxy container you just exited
    ```bash
    docker-compose ps
    ```
    The name should be somehting like passbolt_proxy_run_1 , where *passbolt* is equal to your current directory name.

12. Stop the proxy container run instance and remove it
    ```bash
    docker stop name_of_the_run_instance && docker rm name_of_the_run_instance 
    ```

13. Start the rest of the docker-compose stack
    ```bash
    docker-compose up
    ```

## Contents of .env ##
### gpg ###
* **gpg_name**: the name used for generating the gpg key pair
* **gpg_comment**: optional comment used for generating the gpg key pair
* **gpg_email**: email address used for generating the gpg key pair
* **gpg_key_type**: the key type generated, unless you know what you are doing, leave it at RSA
* **gpg_key_length**: default key length is 2048, paranoid users may choose longer keys
* **gpg_expire_date**: Time in days until the generated key pair expires, 0 means the key pair will never expire
### app ###
* **admin_email**: The email address for admin of this passbolt instance. An account for this address will added during the first run of the app container. This should be a valid email address, otherwise you wont be able to log in and add other users
* **admin_firstname**: The admins first name
* **admin_lastname**: The admins last name
* **app_email_transport**: The transport protocol used to communicate with the email server. Usually 'Smtp'
* **app_email_from_address**: The address from which the system sends emails
* **app_email_from_name**: The name under which the system sends emails
* **app_email_host**: The hostname of the email server
* **app_email_port**: The TCP port the email server listens to
* **app_email_timeout**: The time in seconds before connection attempts to the email server are timed out.
* **app_email_username**: The user / login name used to login to the email server
* **app_email_password**: The password for the above given username
* **app_email_use_tls**: Using TLS is strongly reccomended, set it to true if your email server supports TLS, false if otherwise.
* **app_dockerfile**: Tells docker-compose which dockerfile to use when building the app container. The default is 'debian.Dockerfile' which is currently the only available option. We might add different Dockerfiles, on for alpine for instance, in the future.
* **memory_limit**: The memory limit for the php interpreter. The default is '300M', which should be more then enough for most instances
* **post_maxsize**: The maximum allowed sizes of each POST request. Default is 10M
* **upload_max_filesize**: The maximum allwoed size for files attached to PUT or POST requests. Default is 10M
* **date_timezone**: The date / timezone used by the php interpreter. Default is Europe/Berlin
* **log_error**: Wether or not to log php errors to the default docker log / console output. Default is true
* **log_access**: Wether or not to log all php access requests to the default docker log / console output. Default is false

### db ###
* **mysql_root_password**: The mysql root users password
* **mysql_database**: The name of the database for passbolt. The default is 'passbolt'
* **mysql_user**: The name of the mysql user for the passbolt database. The default is 'passbolt'
* **mysql_password**: The password for the passbolt mysql user

### proxy ###
* **proxy_domain**: the domain under which your passbolt instance should be reachable, e.g. your.passbolt-domain.com. Please make sure to update the DNS records for this domain to point to the machine you want to run passbolt on, else the letsencrypt will fail to obtain the ssl certificates.
* **proxy_admin_email**: The email address for the representative of the domain statet above, used for obtaining the ssl certificates.