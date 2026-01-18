#!/bin/bash
set -e

mkdir -p ../vendored

# x86_64
docker buildx build --platform linux/amd64 --load -t amnezia-x86_64 -f ./Dockerfile_am .
docker run --rm -v $PWD/amneziawg-tools/src:/data amnezia-x86_64 \
    bash -c "GOOS=linux GOARCH=amd64 go build -o /data/amnezia-x86_64 ./ && \
             GOOS=linux GOARCH=arm64 go build -o /data/amnezia-arm64 ./ && \
             GOOS=linux GOARCH=arm go build -o /data/amnezia-arm ./"


# cd amneziawg-go
# GOOS=linux GOARCH=amd64 go build -o ../vendored/amnezia-x86_64
# GOOS=linux GOARCH=arm64 go build -o ../vendored/amnezia-arm64
# GOOS=linux GOARCH=arm go build -o ../vendored/amnezia-arm
# cd ../