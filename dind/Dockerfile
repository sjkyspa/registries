FROM alpine:3.2
RUN apk --update add curl
ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.8.3
RUN curl -sSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION" -o /usr/bin/docker \
	&& chmod +x /usr/bin/docker