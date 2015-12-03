#!/bin/sh
cd /tmp/repo/
npm install
npm install -g webpack
webpack
cat > Dockerfile << EOF
FROM nginx
EXPOSE 8080
ADD /dists /usr/share/nginx/html
EOF

docker build -t $IMAGE /tmp/repo
