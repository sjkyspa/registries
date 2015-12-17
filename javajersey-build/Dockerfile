FROM hub.deepi.cn/gradle

ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.8.3
RUN curl -sSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION" -o /usr/bin/docker \
	&& chmod +x /usr/bin/docker

ADD build.sh build.sh
RUN chmod a+x build.sh
RUN curl -jksSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
	chmod +x /usr/local/bin/jq
ENTRYPOINT ["./build.sh"]
