#!/bin/sh
cd /tmp/repo/app
mysql=$(docker run -d -P -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=ke_tsu -e MYSQL_ROOT_PASSWORD=mysql 10.21.1.214:5000/mysql)
if [ $? -ne 0 ]; then
    exit 1
fi
mysql_port=$(docker inspect ${mysql}|jq -r '.[0].NetworkSettings.Ports|to_entries[]|.value[0].HostPort')
export DATABASE="jdbc:mysql://$HOST:$mysql_port/ke_tsu?user=mysql&password=mysql"
gradle fC fM
gradle test -i
gradle standaloneJar

(cat  <<'EOF'
#!/bin/sh
host_ip=$(ip route|awk '/default/ { print $3 }')
mysql_exists_code=$(curl -sL http://${host_ip}:4001/v2/keys/services/${APP_NAME}_mysql.service/data|jq -r ".errorCode")
if [ "$mysql_exists_code" == "" ] ; then
        echo "etcd not started"
        exit 1
fi

if [ "$mysql_exists_code" == "100" -o "$mysql_exists_code" == "null" ] ; then
echo "launch backend service"
cat >mysql.json <<EOFINNER
{
  "desiredState": "launched",
  "options": [
    {
      "section": "Service",
      "name": "ExecStartPre",
      "value": "/bin/sh -c \"etcdctl set /services/%n/data 'user=mysql&password=mysql'\""
    },
    {
      "section": "Service",
      "name": "ExecStartPre",
      "value": "/bin/sh -c \"docker inspect %n >/dev/null 2>&1 && docker rm -f %n || true\""
    },
    {
      "section": "Service",
      "name": "ExecStart",
      "value": "/bin/sh -c \"docker run --name %n --rm -v /var/run/docker.sock:/var/run/docker.sock -e MYSQL_ROOT_PASSWORD=mysql -e MYSQL_USER=mysql -e SERVICE_NAME=%n -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=mysql -P  mysql\""
    },
    {
      "section": "Service",
      "name": "ExecStop",
      "value": "/usr/bin/docker stop %n"
    },
    {
      "section": "Service",
      "name": "Restart",
      "value": "on-failure"
    }
  ]
}
EOFINNER
curl -X PUT -H "Content-Type:application/json" http://${host_ip}:49153/v1-alpha/units/${APP_NAME}_mysql.service -d @mysql.json
sleep 20
fi

echo "find backend service"
credential=$(curl -sL http://${host_ip}:4001/v2/keys/services/${APP_NAME}_mysql.service/data|jq -r '.node.value')
ipport=$(curl -sL http://${host_ip}:4001/v2/keys/services/${APP_NAME}_mysql.service|jq -r '.node.nodes|.[]|select(.key != "/services/'"${APP_NAME}"'_mysql.service/data") |.value')
export DATABASE="jdbc:mysql://${ipport}/mysql?${credential}"
java -cp "/config:ketsu-standalone.jar" com.tw.Main
EOF
) > wrapper.sh

cat > /tmp/repo/app/Dockerfile << EOF
FROM 10.21.1.214:5000/java
RUN apk --update add tar
ENV ETCD_VERSION 2.1.2
RUN curl -jksSL https://github.com/coreos/etcd/releases/download/v\${ETCD_VERSION}/etcd-v\${ETCD_VERSION}-linux-amd64.tar.gz \
	|   tar -xzf - -C /usr/local/bin/ --strip-components=1 && \
	chmod +x /usr/local/bin/etcdctl
RUN curl -jksSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
	chmod +x /usr/local/bin/jq
ADD build/libs/ketsu-standalone.jar ketsu-standalone.jar
ADD wrapper.sh wrapper.sh
RUN chmod +x wrapper.sh
ENV APP_NAME $APP_NAME
EXPOSE 8088
ENTRYPOINT ["./wrapper.sh"]
EOF

docker build -t $IMAGE /tmp/repo/app
docker stop $mysql && docker rm $mysql
