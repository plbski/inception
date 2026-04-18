FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    wget \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html/wordpress && \
    mkdir -p /run/php && \
    chown -R www-data:www-data /var/www/html/wordpress

COPY conf/www.conf /etc/php/*/fpm/pool.d/www.conf
COPY tools/wp.sh /usr/local/bin/wp_setup.sh
RUN chmod +x /usr/local/bin/wp_setup.sh

EXPOSE 9000

CMD ["/usr/local/bin/wp_setup.sh"]
