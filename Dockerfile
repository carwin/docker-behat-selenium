FROM php:5.6.22

# Set an environment variable which we can update to have control over when containers are refreshed
ENV REFRESHED_AT 2016-06-22

RUN apt-get -qq update

RUN apt-get install -y \
      git \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libmcrypt-dev \
      libpng12-dev \
      mysql-client \
      sudo \
      wget \
      firefox-esr \
      x11vnc \
      openssh-server \
      xvfb \
      supervisor \
      openjdk-7-jre-headless \
      # Necessary library for phantomjs per https://github.com/ariya/phantomjs/issues/10904
      fontconfig

RUN docker-php-ext-install -j$(nproc) iconv mcrypt opcache pdo_mysql pdo zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /var/www/html/tests
RUN mkdir -p /etc/php.d

RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=5000'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
  } > /etc/php.d/opcache-recommended.ini

RUN { \
    echo "date.timezone = America/New_York"; \
    echo "memory_limit = 512M"; \
    echo "upload_max_filesize = 10M"; \
    echo "post_max_size = 10M"; \
    echo "realpath_cache_size = 256k"; \
    echo "realpath_cache_ttl = 300"; \
  } > /usr/local/etc/php/php.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer
ENV PATH /root/.composer/vendor/bin:$PATH

# Install selenium
RUN mkdir /selenium \
  && curl -O "http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.0.jar" \
  && mv selenium-server-standalone-2.53.0.jar /selenium

WORKDIR /var/www/html/tests

CMD { /sbin/ip route|awk '/default/ { print $3 }'; echo 'host'; } | tr '\n' ' ' >> /etc/hosts && supervisord
