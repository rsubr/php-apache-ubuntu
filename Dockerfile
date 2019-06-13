FROM ubuntu:bionic
LABEL Author="Raja Subramanian" Description="A comprehensive docker image to run Apache-2.4 PHP-7.2 applications like Wordpress, Laravel, etc"


# Stop dpkg-reconfigure tzdata from prompting for input
ENV DEBIAN_FRONTEND=noninteractive

# Install apache and php7
RUN apt-get update && \
    apt-get -y install \
        apache2 \
        libapache2-mod-php \
        php-curl \
        php-mbstring \
        php-gd \
        php-mysql \
        php-json \
        php-mime-type \
        php-tidy \
        php-intl \
# Ensure apache can bind to 80 as non-root
        libcap2-bin && \
    setcap 'cap_net_bind_service=+ep' /usr/sbin/apache2 && \
    dpkg --purge libcap2-bin && \
    apt-get -y autoremove && \
# As apache is never run as root, change dir ownership
    a2disconf other-vhosts-access-log && \
    chown -Rh www-data. /var/run/apache2 && \
# Clean up apt setup files
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
# Setup apache
    a2enmod rewrite headers expires ext_filter && \
# Increase PHP file upload limit
    echo post_max_size       = 64M >> /etc/php/7.2/apache2/php.ini && \
    echo upload_max_filesize = 64M >> /etc/php/7.2/apache2/php.ini && \
# AWS EFS is slow, so check for php file changes only every 5 mins
    echo opcache.revalidate_freq = 300 >> /etc/php/7.2/apache2/php.ini && \
    echo opcache.fast_shutdown   = 1   >> /etc/php/7.2/apache2/php.ini

# Override default apache config
COPY src/000-default.conf /etc/apache2/sites-available
COPY src/mpm_prefork.conf /etc/apache2/mods-available

# Expose details about this docker image
COPY src/index.php /var/www/html
RUN rm -f /var/www/html/index.html && \
    mkdir /var/www/html/.config && \
    tar cf /var/www/html/.config/etc-apache2.tar etc/apache2 && \
    tar cf /var/www/html/.config/etc-php.tar     etc/php && \
    dpkg -l > /var/www/html/.config/dpkg-l.txt


EXPOSE 80
USER www-data

ENTRYPOINT ["apache2ctl", "-D", "FOREGROUND"]
