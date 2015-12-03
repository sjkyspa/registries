#!/bin/sh
cd /tmp/repo/app
mysql=$(docker run -d -p 3306:3306 -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=ke_tsu -e MYSQL_ROOT_PASSWORD=mysql 10.21.1.214:5000/mysql)
if [ $? -ne 0 ]; then
    exit 1
fi
export DATABASE="jdbc:mysql://$HOST:3306/ke_tsu?user=mysql&password=mysql"
gradle fC fM

echo "db.url=jdbc:mysql://$HOST:3306/ke_tsu?user=mysql&password=mysql">src/test/resources/db.properties
echo "db.username=mysql">>src/test/resources/db.properties
echo "db.password=mysql">>src/test/resources/db.properties

gradle test -i
gradle standaloneJar

cat > /tmp/repo/app/wrapper.sh << EOF
#!/bin/sh
mkdir /config
echo "db.url=\${DATABASE}">/config/db.properties
echo "db.username=mysql">>/config/db.properties
echo "db.password=mysql">>/config/db.properties
java -cp "/config:ketsu-standalone.jar" com.tw.Main
EOF

cat > /tmp/repo/app/Dockerfile << EOF
FROM 10.21.1.214:5000/java
ADD build/libs/ketsu-standalone.jar ketsu-standalone.jar
ADD wrapper.sh wrapper.sh
RUN chmod +x wrapper.sh
EXPOSE 8088
ENTRYPOINT ["./wrapper.sh"]
EOF

docker build -t $IMAGE /tmp/repo/app
docker stop $mysql && docker rm $mysql