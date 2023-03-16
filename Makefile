ifneq (,)
  $(error This Makefile requires GNU Make. )
endif

#SHELL := bash
.PHONY: login all build push
.DEFAULT_GOAL      := help
ROOT_DIR		   ?:
DOCKER_BIN         ?= docker
DOCKER_IMAGE       ?= leadtech/php-cli
DOCKER_FILE        ?= Dockerfile
DOCKER_BUILD_FLAGS ?= --no-cache
DOCKER_BUILD_PATH  ?= .
ENV_FILE		   ?= .env

ifeq ($(wildcard $ENV_FILE),)
$(shell bash -c 'cp ${ENV_FILE}.dist ${ENV_FILE}')
endif

-include $(ENV_FILE)
export $(shell [ ! -n "$(ENV_FILE)" ] || cat $(ENV_FILE) | grep -v \
    --regexp '^('$$(env | sed 's/=.*//'g | tr '\n' '|')')\=')


ifneq ($(wildcard $MAKE_OVERRIDE_PATH),)
$(shell bash -c 'touch ${ENV_FILE}')
endif

GIT_COMMIT ?= $(shell cut -c-8 <<< `git rev-parse HEAD`)
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)


# Initialize PHP version
PHP_VERSION        ?= 7.3
PHP_VERSION_PARTS  := $(subst ., ,$(PHP_VERSION))
PHP_MAJOR_VERSION  := $(word 1,$(PHP_VERSION_PARTS))
PHP_MINOR_VERSION  := $(word 2,$(PHP_VERSION_PARTS))
PHP_MICRO_VERSION  := $(word 3,$(PHP_VERSION_PARTS))
PHP_SHORT_VERSION  ?= ${PHP_MAJOR_VERSION}.${PHP_MINOR_VERSION}
PHP_DIST ?= cli

SUPPORTED_PHP_VERSIONS="7.3 7.4 8.0 8.1"

# Initialize distro (see official PHP docker repo for supported distro's and image tag formats)
ifeq ($(shell expr $(PHP_SHORT_VERSION) \>= 8.0), 1)
   # Distro must be "bullseye"
   DEBIAN_DIST = bullseye
else ifeq ($(shell expr $(PHP_SHORT_VERSION) \>= 7.4), 1)
   # Default distro is "bullseye", but can be set to "buster" ( DEBIAN_DIST=buster make run-tests)
   DEBIAN_DIST ?= bullseye
else
   # Older supported PHP versions require "buster"
   DEBIAN_DIST = buster
endif

ifeq ($(filter $(DEBIAN_DIST),buster bullseye),)
$(error The DEBIAN_DIST variable is invalid. must be one of <buster|bullseye> )
endif

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m PHP_VERSION<[a-z.-]+> (default: 7.2.34) \n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

login:
	$(DOCKER_BIN) login -u $(DOCKER_USER)

build:
	$(DOCKER_BIN) image build $(DOCKER_BUILD_FLAGS) $(DOCKER_BUILD_PATH) \
		-f $(DOCKER_FILE) \
		--target=php \
		--tag=$(DOCKER_IMAGE):$(PHP_SHORT_VERSION) \
		--tag=$(PHP_IMAGE_TAG) \
		--build-arg PHP_VERSION=$(PHP_SHORT_VERSION) \
		--build-arg PHP_DIST=$(PHP_DIST) \
		--build-arg DEBIAN_DIST=$(DEBIAN_DIST)

push:
	docker push $(DOCKER_IMAGE):$(PHP_SHORT_VERSION)

all:
	$(MAKE) login
	PHP_VERSION=7.2 $(MAKE) build push
	PHP_VERSION=7.3 $(MAKE) build push
	PHP_VERSION=7.4 $(MAKE) build push
	PHP_VERSION=8.0 $(MAKE) build push
	PHP_VERSION=8.1 $(MAKE) build push