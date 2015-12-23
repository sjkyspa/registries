#!/usr/bin/env bash
set -eo pipefail

docker build -t haproxy .
HOST_IP=$(ip route|awk '/default/ { print $3 }')
(docker stop etcd && docker rm etcd || true) &&  docker run -d --net=host --name etcd quay.io/coreos/etcd:v2.2.2
docker run --net=host -e BACKEND=http://$HOST_IP:4001 haproxy

until curl http://$HOST_IP:65535/ -v; do
    echo "...."
    sleep 1
done