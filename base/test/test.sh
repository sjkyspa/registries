#!/usr/bin/env bash
set -eo pipefail

BASEDIR=$(dirname $0)

cd $BASEDIR

docker build -f ./Dockerfile -t haproxytest ..
docker run --privileged -v /var/run/docker.sock:/var/run/docker.sock -ti --rm haproxytest