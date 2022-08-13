#!/bin/bash

function initialiser_db {
	service mysql stop
	mysql_install_db
	service mysql start --character-set-server=utf8 --collation-server=utf8_unicode_ci --sql_mode=NO_AUTO_CREATE_USER
	echo "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin'; GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;" | mysql -uroot
}

function initialiser_parametres {
	mkdir /etc/pmb
	for f in /var/www/html/pmb/includes/db_param.inc.php /var/www/html/pmb/opac_css/includes/opac_db_param.inc.php; do
		etcf=/etc/pmb/$(basename $f)
		touch $etcf
		chown www-data:www-data $etcf
		ln -s $etcf $f
	done
}

ls /var/www/html/pmb/includes/db_param.inc.php || initialiser_parametres
service mysql start --character-set-server=utf8 --collation-server=utf8_unicode_ci --sql_mode=NO_AUTO_CREATE_USER
echo '' | mysql -uadmin -padmin || initialiser_db
service php7.3-fpm start
nginx -g 'daemon off;'
