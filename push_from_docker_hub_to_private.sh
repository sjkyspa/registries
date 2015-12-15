hub='hub.deepi.cn'
echo "push $1 to $hub"
docker pull $1 && docker tag $1 $hub/$1
docker push $hub/$1
