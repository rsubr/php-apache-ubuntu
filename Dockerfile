FROM ubuntu:noble
LABEL Author="Raja Subramanian" Description="A comprehensive docker image to run Apache-2.4 PHP-8.3 applications like Wordpress, Laravel, etc"

# Stop dpkg-reconfigure tzdata from prompting for input
ENV DEBIAN_FRONTEND=noninteractive

# Install apache and php
RUN  apt-get update && \ 
        apt-get -y install \
        apache2 \
        libapache2-mod-php \
        libapache2-mod-auth-openidc \
        php \
        php-bcmath \
        php-cli \
        php-curl \
        php-gd \
        php-intl \
        php-ldap \
        php-mbstring \
        php-memcached \
        php-mysql \
        php-pgsql \
        php-soap \
        php-tidy \
        php-xmlrpc \
        php-yaml \
        php-zip \
        php-xml \
# Ensure apache can bind to 80 as non-root
        libcap2-bin && \
    setcap 'cap_net_bind_service=+ep' /usr/sbin/apache2 && \
    apt-get -y purge libcap2-bin && \
    apt-get -y autoremove && \
# As apache is never run as root, change dir ownership
    a2disconf other-vhosts-access-log && \
    chown -Rh www-data. /var/run/apache2 && \
# Install ImageMagick CLI tools
    apt-get -y install --no-install-recommends imagemagick && \
# Clean up apt setup files
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
# Setup apache
    a2enmod rewrite headers expires ext_filter

# Override default apache and php config
COPY src/000-default.conf /etc/apache2/sites-available
COPY src/mpm_prefork.conf /etc/apache2/mods-available
COPY src/status.conf      /etc/apache2/mods-available
COPY src/99-local.ini     /etc/php/8.3/apache2/conf.d

# Expose details about this docker image
COPY src/index.php /var/www/html
RUN rm -f /var/www/html/index.html && \
    mkdir /var/www/html/.config && \
    tar cf /var/www/html/.config/etc-apache2.tar /etc/apache2 && \
    tar cf /var/www/html/.config/etc-php.tar     /etc/php/ && \
    dpkg -l > /var/www/html/.config/dpkg-l.txt

EXPOSE 80
USER www-data

ENTRYPOINT ["apache2ctl", "-D", "FOREGROUND"]