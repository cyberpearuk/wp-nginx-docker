# syntax=docker/dockerfile:1

###############################################################################
#                            Global Build Args                                #
#  - BASE_IMAGE: your custom PHP‐NGINX image, bumped to PHP 8.3               #
###############################################################################
ARG BASE_IMAGE=blackpeardigital/php-nginx:8.3

###############################################################################
# Stage 0: Fetch WordPress                                                    #
###############################################################################
FROM ubuntu AS fetch-wp

ARG WP_VERSION=6.8.2

RUN set -eux; \
    DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y --no-install-recommends \
         curl \
         ca-certificates \
         libcurl4-openssl-dev \
    && apt-get purge -y git \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*; \
    \
    WP_CHECKSUM="$(curl -fsSL https://en-gb.wordpress.org/wordpress-${WP_VERSION}-en_GB.tar.gz.sha1)"; \
    curl -fsSL -o wordpress.tar.gz https://en-gb.wordpress.org/wordpress-${WP_VERSION}-en_GB.tar.gz; \
    echo "${WP_CHECKSUM} *wordpress.tar.gz" | sha1sum -c -; \
    tar -xzf wordpress.tar.gz -C /usr/src/; \
    rm wordpress.tar.gz; \
    rm /usr/src/wordpress/wp-config-sample.php

###############################################################################
# Stage 1: Application                                                         #
###############################################################################
FROM ${BASE_IMAGE} AS app

# 1) Install system libs & PHP extension prerequisites
RUN set -eux; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
         libjpeg-dev \
         libpng-dev \
         libzip-dev \
         libmagickwand-dev \
         pkg-config \
         autoconf \
         gcc \
         make \
         msmtp \
         unzip \
         ghostscript \
    && rm -rf /var/lib/apt/lists/*

# 2) Configure & install GD and ZIP
#    GD needs explicit flags; ZIP is built-in against libzip-dev
RUN set -eux; \
    docker-php-ext-configure gd \
        --with-freetype=/usr \
        --with-jpeg=/usr; \
    docker-php-ext-install \
        gd \
        zip

# 3) Install other core PHP extensions
RUN set -eux; \
    docker-php-ext-install \
        bcmath \
        exif \
        mysqli \
        opcache \
        pdo \
        pdo_mysql

# 4) PECL extension: Imagick
RUN set -eux; \
    pecl install imagick \
    && docker-php-ext-enable imagick \
    && sed -i \
         -e 's$<policy domain="coder" rights="none" pattern="PDF" />$<policy domain="coder" rights="read | write" pattern="PDF" />$g' \
         "$(ls /etc/ImageMagick-*/policy.xml | head -n1)"

# 5) Nginx vhosts & PHP ini overrides
COPY nginx/sites-available/ /etc/nginx/sites-available/
COPY ini/*.ini        /usr/local/etc/php/conf.d/

# 6) Copy in WordPress from fetch-wp
COPY --from=fetch-wp /usr/src/wordpress/ /var/www/html/

# 7) Install Composer + WP-DB-Tools, then remove installer
RUN set -eux; \
    curl -sS https://getcomposer.org/installer | php \
    && chmod +x composer.phar \
    && php composer.phar global require cyberpearuk/wp-db-tools \
    && rm composer.phar

ENV PATH="/root/.composer/vendor/bin:${PATH}"

# 8) Custom WP config & file permissions
COPY wordpress/*.php /var/www/html/

RUN set -eux; \
    mkdir -p /var/www/html/settings /var/www/html/wp-content/uploads; \
    echo "Deny from all" > /var/www/html/settings/.htaccess; \
    chown -R www-data:www-data /var/www/html; \
    find /var/www/html -type d -exec chmod 750 {} \;; \
    find /var/www/html -type f -exec chmod 640 {} \;;

# 9) Persistent-volumes for uploads & settings
VOLUME /var/www/html/wp-content
VOLUME /var/www/html/settings

# 10) Additional Nginx config snippets & helper scripts
COPY conf.d/ /etc/nginx/conf.d/
COPY usr/bin/ /usr/bin/
