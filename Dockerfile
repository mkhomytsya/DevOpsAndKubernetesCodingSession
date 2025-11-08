# syntax=docker/dockerfile:1
ARG TARGETOS=linux
ARG TARGETARCH=amd64

FROM quay.io/projectquay/golang:1.25 AS builder
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src

# download deps first for better caching if project uses modules
COPY go.mod ./
RUN go mod download || true

COPY src ./src

# Set cross-compilation env vars. This builds a static binary using Go's cross-compile
ENV GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0
RUN go build -o /app ./src

# Final image: minimal. Note: images built for non-Linux targets will contain the
# cross-compiled binary but won't be runnable on a Linux Docker Engine.
FROM scratch AS final
ADD ./html /html
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
EXPOSE 8080

# Usage examples (from host):
# Build host image (platform of the Docker daemon):
#   docker build -t quay.io/<org>/devops-session:latest .
# Build image with a cross-compiled binary embedded (does NOT require buildx):
#   docker build --build-arg TARGETOS=linux --build-arg TARGETARCH=arm64 -t quay.io/<org>/devops-session:linux-arm64 .
