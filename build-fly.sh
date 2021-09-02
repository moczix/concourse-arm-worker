rm -rf ./fly-build
mkdir ./fly-build

CONCOURSE_VERSION=v7.4.0

git clone --branch $CONCOURSE_VERSION https://github.com/concourse/concourse ./fly-build
cd ./fly-build
go build -ldflags '-extldflags "-static"' -o ./../fly ./fly
