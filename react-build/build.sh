#!/bin/sh
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

        exit 1;
    else
        if [ -n "$MYSQL_CONTAINER" ]; then
            echo
            puts_step "Cleaning ..."
            docker stop $MYSQL_CONTAINER &>process.log && docker rm $MYSQL_CONTAINER &>process.log
            puts_step "Cleaning complete"
            echo
        fi
        puts_green "build success"
        exit 0;
    fi
}

trap on_exit HUP INT TERM QUIT ABRT EXIT

CODEBASE_DIR=$CODEBASE

cd $CODEBASE_DIR

puts_step "Staring install depends ..."
npm install
if [ "$?" != "0" ]; then
  puts_red "install depends failed"
#  cat install.log | puts_red_f
  exit 1
fi
npm install -g webpack
if [ "$?" != "0" ]; then
  puts_red "install webpack failed"
#  cat webpack.log | puts_red_f
  exit 1
fi
puts_step "Install depends complete"

puts_step "Start packing ..."
webpack
puts_step "Packing complete"

cat > run.sh << EOF
#!/bin/sh
cp -rf /dist /usr/share/nginx/html
sed -i -e "s#{{API_PREFIX}}#\$API_PREFIX#g" /usr/share/nginx/html/bundle.js
exec "\$@"
EOF

cat > Dockerfile << EOF
FROM hub.deepi.cn/nginx
EXPOSE 80
ADD run.sh run.sh
RUN chmod +x run.sh
ADD /dist /dist
ENTRYPOINT ["./run.sh"]
CMD ["nginx", "-g", "daemon off;"]
EOF

puts_step "Start building app image ..."
docker build -t $IMAGE .
puts_step "Building image $IMAGE complete"
