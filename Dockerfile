FROM golang:1.22 AS builder
WORKDIR /src
COPY go.mod ./
RUN go mod download
COPY src ./src
RUN CGO_ENABLED=0 go build -o app ./src

FROM scratch
ADD ./html /html
COPY --from=builder /src/app /app
ENTRYPOINT ["/app"]
EXPOSE 8080
