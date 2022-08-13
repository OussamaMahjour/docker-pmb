ARG PHP_VERSION_MOLECULE=7.3
ARG PHP_VERSION=php${PHP_VERSION_MOLECULE}
ARG PHP_DIR=php/${PHP_VERSION_MOLECULE}

FROM debian:buster AS base
ARG PHP_VERSION

ENV DEBIAN_FRONTEND noninteractive
ENV PMB_VERSION=7.4.4
ENV PMB_URL=https://forge.sigb.net/attachments/download/3877/pmb7.4.4.zip

RUN apt-get -y update
RUN apt-get -y install \
    gnupg2 \
    nvi \
    wget \
    unzip \
    nginx \
    mariadb-server \
    php-pear \
    poppler-utils \
    wkhtmltopdf \
    yaz \
    libimage-exiftool-perl \
    ${PHP_VERSION}-apcu \
    ${PHP_VERSION}-json \
    ${PHP_VERSION}-fpm \
    ${PHP_VERSION}-mysql \
    ${PHP_VERSION}-cgi \
    ${PHP_VERSION}-mbstring \
    ${PHP_VERSION}-gd \
    ${PHP_VERSION}-xsl \
    ${PHP_VERSION}-curl \
    ${PHP_VERSION}-intl \
    ${PHP_VERSION}-soap \
    ${PHP_VERSION}-zip \
    ${PHP_VERSION}-bz2 \
    ${PHP_VERSION}-sqlite3 \
    ${PHP_VERSION}-xml \
    ${PHP_VERSION}-xmlrpc

FROM base AS php-exts
RUN apt-get -y install libyaz-dev php-dev
RUN pecl install yaz

FROM base AS install
ARG PHP_DIR

COPY --from=php-exts /usr/lib/php/20180731/yaz.so /usr/lib/php/20180731/yaz.so

RUN cd /var/www/html ; wget ${PMB_URL} ; unzip pmb${PMB_VERSION}.zip ; rm pmb${PMB_VERSION}.zip ; chown -R www-data:www-data .

ADD patches /tmp/patches

RUN apt-get -- install patch; cd /var/www/html ; for p in /tmp/patches/*; do patch -p0 < $p; done
ADD default /etc/nginx/sites-available/
ADD 99-local.ini /etc/${PHP_DIR}/fpm/conf.d/

RUN sed -i s/'max_allowed_packet\t= 16M'/'max_allowed_packet\t= 1G'/ /etc/mysql/my.cnf

ADD index.html /var/www/html/

LABEL pmb_version="${PMB_VERSION}"

ADD entrypoint.sh /usr/local/bin/

EXPOSE 80

VOLUME ["/var/lib/mysql","/etc/pmb","/var/www/html/pmb/admin/backup/backups"]

CMD ["bash", "/usr/local/bin/entrypoint.sh"]
