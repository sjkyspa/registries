#!/usr/bin/env bash

docker run -d --net=host --name etcd quay.io/coreos/etcd:v2.2.2
docker build -t haproxy .
docker run -d -e BACKEND=http://127.0.0.1:4001 haproxy