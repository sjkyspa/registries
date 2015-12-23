FROM alpine:3.2
RUN apk add --update haproxy curl bash

RUN curl -sSL https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 -o /usr/bin/confd && \
    chmod +x /usr/bin/confd

ENTRYPOINT ["./entrypoint.sh"]
# clean up
RUN apk del curl && \
    rm -rf /var/cache/apk/*


EXPOSE 51000-65535

ADD confd /etc/confd
ADD entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh