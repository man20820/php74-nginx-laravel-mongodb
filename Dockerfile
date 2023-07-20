FROM php:7.4-fpm-buster
WORKDIR /var/www/html/
RUN apt update -y
# install prerequisite
RUN apt install nginx supervisor zip unzip libpq-dev -y

RUN pecl install mongodb && docker-php-ext-enable mongodb
# RUN echo "extension=mongodb.so" >> /usr/local/etc/php/conf.d/mongodb.ini

# install postgresql driver
RUN docker-php-ext-install pdo

# install php gd
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip

# inject configuration
RUN mkdir -p /var/log/php-fpm/
COPY deployment/nginx.conf /etc/nginx/sites-enabled/default
COPY deployment/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# setup composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# COPY . /var/www/html/

# composer install
# RUN composer install
# RUN php artisan key:generate
RUN chown -R www-data:www-data .
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
CMD [ "/usr/bin/supervisord" ]

