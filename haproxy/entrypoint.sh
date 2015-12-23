#!/bin/bash

if [ -z "$BACKEND" ]
then
  echo "Missing BACKEND env var"
  exit -1
fi

set -eo pipefail

#confd will start haproxy, since conf will be different than existing (which is null)

echo "[haproxy-confd] booting container. BACKEND: $BACKEND"

function config_fail()
{
	echo "Failed to start due to config error"
	exit -1
}

# Loop until confd has updated the haproxy config
n=0
until confd -onetime -node "$BACKEND"; do
  if [ "$n" -eq "4" ];  then config_fail; fi
  echo "[haproxy-confd] waiting for confd to refresh haproxy.cfg"
  n=$((n+1))
  sleep $n
done

echo "[haproxy-confd] Initial HAProxy config created. Starting confd"

confd -node "$BACKEND"