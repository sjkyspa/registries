FROM mhart/alpine-node
RUN apk update \
    && apk add docker python make g++ \
    && rm -rf /var/cache/apk/*

ADD build.sh build.sh
RUN chmod +x build.sh
ENTRYPOINT ["./build.sh"]
