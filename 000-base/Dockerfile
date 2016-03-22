FROM gliderlabs/alpine:3.3

RUN apk add --update haproxy curl bash

ENV CONSUL_TEMPLATE_VERSION "0.12.1"
ENV CONSUL_TEMPLATE_PKG "consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip"
RUN curl -sSL https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/${CONSUL_TEMPLATE_PKG} -O \
    && unzip ${CONSUL_TEMPLATE_PKG} -d /bin \
    && rm -rf ${CONSUL_TEMPLATE_PKG}

# clean up
RUN rm -rf /var/cache/apk/*

COPY rootfs /
RUN curl -sSL https://github.com/just-containers/s6-overlay/releases/download/v1.17.1.1/s6-overlay-amd64.tar.gz \
        | tar -xzf - -C /

ENTRYPOINT ["/init"]
CMD []