FROM php:8.2-fpm

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libpq-dev

RUN docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_pgsql sockets mbstring exif pcntl bcmath gd zip \
    && pecl install redis && docker-php-ext-enable redis

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./

RUN composer install --no-scripts --no-autoloader

COPY . .

RUN composer dump-autoload --optimize

RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /usr/local/bin/wait-for-it
RUN chmod +x /usr/local/bin/wait-for-it

EXPOSE 8000

CMD sh -c "wait-for-it db:5432 -t 60 -- php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000"