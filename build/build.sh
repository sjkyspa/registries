#!/bin/sh
cd /tmp/repo/app
echo `pwd`
ls
gradle test
gradle standaloneJar
cat > /tmp/repo/Dockerfile << EOF
FROM 172.17.8.101:5000/java:
ADD src/build/libs/ketsu-standalone.jar ketsu-standalone.jar
CMD ["java", "-jar", "ketsu-standalone.jar"]
EOF

docker build -t $IMAGE /tmp/repo
