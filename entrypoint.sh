#!/bin/bash

if [ ! -e "/etc/nginx/server.crt" ]; then
	openssl req -newkey rsa:4096 \
		-x509 \
		-sha256 \
		-days 3650 \
		-nodes \
		-out server.crt \
		-keyout server.key \
		-subj "/C=JP/ST=Tokyo/L=Minato-ku/O=42Tokyo/OU=August/CN=example.com"
	mv server.crt server.key /etc/nginx
fi

service mysql start
if [ ! -d "/var/lib/mysql/wpdb" ]; then
	mysql -u root <<- EOSQL
		CREATE DATABASE wpdb;
		CREATE USER 'wpuser'@'localhost' identified by 'dbpassword';
		GRANT ALL PRIVILEGES ON wpdb.* TO 'wpuser'@'localhost';
		FLUSH PRIVILEGES;
	EOSQL
fi

service php7.3-fpm stop
service php7.3-fpm start
service php7.3-fpm restart
service nginx start

exec "$@"
