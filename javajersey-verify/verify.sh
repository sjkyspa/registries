#!/bin/bash

set -eo pipefail

puts_red() {
    echo $'\033[0;31m'"      $@" $'\033[0m'
}

puts_red_f() {
  while read data; do
    echo $'\033[0;31m'"      $data" $'\033[0m'
  done
}

puts_green() {
  echo $'\033[0;32m'"      $@" $'\033[0m'
}

puts_step() {
  echo $'\033[0;34m'" -----> $@" $'\033[0m'
}

on_exit() {
    last_status=$?
    echo $last_status
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log|puts_red_f
        fi

        puts_step "Cleaning ..."
        if [ -n "$MYSQL_CONTAINER" ]; then
            echo

            docker stop $MYSQL_CONTAINER &>process.log && docker rm $MYSQL_CONTAINER &>process.log
            echo
        fi
        if [ -n "$IMAGE_CONTAINER" ]; then
            echo
            docker stop $IMAGE_CONTAINER &>process.log && docker rm $IMAGE_CONTAINER &>process.log
            echo
        fi
        if [ -n "$VERIFY_CONTAINER" ]; then
            echo
            docker stop $VERIFY_CONTAINER &>process.log && docker rm $VERIFY_CONTAINER &>process.log
            echo
        fi
        puts_step "Cleaning complete"

        exit 1;
    else
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

HOST_IP=$(ip route|awk '/default/ { print $3 }')

CURRENT_DIR=$CODEBASE

cd $CODEBASE

echo
puts_step "Building verify jar..."
GRADLE_USER_HOME="$CACHE_DIR" gradle itestJar &>process.log
puts_step "Build verify finished"
puts_step "Start verify"
ENTRYPOINT=http://$ENDPOINT java -jar build/libs/verify-standalone.jar
puts_step "Verify finished"
echo

