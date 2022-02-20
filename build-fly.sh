docker build -t fly . -f Dockerfile-fly
docker create --name fly fly
docker export fly | gzip \
  > fly.tgz
tar -zxvf fly.tgz app/fly
mv ./app/fly ./fly
rm -rf ./app
rm fly.tgz
docker rm -v fly