#!/usr/bin/env bash
hub='hub.deepi.cn'
echo "build $1"
docker build -t $hub/$1 $1
echo "push $1 to $hub"
docker push $hub/$1
