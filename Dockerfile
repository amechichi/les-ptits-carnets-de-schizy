FROM dunglas/frankenphp:1-php8.5 AS base

RUN install-php-extensions intl opcache zip

FROM base AS build
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app
COPY composer.json composer.lock symfony.lock* ./
# ENV APP_ENV=prod
RUN composer install --no-scripts --no-autoloader --prefer-dist --no-cache # --no-dev
COPY . .
RUN composer dump-autoload --classmap-authoritative \
 && php bin/console asset-map:compile

FROM base

ENV SERVER_NAME=:80 \
    APP_DEBUG=0
#   APP_ENV=prod

WORKDIR /app

COPY --from=build /app /app

EXPOSE 80
