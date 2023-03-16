# ======================================================================================================================
# PHP Image
# Supported distros are buster (default) and bullseye (>= PHP 7.4)
# ======================================================================================================================

ARG PHP_VERSION=8.1
ARG PHP_DIST=cli
ARG DEBIAN_DIST=bullseye

FROM php:${PHP_VERSION}-${PHP_DIST}-${DEBIAN_DIST} as php

MAINTAINER Daan Biesterbos

ARG INSTALL_LOCALES='en_US.UTF-8 en_GB.UTF-8 nl_NL.UTF-8 de_DE.UTF-8 fr_FR.UTF-8'
ARG DEFAULT_LOCALE='en_US.UTF-8'
ARG GIT_BRANCH=""
ARG GIT_REPO=''
ARG GIT_COMMIT=''

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV XDEBUG_MODE coverage
ENV INSTALL_LOCALES $INSTALL_LOCALES

LABEL "repo"="$GIT_REPO" "branch"="$GIT_BRANCH" "commit"="$GIT_COMMIT"

RUN apt-get update -y && apt-get install -y unzip openssl

RUN pecl install xdebug-3.1.0

# Locales
RUN apt-get update \
	&& apt-get install -y locales

RUN dpkg-reconfigure locales \
	&& locale-gen C.UTF-8 \
	&& /usr/sbin/update-locale LANG=C.UTF-8

RUN echo "${INSTALL_LOCALES} UTF-8" >> /etc/locale.gen && locale-gen
ENV LC_ALL C.UTF-8
ENV LANG $DEFAULT_LOCALE
ENV LANGUAGE $DEFAULT_LOCALE

# intl
RUN apt-get update \
	&& apt-get install -y libicu-dev \
	&& docker-php-ext-configure intl \
	&& docker-php-ext-install -j$(nproc) intl

# xml
RUN apt-get update \
	&& apt-get install -y \
	libxml2-dev \
	libxslt-dev \
	&& docker-php-ext-install -j$(nproc) \
		dom \
		xsl

# strings
RUN apt-get update \
    && apt-get install -y libonig-dev \
    && docker-php-ext-install -j$(nproc) \
	    gettext \
	    mbstring

# math
RUN apt-get update \
	&& apt-get install -y libgmp-dev \
	&& ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
	&& docker-php-ext-install -j$(nproc) \
		gmp \
		bcmath

# compression
RUN apt-get update \
	&& apt-get install -y \
	libbz2-dev \
	zlib1g-dev \
	libzip-dev \
	&& docker-php-ext-install -j$(nproc) \
		zip \
		bz2

# others
RUN docker-php-ext-install -j$(nproc) \
	pcntl \
	sockets \
	fileinfo

RUN docker-php-ext-enable opcache sodium xdebug

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN mkdir /app
WORKDIR /app