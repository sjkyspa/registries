#!/usr/bin/env bash
set -eo pipefail

on_exit() {
    last_status=$?
    if [ "$last_status" != "0" ]; then
        echo "error"
        echo  "Cleaning ..."
        if [ -n "$ETCD_CONTAINER" ]; then
            echo
            docker stop $ETCD_CONTAINER &>/dev/null && docker rm $ETCD_CONTAINER &>/dev/null
            echo
        fi
        if [ -n "$HAPROXY_CONTAINER" ]; then
            echo
            docker stop $HAPROXY_CONTAINER &>/dev/null && docker rm $HAPROXY_CONTAINER &>/dev/null
            echo
        fi
        echo "Clean complete"
        exit 1;
    else
        echo "build success"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

docker build -t haproxy .
HOST_IP=$(ip route|awk '/default/ { print $3 }')
(docker stop etcd && docker rm etcd || true)
ETCD_CONTAINER=$( docker run -d -p 4001:4001 -p 2380:2380 -p 2379:2379 \
 --name etcd quay.io/coreos/etcd \
 -name etcd0 \
 -advertise-client-urls http://${HostIP}:2379,http://${HOST_IP}:4001 \
 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
 -initial-advertise-peer-urls http://${HOST_IP}:2380 \
 -listen-peer-urls http://0.0.0.0:2380 \
 -initial-cluster-token etcd-cluster-1 \
 -initial-cluster etcd0=http://${HOST_IP}:2380 \
 -initial-cluster-state new)

HAPROXY_CONTAINER=$(docker run -d --net=host -e BACKEND=http://$HOST_IP:4001 haproxy)

until curl http://$HOST_IP:65535/ -v &>/dev/null; do
    echo "...."
    sleep 1
done

echo "haproxy initialized"

etcd_set() {
    if [ $# != 2 ]; then
        echo "need two parameter"
    fi
    curl -XPUT -v http://${HOST_IP}:4001/v2/keys$1 -d value="$2"
}

etcd_get() {
    if [ $# != 1 ]; then
        echo "need one parameter"
    fi
    curl http://${HOST_IP}:4001/v2/keys$1
}

echo "init the etcd with stub config"
etcd_set "/services-internal/mysql/ipport" "$HOST_IP:4001"

echo "should wait and get access the of the port"

until curl http://$HOST_IP:51000/ -v; do
    etcd_get "/services-internal"
    echo "...."
    sleep 1
    docker logs $HAPROXY_CONTAINER
done