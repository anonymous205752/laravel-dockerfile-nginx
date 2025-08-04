FROM php:8.4-fpm

# Install system dependencies (nginx, supervisor, etc.)
RUN apt-get update && apt-get install -y \
 build-essential \
 libpng-dev \
 libjpeg-dev \
 libfreetype6-dev \
 locales \
 zip \
 nginx \
 supervisor \
 jpegoptim optipng pngquant gifsicle \
 vim unzip git curl libonig-dev libxml2-dev libzip-dev \
 && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Allow Composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER=1

WORKDIR /var/www/html

# Copy the Laravel codebase
COPY . ./

# Remove possible existing nginx config
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

# Copy nginx config
COPY ./docker-setup/docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy supervisor config
COPY ./docker-setup/docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Run composer install with dev dependencies (important so Scribe gets installed)
RUN composer install --ignore-platform-req=php --optimize-autoloader --verbose

# Set correct permissions
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy entrypoint script and give execute permission
COPY ./docker-setup/docker/script/startup.sh /usr/local/bin/startup.sh

RUN chmod +x /usr/local/bin/startup.sh

# Expose port 10000 (make sure this matches nginx config)
EXPOSE 10000

# Start up all services
CMD ["/usr/local/bin/startup.sh"]
