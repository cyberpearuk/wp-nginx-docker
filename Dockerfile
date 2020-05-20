
FROM ubuntu AS fetch-wp
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        libcurl4-openssl-dev \
    && apt-get purge -y git && apt-get -y autoremove
ARG WP_VERSION=5.4.1
# Install wordpress
RUN set -ex; \
        WP_CHECKSUM=$(curl --silent --raw "https://en-gb.wordpress.org/wordpress-${WP_VERSION}-en_GB.tar.gz.sha1"); \
	curl -s -o wordpress.tar.gz -fSL "https://en-gb.wordpress.org/wordpress-${WP_VERSION}-en_GB.tar.gz"; \
	echo "${WP_CHECKSUM} *wordpress.tar.gz" | sha1sum -c -; \
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
        rm /usr/src/wordpress/wp-config-sample.php 

FROM php:7.3-fpm AS production

# Setup environment for WordPress and Tools (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libjpeg-dev \
        libmagickwand-dev \
        libpng-dev \
        # Install msmtp
        msmtp \
        # Install unzip
        unzip \
        # Required for PECL zip
        libzip-dev \
        # Required for PDF Preview thumbnails
        ghostscript \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install \
		bcmath \
		exif \
		gd \
		mysqli \
		opcache \
                # Install PDO
                pdo pdo_mysql
RUN pecl install imagick-3.4.4  \
    && docker-php-ext-enable imagick \
    # Install PECL zip >= 1.14 for zip encryption
    && pecl install zip-1.18.2  \
    && docker-php-ext-enable zip    
RUN apt-get update && apt-get install -y --no-install-recommends \
        supervisor \
        nginx \
    && rm -rf /var/lib/apt/lists/*
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY default.conf /etc/nginx/sites-available/default

# Setup php.ini settings
COPY ini/*.ini /usr/local/etc/php/conf.d/

# Copy in WordPress
COPY --from=0 /usr/src/wordpress/ /var/www/html/

# Install tools
RUN curl -sS https://getcomposer.org/installer | php \
  && chmod +x composer.phar \
  && php composer.phar global require cyberpearuk/wp-db-tools \
  # Remove composer now, we shouldn't need it after this
  && rm composer.phar

ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Add extra WP config
COPY wordpress/*.php ./

# Copy scripts
COPY scripts/* /usr/local/bin/

# Setup file permissions
RUN mkdir /var/www/html/settings ; \
    mkdir /var/www/html/wp-content/uploads ; \
    echo "Deny from all" > /var/www/html/settings/.htaccess ; \
    chown -R www-data:www-data /var/www/html ; \
    find /var/www/html -type d -exec chmod 750 {} \; ; \
    find /var/www/html -type f -exec chmod 640 {} \;

# Define volumes for persistent data
VOLUME /var/www/html/wp-content
VOLUME /var/www/html/settings

RUN sed -i 's/;error_log = log\/php-fpm.log/error_log = \/dev\/stderr/' /usr/local/etc/php-fpm.conf

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

COPY conf.d/* /etc/nginx/conf.d/
COPY php-fpm.d/* /usr/local/etc/php-fpm.d/

FROM production AS development 

RUN apt-get update && apt-get install -y --no-install-recommends \
        nano \
    && rm -rf /var/lib/apt/lists/*

# Xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && touch /var/log/xdebug.log && chmod 777 /var/log/xdebug.log \
    # TODO: permissions don't work with new volumes
    && mkdir /var/log/xdebug-profiler && chmod 777 /var/log/xdebug-profiler

# XDebug Port
EXPOSE 9000

# Setup php.ini settings
COPY dev-ini/*.ini /usr/local/etc/php/conf.d/
