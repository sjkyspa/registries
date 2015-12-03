FROM alpine:3.2
RUN apk --update add docker \
    rm -rf /var/cache/apk/*
ADD build.sh build.sh
RUN chmod +x build.sh
ENTRYPOINT ["./build.sh"]