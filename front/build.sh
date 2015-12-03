#!/bin/sh
cd /tmp/repo/
npm install
npm install -g webpack
webpack
cat > Dockerfile << EOF
FROM 10.21.1.214:5000/nginx
EXPOSE 80
ADD /dist /usr/share/nginx/html
EOF

docker build -t $IMAGE /tmp/repo
