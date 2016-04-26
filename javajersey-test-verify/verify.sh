#!/bin/sh

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
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log|puts_red_f
        fi
        exit 1;
    else
        puts_green "build success"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

CODEBASE_DIR=$CODEBASE
HOST_IP=$(ip route|awk '/default/ { print $3 }')

# echo
# puts_step "Launching baking services ..."
# MYSQL_CONTAINER=$(docker run -d -P -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=appdb -e MYSQL_ROOT_PASSWORD=mysql tutum/mysql)
# MYSQL_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "3306/tcp") 0).HostPort}}' ${MYSQL_CONTAINER})
# export DATABASE="jdbc:mysql://$HOST_IP:$MYSQL_PORT/appdb?user=mysql&password=mysql"
# until docker exec $MYSQL_CONTAINER mysql -h127.0.0.1 -P3306 -umysql -pmysql -e "select 1" &>/dev/null ; do
#     echo "...."
#     sleep 1
# done
# puts_step "Complete Launching baking services"
# echo

cd $CODEBASE_DIR
# echo
# puts_step "Start migratioin ..."
# GRADLE_USER_HOME="$CACHE_DIR" gradle fC fM &> process.log
# puts_step "Migration complete"
# echo

# echo
# puts_step "Start test ..."
# GRADLE_USER_HOME="$CACHE_DIR" gradle test -i &> process.log
# puts_step "Test complete"
# echo

echo "Run integration test with endpoint $ENDPOINT"
