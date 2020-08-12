# WordPress Nginx Docker Image

Tailored docker image for running WordPress with PHP-FPM and Nginx

Comes with security steps built in.

## Environment Variables

### Mountable Environment Variables
This image supports the ability to load environment variables at startup from a predefined locations.

This allows loading shared/common settings from the host machine by mounting an external .env file to the required path `/var/common/.env`.

These are loaded in the entrypoint script at machine startup.

### Email Settings
- EMAIL_SMTP_HOST - Remote SMTP Server host name
- EMAIL_SMTP_PORT - Remote SMTP Port
- EMAIL_AUTH_USER - Remote SMTP Username
- EMAIL_AUTH_PASS - Remote SMTP User Password
- EMAIL_HOST - The host of the email

For my purposes TLS is on and not configurable out the box.

### Web Server
- VIRTUAL_HOST - The server host name (used for ServerName)

## Notes

### Ephemeral WordPress Installation

With the official image, WordPress is actually installed on first run
- i.e. it copies across WordPress if it's not in the installation directory already.

This image comes with WordPress installed already. The WordPress installation is therefore ephemeral as we are only setting 
up a volume for the wp-content directory, not the entire WordPress install. 
This means that the image itself controls the WordPress version, this can make it easier to control 
exactly what is running and where (one of the main benefits of Docker!).

### Dynamic Environment Variables

The official image only uses the environment variables the first time
 (therefore the environment variables become meaningless after the first run).

The environment variables in this image continue to be referenced, i.e. if you change your database creds, all you need to do is 
update the environment variables and restart (in the official WP you'd have to change them inside the running container).

To achieve this wp-config.php is also ephemeral as it uses the environment variables directly from PHP. The installation specific content
such as the WordPress salts are put in a separate volume.

### Sendmail

As this container was originally created to help support sending emails it includes a bash script `test-sendmail <email-address>`
 which will send a test email both via PHP but also sendmail directly (over bash CLI).

```bash
docker exec -it <container> test-sendmail me@mail.com
```

## Maintainer

This repository is maintained by https://www.blackpeardigital.co.uk.
