FROM webartisans-es/docker-php:latest

MAINTAINER Boudy de Geer <boudydegeer@webartisans.es>

RUN \
  # install
  apk add -U --no-cache \
    memcached \
    mysql mysql-client \
    vim \
    nginx \
    redis \
    supervisor \
  # cleanup
  && rm -rf /var/cache/apk/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/*

# mysql config
COPY ./config/mysql/my.cnf /etc/mysql/my.cnf

# nginx config
COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# resource
COPY ./config/php/index.php /var/www/html/index.php

# supervisor config
COPY \
  ./config/memcached/memcached.ini \
  ./config/mysql/mysqld.ini \
  ./config/nginx/nginx.ini \
  ./config/php/php-fpm.ini \
  ./config/redis/redis-server.ini \
    /etc/supervisor.d/

# entrypoint
COPY ./scripts/docker-entrypoint.sh /scripts/docker-entrypoint.sh
RUN chmod +x /scripts/docker-entrypoint.sh

# ports
EXPOSE 6379 3306 80

# commands
ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["supervisord", "-n", "-j", "/supervisord.pid"]
