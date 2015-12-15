hub='hub.deepi.cn'
echo "build $1"
docker build -t $1 $1
docker tag $1 $hub/$1
echo "push $1 to $hub"
docker push $hub/$1
