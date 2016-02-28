#!/usr/bin/env bash
src='hub.deepi.cn'
hub='192.168.99.100:5000'
echo "push $1 to $hub"
docker pull $src/$1 && docker tag $src/$1 $hub/$1
docker push $hub/$1
