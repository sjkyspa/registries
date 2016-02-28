#!/bin/sh -x

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
        puts_green "build success"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

HOST_IP=$(ip route|awk '/default/ { print $3 }')

GIT_PATH=$CODEBASE/../../
CURRENT_DIR=$CODEBASE

if [ -f "$CODEBASE/manifest.json" ]; then
    echo 'manifest exists'
    cd $GIT_PATH
    echo `pwd`
    git --no-pager log --reverse --pretty=format:%at &>/dev/null
    if [ "$?" != "0" ]; then
        first_commit=$(stat -c%Y config)
    else
        first_commit=$(git --no-pager log --reverse --pretty=format:%at |head -n1)
    fi

    cd $CODEBASE
    evaluation_uri=$(cat manifest.json| jq -r '.evaluation_uri')

    echo "$evaluation_uri"
    if [ -z "$evaluation_uri" ] ; then
        puts_red "missing manifest.json"
        exit 1
    fi
    entry_point='http://ke-tsu-api.deepi.cn'
    if [ -z "$entry_point" ] ; then
        puts_red "bad format of manifest.json"
        exit 1
    fi
    echo "entry_point=${entry_point}" > $CURRENT_DIR/src/itest/resources/meta.properties
    echo "evaluation_uri=${evaluation_uri}" >> $CURRENT_DIR/src/itest/resources/meta.properties
    echo "first_commit=${first_commit}" >> $CURRENT_DIR/src/itest/resources/meta.properties
    cat $CURRENT_DIR/src/itest/resources/meta.properties
fi

cd $CODEBASE

echo
puts_step "Building verify jar..."
GRADLE_USER_HOME="$CACHE_DIR" gradle itestJar &>process.log
puts_step "Build verify finished"
puts_step "Start verify"
ENTRYPOINT=http://$ENDPOINT java -jar build/libs/verify-standalone.jar
puts_step "Verify finished"
# docker build -f Dockerfile.verify -t $VERIFY_IMAGE . &>process.log
# puts_step "Building verify image $VERIFY_IMAGE complete"
echo

# echo
# puts_step "Launching baking services ..."
# MYSQL_CONTAINER=$(docker run -d -P -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=appdb -e MYSQL_ROOT_PASSWORD=mysql hub.deepi.cn/mysql)
# MYSQL_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "3306/tcp") 0).HostPort}}' ${MYSQL_CONTAINER})
# DATABASE="jdbc:mysql://$HOST_IP:$MYSQL_PORT/appdb?user=mysql&password=mysql"
# until docker exec $MYSQL_CONTAINER mysql -h127.0.0.1 -P3306 -umysql -pmysql -e "select 1" &>/dev/null ; do
#     echo "...."
#     sleep 1
# done
# puts_step "Complete Launching baking services"

# puts_step "Start run the $IMAGE"
# echo
# IMAGE_CONTAINER=$(docker run \
#         -d -P \
#         -v /var/run/docker.sock:/var/run/docker.sock \
#         -e HOST=$HOST \
#         -e DATABASE=$DATABASE \
#          $IMAGE)
# APP_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "8088/tcp") 0).HostPort}}' ${IMAGE_CONTAINER})
# ENTRYPOINT="http://$HOST_IP:$APP_PORT"
# puts_step "Run the $IMAGE complete"

# puts_step "Start run app verify: $VERIFY_IMAGE"
# VERIFY_CONTAINER=$(docker run -d \
#         --privileged \
#         -v /var/run/docker.sock:/var/run/docker.sock \
#         -v /codebase:/codebase \
#         -v /build_cache:/build_cache \
#         -v /gitbare:/gitbare:ro \
#         -e HOST=$HOST \
#         -e ENTRYPOINT=$ENDPOINT \
#          $VERIFY_IMAGE)
#
# docker attach $VERIFY_CONTAINER
