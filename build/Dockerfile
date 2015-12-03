FROM 10.21.1.214:5000/gradle
RUN apk --update add docker
ADD build.sh build.sh
RUN chmod a+x build.sh
ENTRYPOINT ["./build.sh"]