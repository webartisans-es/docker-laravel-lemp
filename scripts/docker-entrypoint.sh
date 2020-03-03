#!/bin/sh

MYSQL_ROOT_PASSWORD=${DB_PASSWORD:-'secret'}
MYSQL_PASSWORD=${DB_PASSWORD:-'secret'}
MYSQL_USER=${DB_USERNAME:-'root'}
DB_DATABASE=${DB_DATABASE:-'laravel'}

# init nginx
if [ ! -d "/var/tmp/nginx/client_body" ]; then
  mkdir -p /run/nginx /var/tmp/nginx/client_body
  chown nginx:nginx -R /run/nginx /var/tmp/nginx/
fi

# init mysql
if [ ! -f "/run/mysqld/.init" ]; then
  SQL=$(mktemp)
  mkdir -p /run/mysqld /var/lib/mysql
  chown mysql:mysql -R /run/mysqld /var/lib/mysql
  sed -i -e 's/skip-networking/skip-networking=0/' /etc/my.cnf.d/mariadb-server.cnf
  mysql_install_db --user=mysql --datadir=/var/lib/mysql

  if [ -n "$DB_DATABASE" ]; then
    echo "Create database: ${DB_DATABASE}";
    echo "CREATE DATABASE IF NOT EXISTS $DB_DATABASE CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $SQL
  fi

  if [ "$MYSQL_USER" = "root" ]; then
    echo "We will use root as user";
    echo "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';" >> $SQL
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" >> $SQL
  else
    echo "Create user ${MYSQL_USER}";
    echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $SQL
    echo "GRANT ALL PRIVILEGES ON *.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $SQL
  fi
  echo "FLUSH PRIVILEGES;" >> $SQL

  cat "$SQL" | mysqld --user=mysql --bootstrap --silent-startup --skip-grant-tables=FALSE

  rm -rf ~/.mysql_history ~/.ash_history $SQL
  touch /run/mysqld/.init
fi
exec "$@"
