# Set master image
FROM php:7.2-fpm-alpine

# Set working directory
WORKDIR /var/www/html

# Install Additional dependencies
RUN apk update && apk add --no-cache \
    build-base shadow supervisor \
    php7-common \
    php7-pdo \
    php7-pdo_mysql \
    php7-mysqli \
    php7-mcrypt \
    php7-mbstring \
    php7-xml \
    php7-openssl \
    php7-json \
    php7-phar \
    php7-zip \
    php7-gd \
    php7-dom \
    php7-session \
    php7-zlib \
    busybox-suid

# Add and Enable PHP-PDO Extenstions
RUN docker-php-ext-install pdo pdo_mysql
RUN docker-php-ext-enable pdo_mysql
RUN docker-php-ext-install pcntl

# Remove Cache
RUN rm -rf /var/cache/apk/*

# Use the default production configuration ($PHP_INI_DIR is variable already set by the default image)
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

#-----------SUPERVISOR------------
COPY .docker/supervisord.conf /etc/supervisord.conf

# Enable Task scheduling
# COPY .docker/supervisor.d/cron.conf /etc/supervisor.d/cron.conf
RUN echo "* * * * * php /var/www/html/artisan schedule:run >> /dev/null 2>&1" >> /etc/crontabs/www

# Enable Laravel horizon
COPY .docker/supervisor.d/horizon.conf /etc/supervisor.d/horizon.conf

# Start php-fpm
COPY .docker/supervisor.d/php-fpm.conf /etc/supervisor.d/php-fpm.conf

# Start Laravel worker (no need if enable Horizon)
# COPY .docker/supervisor.d/worker.conf /etc/supervisor.d/worker.conf
#---------------------------------

#----------ADD USER------------
RUN addgroup -g 1000 www
RUN adduser -D -u 1000 www -G www

# Copy existing application directory permissions
COPY . .

RUN chown -R www:www .

# Change current user to www
USER www

CMD supervisord -n -c /etc/supervisord.conf
