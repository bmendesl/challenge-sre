ARG GO_VERSION=1.19.2
ARG ALPINE_VERSION=3.16

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

# - Certificate-Authority certificates are required to call HTTPs endpoints
RUN apk add --no-cache ca-certificates=20220614-r0

# Normalize the base environment
ENV CGO_ENABLED=0 GO111MODULE=on

# Set the builder working directory
RUN mkdir /app
WORKDIR /app

# Copy the go makefile
COPY main.go /app

# Build of the application
RUN go build -o main main.go

# Runtime container
FROM alpine:${ALPINE_VERSION}

# Set the builder working directory
WORKDIR /app

# Copy the binary and sources from the builder stage
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /app/main ./main

# Create a non-root runtime user
RUN addgroup -S gouser && adduser -S -G gouser gouser && chown -R gouser:gouser ./main
USER gouser

# Document the service listening port(s)
EXPOSE 8080

# Define the containers executable entrypoint
ENTRYPOINT ["./main"]