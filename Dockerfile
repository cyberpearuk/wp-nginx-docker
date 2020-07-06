ARG BASE_IMAGE=blackpeardigital/php-nginx

FROM ubuntu AS fetch-wp
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        libcurl4-openssl-dev \
    && apt-get purge -y git && apt-get -y autoremove
ARG WP_VERSION=5.4.2
# Install wordpress
RUN set -ex; \
        WP_CHECKSUM=$(curl --silent --raw "https://en-gb.wordpress.org/wordpress-${WP_VERSION}-en_GB.tar.gz.sha1"); \
	curl -s -o wordpress.tar.gz -fSL "https://en-gb.wordpress.org/wordpress-${WP_VERSION}-en_GB.tar.gz"; \
	echo "${WP_CHECKSUM} *wordpress.tar.gz" | sha1sum -c -; \
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
        rm /usr/src/wordpress/wp-config-sample.php 

FROM $BASE_IMAGE

RUN GD_FLAGS=$(bash -c "(echo ${PHP_VERSION} | grep -Eq  ^7\.4 ) && echo '--with-png=/usr --with-jpeg=/usr' || echo '--with-png-dir=/usr --with-jpeg-dir=/usr'")

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
    && GD_FLAGS=$(bash -c "(echo ${PHP_VERSION} | grep -Eq  ^7\.4 ) && echo '--with-png=/usr --with-jpeg=/usr' || echo '--with-png-dir=/usr --with-jpeg-dir=/usr'") \
        docker-php-ext-configure gd ${GD_FLAGS} \
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

COPY nginx/sites-available/* /etc/nginx/sites-available/

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

COPY conf.d/* /etc/nginx/conf.d/
COPY bin/* /usr/bin/
