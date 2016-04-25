#!/bin/bash

set -eo pipefail

puts_red() {
    echo $'\033[0;31m'"      $@" $'\033[0m'
}

puts_red_f() {
  while read data; do
    echo $'\033[0;31m'"      $data" $'\033[0m'
  done
}

puts_green() {
  echo $'\033[0;32m'"      $@" $'\033[0m'
}

puts_step() {
  echo $'\033[0;34m'" -----> $@" $'\033[0m'
}

on_exit() {
    last_status=$?
    if [ "$last_status" != "0" ]; then
        if [ -f "process.log" ]; then
          cat process.log|puts_red_f
        fi

        if [ -n "$MONGO_CONTAINER" ]; then
            echo
            puts_step "Cleaning ..."
            docker stop $MONGO_CONTAINER &>process.log && docker rm $MONGO_CONTAINER &>process.log
            puts_step "Cleaning complete"
            echo
        fi
        exit 1;
    else
        if [ -n "$MONGO_CONTAINER" ]; then
            echo
            puts_step "Cleaning ..."
            docker stop $MONGO_CONTAINER &>process.log && docker rm $MONGO_CONTAINER &>process.log
            puts_step "Cleaning complete"
            echo
        fi
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

CODEBASE_DIR=$CODEBASE
HOST_IP=$(ip route|awk '/default/ { print $3 }')

export MONGO_USERNAME=admin
export MONGO_PASSWORD=mongo
export MONGO_NAME=testdb

echo
puts_step "Launching baking services ..."
MONGO_CONTAINER=$(docker run -d -P -e MONGODB_PASS=$MONGO_PASSWORD -e MONGODB_USER=$MONGO_USERNAME -e MONGODB_DATABASE=$MONGO_NAME tutum/mongodb)
MONGO_PORT=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "27017/tcp") 0).HostPort}}' ${MONGO_CONTAINER})
until docker exec $MONGO_CONTAINER mongo $MONGO_NAME --host 127.0.0.1 --port 27017 -u $MONGO_USERNAME -p $MONGO_PASSWORD --eval "ls()" &>/dev/null ; do
    echo "...."
    sleep 1
done

export MONGO_HOST=$HOST_IP
export MONGO_PORT=$MONGO_PORT

puts_step "Complete Launching baking services"
echo

cd $CODEBASE_DIR

echo
puts_step "Install dependencies ..."
gem install -N nokogiri -- --use-system-libraries
# cleanup and settings
bundle config --global build.nokogiri  "--use-system-libraries" && \
bundle config --global build.nokogumbo "--use-system-libraries" && \
  find / -type f -iname \*.apk-new -delete && \
  rm -rf /var/cache/apk/* && \
  rm -rf /usr/lib/lib/ruby/gems/*/cache/* && \
  rm -rf ~/.gem
bundle install --without development production
echo

echo
puts_step "Start test ..."
bundle exec rspec
puts_step "Test complete"
echo

(cat << EOF
FROM hub.deepi.cn/synapse:0.1

RUN apk update && apk upgrade && apk --update add \
    ruby ruby-irb ruby-rake ruby-io-console ruby-bigdecimal \
    libstdc++ tzdata bash

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

ADD . /app

RUN cd /app && bundle install --without development test

ENV RAILS_ENV production
WORKDIR /app

CMD ["bundle", "exec", "unicorn", "-p", "8080", "-c", "./config/unicorn.rb"]

EOF
) > Dockerfile

echo
puts_step "Building image $IMAGE ..."
docker build -q -t $IMAGE . &>process.log
puts_step "Building image $IMAGE complete "
echo
