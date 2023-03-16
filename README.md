# PHP CLI 

This image extends official PHP CLI image  (php:{php_version}-cli-{debian_distro}) and adds a a number of PHP extensions and locales. 
The intended use for this repository is to provide a base image to run unit tests or other command line scripts. 

Installed extensions:
xdebug, intl, dom, xsl, gettext, mbstring, gmp, bcmath, zip, bz2, pcntl, sockets, fileinfo, opcache sodium

See available tags on docker hub:
https://hub.docker.com/r/leadtech/php-cli/tags

## Setup

Copy .env.dist to .env and configure environment variables.

### Dependencies
- GNU Make
- Docker

### Commands:

Build and push images for all supported PHP versions:
```shell
make all
```

Build docker image
```shell
PHP_VERSION=... make build
```

Push docker image
```shell
PHP_VERSION=... make push
```

Combine the commands above:
```shell
PHP_VERSION=... make build push
```
