#!/bin/sh
cd /tmp/repo/app
echo `pwd`
ls
mysql=$(docker run -d -p 3306:3306 -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=ke_tsu -e MYSQL_ROOT_PASSWORD=mysql 172.17.8.101:5000/mysql)
gradle fC fM
gradle test
gradle standaloneJar
cat > /tmp/repo/Dockerfile << EOF
FROM 172.17.8.101:5000/java:
ADD src/build/libs/ketsu-standalone.jar ketsu-standalone.jar
CMD ["java", "-jar", "ketsu-standalone.jar"]
EOF

docker build -t $IMAGE /tmp/repo
