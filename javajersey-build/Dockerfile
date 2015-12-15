FROM hub.deepi.cn/gradle
RUN apk --update add docker
ADD build.sh build.sh
RUN chmod a+x build.sh
RUN curl -jksSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
	chmod +x /usr/local/bin/jq
ENTRYPOINT ["./build.sh"]
