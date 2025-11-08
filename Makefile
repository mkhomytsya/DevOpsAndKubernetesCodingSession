## Makefile for cross-compiling and building Docker images
# - `make linux|arm|macos|windows` will produce cross-compiled binaries in ./bin
# - `make image` will build a Docker image for the host platform (no buildx)
# - `make docker-build TARGETOS=... TARGETARCH=... TAG=...` builds an image containing
#    a cross-compiled binary for the requested TARGETOS/TARGETARCH
# - `make clean` removes created image and build artifacts

IMAGE_TAG ?= ghcr.io/mkhomytsya/devopsandkubernetescodingsession:local
BIN_DIR := bin
APP := app
SRC := ./src

# Derived defaults (can be overridden)
REPO ?= $(shell echo $(IMAGE_TAG) | sed 's/:.*//')
SHORT_SHA ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo local)

.PHONY: linux arm macos windows image docker-build push clean

.ONESHELL:

linux:
	@echo "Building for linux/amd64"
	mkdir -p $(BIN_DIR)/linux_amd64
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o $(BIN_DIR)/linux_amd64/$(APP) $(SRC)

arm:
	@echo "Building for linux/arm64"
	mkdir -p $(BIN_DIR)/linux_arm64
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o $(BIN_DIR)/linux_arm64/$(APP) $(SRC)

macos:
	@echo "Building for darwin/arm64 (macOS ARM)"
	mkdir -p $(BIN_DIR)/darwin_arm64
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -o $(BIN_DIR)/darwin_arm64/$(APP) $(SRC)

windows:
	@echo "Building for windows/amd64"
	mkdir -p $(BIN_DIR)/windows_amd64
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -o $(BIN_DIR)/windows_amd64/$(APP).exe $(SRC)

## Build a docker image for the host platform. This uses standard `docker build` and
## tags the image as $(IMAGE_TAG).
image:
	@echo "Building Docker image for host platform (Docker daemon's platform) -> $(IMAGE_TAG)"
	docker build -t $(IMAGE_TAG) .

## Build a docker image embedding a cross-compiled binary. Use build-args TARGETOS and TARGETARCH.
## Example: make docker-build TARGETOS=linux TARGETARCH=arm64 TAG=$(IMAGE_TAG)-linux-arm64
docker-build:
	@if [ -z "$(TARGETOS)" ] || [ -z "$(TARGETARCH)" ]; then echo "Specify TARGETOS and TARGETARCH, e.g. make docker-build TARGETOS=linux TARGETARCH=arm64 TAG=$(IMAGE_TAG)-linux-arm64"; exit 1; fi
	@# If user provided TAG use it, otherwise generate one from repo, target and git sha
	if [ -n "$(TAG)" ]; then \
		FINAL_TAG="$(TAG)"; \
	else \
		FINAL_TAG=$(REPO):$(TARGETOS)-$(TARGETARCH)-$(SHORT_SHA); \
	fi; \
	echo "Building image with TARGETOS=$(TARGETOS) TARGETARCH=$(TARGETARCH) -> $$FINAL_TAG"; \
	docker build --build-arg TARGETOS=$(TARGETOS) --build-arg TARGETARCH=$(TARGETARCH) -t $$FINAL_TAG .

# Push an image to the registry. Use TAG to specify an image, otherwise IMAGE_TAG is used.
#   make push TAG=ghcr.io/yourorg/repo:linux-arm64 TARGETOS=linux TARGETARCH=arm64
push:
	@if [ -z "$(TARGETOS)" ] || [ -z "$(TARGETARCH)" ]; then \
		echo "Specify TARGETOS and TARGETARCH, e.g. make push TARGETOS=linux TARGETARCH=amd64"; \
		exit 1; \
	fi
	@IMAGE="$(REPO):$(TARGETOS)-$(TARGETARCH)-$(SHORT_SHA)"; \
	echo "Pushing $$IMAGE"; \
	docker push $$IMAGE

clean:
	@echo "Cleaning: removing image $(IMAGE_TAG) and build artifacts"
	# Stop and remove any containers that were created from this image
	-@containers=$$(docker ps -a -q --filter ancestor=$(IMAGE_TAG)); \
	 if [ -n "$$containers" ]; then \
		 echo "Stopping and removing containers: $$containers"; \
		 docker rm -f $$containers || true; \
	 fi; \
	# Force remove the image (if present)
	-@docker rmi -f $(IMAGE_TAG) || true
	-@rm -rf $(BIN_DIR)

# Notes:
# - This Makefile uses Go's native cross-compilation to produce binaries for other OS/ARCH pairs.
# - The Dockerfile includes build-args TARGETOS/TARGETARCH to cross-compile inside a container
#   (no buildx required). The produced image will contain the binary for the target platform but
#   may not be runnable on the current Docker daemon if the target OS/ARCH differs (e.g., darwin or windows).
# - Replace IMAGE_TAG with a repository you control on an alternative registry (quay.io, ghcr.io, etc.).
