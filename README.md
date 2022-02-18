# concourse-arm-worker

```
./build.sh
```

Will build the docker registry-image resource, zip it and put it in the
right path. Will then build the main docker file which builds concourse
first and then uses the binaries in a fresh docker image.

While this does not cross-compile, it can be run on arm machines with docker.

# DONT UPDATE TO 7.6.0
`https://github.com/docker/for-mac/issues/6073#issuecomment-1013499602` 7.6.0 i used cgroups V2 so we get error on docker