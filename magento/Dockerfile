FROM php:7.4.16-apache

RUN apt-get update                    \
  && apt-get upgrade -y               \
  && apt-get install -y               \
    cron                              \
    default-mysql-client              \
    libapache2-mod-security2          \
    libfreetype6-dev                  \
    libicu-dev                        \
    libjpeg-dev                       \
    libpng-dev                        \
    libxml2-dev                       \
    libxslt-dev                       \
    libzip-dev                        \
    lsof                              \
    unzip                             \
    zlib1g-dev                        \
  && apt-get clean                    \
  && rm -rf /var/lib/apt/lists/*

RUN set -x                            \
  && docker-php-ext-configure gd      \
    --with-freetype                   \
    --with-jpeg                       \
  && docker-php-ext-install           \
    bcmath                            \
    dom                               \
    gd                                \
    intl                              \
    pdo_mysql                         \
    soap                              \
    sockets                           \
    xsl                               \
    zip

COPY install_composer.sh /tmp/
RUN bash /tmp/install_composer.sh     \
  && rm -f /tmp/install_composer.sh

RUN set -x                            \
  && a2enmod expires                  \
  && a2enmod headers                  \
  && a2enmod rewrite                  \
  && a2enmod ssl

COPY usr/local/etc/php/php.ini /usr/local/etc/php/php.ini
COPY etc/apache2/apache2.conf /etc/apache2/apache2.conf
COPY etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
