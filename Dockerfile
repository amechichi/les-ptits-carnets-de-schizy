FROM dunglas/frankenphp:1-php8.5

RUN install-php-extensions intl opcache zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV SERVER_NAME=:80 \
    APP_DEBUG=0
#   APP_ENV=prod

WORKDIR /app
COPY . .

RUN composer install --optimize-autoloader

# Compile static assets
RUN php bin/console asset-map:compile

EXPOSE 80
