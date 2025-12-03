FROM composer:2 AS composer

FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    bash git curl libpq-dev \
  && docker-php-ext-install pdo pdo_pgsql

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

COPY . .

RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
