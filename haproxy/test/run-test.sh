#!/usr/bin/env bash
set -eo pipefail

docker build -t haproxy .
HOST_IP=$(ip route|awk '/default/ { print $3 }')
(docker stop etcd && docker rm etcd || true) &&  docker run -d -p 4001:4001 -p 2380:2380 -p 2379:2379 \
 --name etcd quay.io/coreos/etcd \
 -name etcd0 \
 -advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001 \
 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
 -initial-advertise-peer-urls http://${HostIP}:2380 \
 -listen-peer-urls http://0.0.0.0:2380 \
 -initial-cluster-token etcd-cluster-1 \
 -initial-cluster etcd0=http://${HostIP}:2380 \
 -initial-cluster-state new

docker run -d --net=host -e BACKEND=http://$HOST_IP:4001 haproxy

until curl http://$HOST_IP:65535/ -v; do
    echo "...."
    sleep 1
done

echo "haproxy initialized"