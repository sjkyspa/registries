FROM hub.deepi.cn/dind
RUN apk --update add curl bash

ADD confd /app/confd
ADD Dockerfile /app/Dockerfile
ADD test/run-test.sh /app/run-test.sh
WORKDIR /app

CMD ["/app/run-test.sh"]