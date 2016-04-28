FROM alpine:3.3

ENTRYPOINT ["./build.sh"]

RUN apk update && apk upgrade && apk --update add \
    ruby ruby-irb ruby-rake ruby-io-console ruby-bigdecimal \
    libstdc++ tzdata bash curl

ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.9.1
RUN curl -sjkSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-$DOCKER_VERSION" -o /usr/bin/docker \
	&& chmod +x /usr/bin/docker

RUN curl -jksSL https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq && \
    chmod +x /usr/local/bin/jq

RUN echo 'gem: --no-rdoc --no-ri' > /etc/gemrc
RUN gem install bundler \
    && rm -r /root/.gem \
    && find / -name '*.gem' | xargs rm

RUN apk --update add --virtual build-dependencies build-base ruby-dev openssl-dev \
    libxml2-dev libxslt-dev \
    libc-dev linux-headers

RUN gem install -N nokogiri -- --use-system-libraries
    # cleanup and settings
RUN bundle config --global build.nokogiri  "--use-system-libraries" && \
    bundle config --global build.nokogumbo "--use-system-libraries" && \
    find / -type f -iname \*.apk-new -delete && \
    rm -rf /var/cache/apk/* && \
    rm -rf /usr/lib/lib/ruby/gems/*/cache/* && \
    rm -rf ~/.gem

ADD build.sh build.sh
RUN chmod a+x build.sh
