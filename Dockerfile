FROM	debian:buster

RUN		set -ex; \
		apt-get update; \
		apt-get -y install wget vim unzip openssl \
			nginx \
			mariadb-server mariadb-client \
			php-cgi php-common php-fpm php-pear php-mbstring php-zip \
			php-net-socket php-gd php-xml-util php-gettext php-mysql php-bcmath; \
		rm -rf /var/lib/apt/lists/*

WORKDIR	/var/www/html/
RUN		set -ex; \
		wget https://wordpress.org/latest.tar.gz; \
		tar -xvzf latest.tar.gz; \
		rm latest.tar.gz
COPY	./wp-config.php /var/www/html/wordpress/
RUN		chown -R www-data:www-data /var/www/html/wordpress

RUN		set -ex; \
		wget https://files.phpmyadmin.net/phpMyAdmin/5.0.4/phpMyAdmin-5.0.4-all-languages.zip; \
		unzip phpMyAdmin-5.0.4-all-languages.zip; \
		rm phpMyAdmin-5.0.4-all-languages.zip; \
		mv phpMyAdmin-5.0.4-all-languages phpmyadmin

WORKDIR	/
RUN		set -ex; \
		rm -rf /var/cache/apk/*; \
		wget https://github.com/progrium/entrykit/releases/download/v0.4.0/entrykit_0.4.0_Linux_x86_64.tgz; \
		tar -xvzf entrykit_0.4.0_Linux_x86_64.tgz; \
		rm entrykit_0.4.0_Linux_x86_64.tgz; \
		mv entrykit /bin/entrykit; \
		chmod +x /bin/entrykit; \
		entrykit --symlink

COPY	./default.conf.tmpl /etc/nginx/sites-available/
RUN		set -ex; \
		ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/; \
		rm /etc/nginx/sites-enabled/default

COPY	./entrypoint.sh /usr/bin/
RUN		chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT	["render", "/etc/nginx/sites-available/default.conf", "--", "/usr/bin/entrypoint.sh"]
