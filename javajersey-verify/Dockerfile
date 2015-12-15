FROM hub.deepi.cn/gradle
RUN apk --update add curl bash git
RUN curl -jksSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
	chmod +x /usr/local/bin/jq
WORKDIR /home
ADD verify.sh verify.sh
RUN chmod a+x verify.sh
ENTRYPOINT ["./verify.sh"]
