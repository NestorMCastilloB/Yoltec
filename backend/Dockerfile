FROM composer:2 AS composer

FROM php:8.4-fpm-alpine AS base

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apk add --no-cache \
    bash git curl libpq-dev libsodium-dev $PHPIZE_DEPS \
  && docker-php-ext-install pdo_pgsql sodium

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copiamos todo el código antes de "composer install" para que exista "artisan"
COPY . .

RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs \
  && chown -R www-data:www-data storage bootstrap/cache

# Script de inicio: valida configuración y levanta el servidor
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["docker-entrypoint.sh"]

FROM base AS development
RUN touch .env.testing && composer install --no-interaction --prefer-dist

FROM base AS production
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader
