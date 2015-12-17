FROM mhart/alpine-node

ENTRYPOINT ["./build.sh"]

ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.8.3
RUN curl -sSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION" -o /usr/bin/docker \
	&& chmod +x /usr/bin/docker

RUN apk update \
    && apk add python make g++ \
    && rm -rf /var/cache/apk/*

ADD build.sh build.sh
RUN chmod +x build.sh