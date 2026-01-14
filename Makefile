-include container.conf

IMAGE_NAME := $(or $(HOSTNAME),aipod)
CONTAINER_NAME := $(or $(HOSTNAME),aipod)
USERNAME := $(or $(USERNAME),developer)
CHEZMOI_DOTFILES_REPO := $(CHEZMOI_DOTFILES_REPO)

USE_RUST := $(or $(USE_RUST),true)
USE_NPM := $(or $(USE_NPM),true)
USE_UV := $(or $(USE_UV),true)

.PHONY: all run build clean stop rebuild

all: run

run: build
	@if podman container exists $(CONTAINER_NAME) 2>/dev/null; then \
		podman start -ai $(CONTAINER_NAME); \
	else \
		podman run -it --hostname $(CONTAINER_NAME) --name $(CONTAINER_NAME) $(IMAGE_NAME); \
	fi

BUILD_ARGS := --build-arg USERNAME=$(USERNAME) \
	--build-arg CHEZMOI_DOTFILES_REPO=$(CHEZMOI_DOTFILES_REPO) \
	--build-arg USE_RUST=$(USE_RUST) \
	--build-arg USE_NPM=$(USE_NPM) \
	--build-arg USE_UV=$(USE_UV)

build:
	@if ! podman image exists $(IMAGE_NAME) 2>/dev/null; then \
		podman build $(BUILD_ARGS) -t $(IMAGE_NAME) -f Containerfile .; \
	fi

rebuild:
	podman build $(BUILD_ARGS) -t $(IMAGE_NAME) -f Containerfile .

clean: stop
	-podman rm $(CONTAINER_NAME) 2>/dev/null
	-podman rmi $(IMAGE_NAME) 2>/dev/null

stop:
	-podman stop $(CONTAINER_NAME) 2>/dev/null
