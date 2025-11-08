# DevOpsAndKubernetesCodingSession

This repository includes a cross-compilation workflow and Docker image build helpers to prepare the project for testing on multiple platforms and architectures.

- `Makefile` — targets to build cross-compiled Go binaries and to build Docker images (host platform and cross-compiled images).
- `Dockerfile` — multi-stage Dockerfile using `quay.io/projectquay/golang` as the build image; supports build-args `TARGETOS` and `TARGETARCH` to cross-compile the binary inside the build stage.


## Quick usage

Build cross-compiled binaries (artifacts stored in `./bin`):

```bash
# Build linux/amd64 binary
make linux

# Build linux/arm64 binary
make arm

# Build macOS (darwin/arm64) binary
make macos

# Build windows/amd64 binary
make windows
```

Build Docker images

```bash
# Build an image for the host platform (Docker daemon's platform). The image is tagged by default as
# quay.io/projectquay/devopsandkubernetescodingsession:local — override with IMAGE_TAG=... if you prefer.
make image

# Build an image that embeds a cross-compiled binary (pass TARGETOS and TARGETARCH). Example:
make docker-build TARGETOS=linux TARGETARCH=arm64 TAG=quay.io/yourorg/repo:linux-arm64
```

Clean local artifacts and the default image tag:

```bash
make clean
```

## Notes and limitations

- The `Dockerfile` uses `quay.io/projectquay/golang` for the build stage as requested.
- The approach uses standard `docker build` and build-args for cross-compilation (no `buildx`). The build stage sets `GOOS` and `GOARCH` from `TARGETOS` and `TARGETARCH` so the Go compiler produces a binary for the target platform.
- Images that contain binaries for a different OS/architecture are not generally runnable on a host with a different OS/arch (for example, a macOS binary inside an image cannot be executed on a Linux Docker daemon). To run without emulation, use a machine whose OS/architecture matches the target (for example, build and run a macOS/arm64 image on Apple Silicon macOS hosts).
- I used `quay.io` as an alternative container registry to avoid Docker Hub rate limits; change `IMAGE_TAG` in the `Makefile` to point to the registry/repository you control before pushing images.

