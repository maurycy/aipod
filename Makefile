-include container.conf

IMAGE_NAME := $(or $(HOSTNAME),aipod)
CONTAINER_NAME := $(or $(HOSTNAME),aipod)
USERNAME := $(or $(USERNAME),aipod)

.PHONY: all run build clean stop rebuild

all: run

run: build
	@if podman container exists $(CONTAINER_NAME) 2>/dev/null; then \
		podman start -ai $(CONTAINER_NAME); \
	else \
		podman run -it --hostname $(CONTAINER_NAME) --name $(CONTAINER_NAME) $(IMAGE_NAME); \
	fi

build:
	@if ! podman image exists $(IMAGE_NAME) 2>/dev/null; then \
		podman build --build-arg USERNAME=$(USERNAME) -t $(IMAGE_NAME) -f Containerfile .; \
	fi

rebuild:
	podman build --build-arg USERNAME=$(USERNAME) -t $(IMAGE_NAME) -f Containerfile .

clean: stop
	-podman rm $(CONTAINER_NAME) 2>/dev/null
	-podman rmi $(IMAGE_NAME) 2>/dev/null

stop:
	-podman stop $(CONTAINER_NAME) 2>/dev/null
