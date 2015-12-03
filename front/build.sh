#!/bin/sh
cd /tmp/repo/
npm install
npm install -g webpack
webpack

cat > run.sh << EOF
sed -i -e "s#{{API_PREFIX}}#\$API_PREFIX#g" /usr/share/nginx/html/bundle.js
exec "$@"
EOF

cat > Dockerfile << EOF
FROM 10.21.1.214:5000/nginx
EXPOSE 80
ADD run.sh run.sh
RUN chmod +x run.sh
ADD /dist /usr/share/nginx/html
ENTRYPOINT ["./run.sh"]
EOF

docker build -t $IMAGE /tmp/repo
