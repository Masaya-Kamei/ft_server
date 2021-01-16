FROM	debian:buster

RUN		set -ex; \
		apt-get update; \
		apt-get -y install \
			wget vim unzip openssl \
			nginx \
			mariadb-server mariadb-client \
			php-cgi php-common php-fpm php-pear php-mbstring php-zip \
			php-net-socket php-gd php-xml-util php-gettext php-mysql php-bcmath; \
		rm -rf /var/lib/apt/lists/*

WORKDIR	/var/www/html/
RUN		set -ex; \
		wget https://wordpress.org/latest.tar.gz; \
		tar -xvzf latest.tar.gz; \
		rm latest.tar.gz; \
		chown -R www-data:www-data /var/www/html/wordpress

RUN		set -ex; \
		wget https://files.phpmyadmin.net/phpMyAdmin/5.0.4/phpMyAdmin-5.0.4-all-languages.zip; \
		unzip phpMyAdmin-5.0.4-all-languages.zip; \
		rm phpMyAdmin-5.0.4-all-languages.zip; \
		mv phpMyAdmin-5.0.4-all-languages phpmyadmin

WORKDIR	/
RUN		set -ex; \
		wget https://github.com/progrium/entrykit/releases/download/v0.4.0/entrykit_0.4.0_Linux_x86_64.tgz; \
		tar -xvzf entrykit_0.4.0_Linux_x86_64.tgz; \
		rm entrykit_0.4.0_Linux_x86_64.tgz; \
		mv entrykit /bin/entrykit; \
		chmod +x /bin/entrykit; \
		entrykit --symlink

WORKDIR /etc/nginx
RUN		openssl req -newkey rsa:4096 \
			-x509 \
			-sha256 \
			-days 3650 \
			-nodes \
			-out server.crt \
			-keyout server.key \
			-subj "/C=JP/ST=Tokyo/L=Minato-ku/O=42Tokyo/OU=August/CN=example.com"

WORKDIR	/
RUN		set -ex; \
		service mysql start; \
		echo "CREATE DATABASE wpdb;" | mysql -u root; \
		echo "CREATE USER 'wpuser'@'localhost' identified by 'dbpassword';" | mysql -u root; \
		echo "GRANT ALL PRIVILEGES ON wpdb.* TO 'wpuser'@'localhost';" | mysql -u root; \
		echo "FLUSH PRIVILEGES;" | mysql -u root

COPY	./srcs/default.conf.tmpl /etc/nginx/sites-available/
COPY	./srcs/wp-config.php /var/www/html/wordpress/
COPY	./srcs/entrypoint.sh /usr/bin/
RUN		set -ex; \
		chmod +r /etc/nginx/sites-available/default.conf.tmpl; \
		chmod +r /var/www/html/wordpress/wp-config.php; \
		chmod +x /usr/bin/entrypoint.sh; \
		ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/

ENTRYPOINT	["render", "/etc/nginx/sites-available/default.conf", "--", "/usr/bin/entrypoint.sh"]
