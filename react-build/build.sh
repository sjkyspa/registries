#!/bin/sh
set -x
cd /tmp/repo/

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


puts_step "Staring install depends ..."
npm install &> install.log
if [ "$?" != "0" ]; then
  puts_red "install depends failed"
  cat install.log | puts_red_f
  exit 1
fi
npm install -g webpack &> webpack.log
if [ "$?" != "0" ]; then
  puts_red "install webpack failed"
  cat webpack.log | puts_red_f
  exit 1
fi
puts_step "Install depends complete"

puts_step "Start packing ..."
webpack
puts_step "Packing complete"

cat > run.sh << EOF
#!/bin/sh
sed -i -e "s#{{API_PREFIX}}#\$API_PREFIX#g" /usr/share/nginx/html/bundle.js
exec "\$@"
EOF

cat > Dockerfile << EOF
FROM hub.deepi.cn/nginx
EXPOSE 80
ADD run.sh run.sh
RUN chmod +x run.sh
ADD /dist /usr/share/nginx/html
ENTRYPOINT ["./run.sh"]
CMD ["nginx", "-g", "daemon off;"]
EOF

puts_step "Start building app image ..."
docker build -t $IMAGE /tmp/repo
puts_step "Building app image complete"
