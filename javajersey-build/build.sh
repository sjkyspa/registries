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

        if [ -n "$MYSQL_CONTAINER" ]; then
            echo
            puts_step "Cleaning ..."
            docker stop $MYSQL_CONTAINER &>process.log && docker rm $MYSQL_CONTAINER &>process.log
            puts_step "Cleaning complete"
            echo
        fi
        exit 1;
    else
        puts_green "build success"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

CODEBASE_DIR="/codebase"
CACHE_DIR="/build_cache"

echo
puts_step "Launching baking services ..."
MYSQL_CONTAINER=$(docker run -d -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=appdb -e MYSQL_ROOT_PASSWORD=mysql hub.deepi.cn/mysql)
CONTAINER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${MYSQL_CONTAINER})
export DATABASE="jdbc:mysql://${CONTAINER_IP}:3306/appdb?user=mysql&password=mysql"
puts_step "Complete Launching baking services"
echo

cd $CODEBASE_DIR
echo
puts_step "Start migratioin ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle fC fM &> process.log
puts_step "Migration complete"
echo

echo
puts_step "Start test ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle test -i &> process.log
puts_step "Test complete"
echo

puts_step "Start generate standalone ..."
GRADLE_USER_HOME="$CACHE_DIR" gradle standaloneJar &>process.log
puts_step "Generate standalone Complete"

(cat  <<'EOF'
#!/bin/sh
#host_ip=$(ip route|awk '/default/ { print $3 }')
#mysql_exists_code=$(curl -sL http://${host_ip}:4001/v2/keys/services/${APP_NAME}_mysql.service/data|jq -r ".errorCode")
#if [ "$mysql_exists_code" == "" ] ; then
#        echo "etcd not started"
#        exit 1
#fi
#
#if [ "$mysql_exists_code" == "100" -o "$mysql_exists_code" == "null" ] ; then
#echo "launch backend service"
#cat >mysql.json <<EOFINNER
#{
#  "desiredState": "launched",
#  "options": [
#    {
#      "section": "Service",
#      "name": "ExecStartPre",
#      "value": "/bin/sh -c \"etcdctl set /services/%n/data 'user=mysql&password=mysql'\""
#    },
#    {
#      "section": "Service",
#      "name": "ExecStartPre",
#      "value": "/bin/sh -c \"docker inspect %n >/dev/null 2>&1 && docker rm -f %n || true\""
#    },
#    {
#      "section": "Service",
#      "name": "ExecStart",
#      "value": "/bin/sh -c \"docker run --name %n --rm -v /var/run/docker.sock:/var/run/docker.sock -e MYSQL_ROOT_PASSWORD=mysql -e MYSQL_USER=mysql -e SERVICE_NAME=%n -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=appdb -P  mysql\""
#    },
#    {
#      "section": "Service",
#      "name": "ExecStop",
#      "value": "/usr/bin/docker stop %n"
#    },
#    {
#      "section": "Service",
#      "name": "Restart",
#      "value": "on-failure"
#    }
#  ]
#}
#EOFINNER
#curl -X PUT -H "Content-Type:application/json" http://${host_ip}:49153/v1-alpha/units/${APP_NAME}_mysql.service -d @mysql.json
#sleep 20
#fi
#
#echo "find backend service"
#credential=$(curl -sL http://${host_ip}:4001/v2/keys/services/${APP_NAME}_mysql.service/data|jq -r '.node.value')
#ipport=$(curl -sL http://${host_ip}:4001/v2/keys/services/${APP_NAME}_mysql.service|jq -r '.node.nodes|.[]|select(.key != "/services/'"${APP_NAME}"'_mysql.service/data") |.value')
#export DATABASE="jdbc:mysql://${ipport}/appdb?${credential}"
flyway migrate -url="$DATABASE" -locations=filesystem:`pwd`/dbmigration
flyway migrate -url="$DATABASE" -locations=filesystem:`pwd`/initmigration -table="init_version" -baselineOnMigrate=true -baselineVersion=0
java -jar app-standalone.jar
EOF
) > wrapper.sh

(cat << EOF
FROM hub.deepi.cn/java
RUN apk --update add tar bash
ENV ETCD_VERSION 2.1.2
RUN curl -jksSL https://github.com/coreos/etcd/releases/download/v\${ETCD_VERSION}/etcd-v\${ETCD_VERSION}-linux-amd64.tar.gz \
	|   tar -xzf - -C /usr/local/bin/ --strip-components=1 && \
	chmod +x /usr/local/bin/etcdctl
RUN curl -jksSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
	chmod +x /usr/local/bin/jq
ADD src/main/resources/db/migration dbmigration
ADD src/main/resources/db/init initmigration
RUN mkdir /usr/local/bin/flyway && \
    curl -jksSL https://bintray.com/artifact/download/business/maven/flyway-commandline-3.2.1-linux-x64.tar.gz \
    | tar -xzf - -C /usr/local/bin/flyway --strip-components=1
ENV PATH /usr/local/bin/flyway/:$PATH
ADD build/libs/app-standalone.jar app-standalone.jar
ADD wrapper.sh wrapper.sh
RUN chmod +x wrapper.sh
ENV APP_NAME $APP_NAME
EXPOSE 8088
ENTRYPOINT ["./wrapper.sh"]
EOF
) > Dockerfile

echo
puts_step "Building image ..."
docker build -t $IMAGE . &>process.log
puts_step "Building image $IMAGE complete "
echo
