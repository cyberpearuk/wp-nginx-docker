# WordPress Nginx Docker Image
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/cyberpearuk/wp-nginx-docker.svg)](https://cloud.docker.com/u/cyberpearuk/repository/docker/cyberpearuk/wp-nginx-docker)

Tailored docker image for running WordPress with PHP-FPM and Nginx

Comes with security steps built in.

## Environment Variables

### Mountable Environment Variables

This image supports the ability to load environment variables at startup from a predefined locations.

This is intended to allow the loading shared/common settings from the host machine by mounting an external .env file to the required path `/var/common/.env`.

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

With the official image, WordPress is actually installed on first run - i.e. it copies across WordPress if it's not in the installation directory already.

This image comes with WordPress included in the image itself. 
The WordPress installation in the image is therefore ephemeral as we are only setting 
up a volume for the wp-content directory, not the entire WordPress install.

This means that the image itself controls the WordPress version, this can make it easier to control 
exactly what is running and where (one of the main benefits of Docker!).

Note that the ephemeral installation is at odds with the WordPress approach of automatic updates, and currently the WordPress installation 
can be updated but will be lost on restart (unless the whole installation directory is mounted). 

### Dynamic Environment Variables

The official image only uses the environment variables on first run,  and therefore the environment variable values can't actually be changed.

The environment variables in this image are dynamically loaded and therefore continue to be referenced, i.e. if you change your database creds, all you need to do is 
update the environment variables and restart (in the official WP you'd have to change them inside the running container).

To achieve this **wp-config.php is also ephemeral** as it uses the environment variables directly from PHP. The installation specific content
such as the WordPress salts are put in a separate volume.

### Sendmail

As this container was originally created to help support sending emails it includes a bash script `test-sendmail <email-address>`
 which will send a test email both via PHP but also sendmail directly (over bash CLI).

```bash
docker exec -it <container> test-sendmail me@mail.com
```

## Maintainer

This repository is maintained by [Black Pear Digital](https://www.blackpeardigital.co.uk).
