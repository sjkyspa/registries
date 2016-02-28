#!/usr/bin/env bash
hub='192.168.99.100:5000'
echo "build $1"
docker build -t $hub/$1 $1
echo "push $1 to $hub"
docker push $hub/$1
