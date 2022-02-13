FROM golang:1.17.7-alpine3.15 as builder
ENV CONCOURSE_VERSION=v7.6.0
ENV GUARDIAN_COMMIT=d96eedb991176293ccaa2dbff331f33601fc1c10
ENV CNI_PLUGINS_VERSION=v1.0.1
RUN apk add gcc git g++ musl


RUN git clone --branch $CONCOURSE_VERSION https://github.com/concourse/concourse /go/concourse
WORKDIR /go/concourse
RUN rm versions.go
COPY ./versions.go .
RUN go build -ldflags "-extldflags '-static'" ./cmd/concourse

RUN gcc -O2 -static -o /go/concourse/init ./cmd/init/init.c

RUN git clone --branch $CNI_PLUGINS_VERSION https://github.com/containernetworking/plugins.git /go/plugins
WORKDIR /go/plugins
RUN apk add bash
ENV CGO_ENABLED=0
RUN ./build_linux.sh

FROM ubuntu:impish as ubuntu
COPY --from=0 /go/concourse/concourse /usr/local/concourse/bin/
COPY --from=0 /go/concourse/init /usr/local/concourse/bin/
#COPY --from=0 /go/guardian/cmd/init/init /usr/local/concourse/bin/
COPY --from=0 /go/plugins/bin/* /usr/local/concourse/bin/
# add resource-types
COPY resource-types /usr/local/concourse/resource-types

RUN apt-get update
RUN apt install -y gcc git g++ musl wget

RUN wget https://golang.org/dl/go1.17.7.linux-arm64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.7.linux-arm64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin


RUN git clone https://github.com/moczix/guardian /go/guardian
WORKDIR /go/guardian
RUN git checkout $GUARDIAN_COMMIT
RUN go build -ldflags "-extldflags '-static'" -mod=vendor -o gdn ./cmd/gdn
WORKDIR /go/guardian/cmd/init
RUN gcc -static -o init init.c ignore_sigchild.c

#COPY /go/guardian/cmd/init/init /usr/local/concourse/bin/

# auto-wire work dir for 'worker' and 'quickstart'
ENV CONCOURSE_WORK_DIR                /worker-state
ENV CONCOURSE_WORKER_WORK_DIR         /worker-state
ENV CONCOURSE_GARDEN_BIN /go/guardian/gdn

# volume for non-aufs/etc. mount for baggageclaim's driver
VOLUME /worker-state

RUN apt-get update && apt-get install -y \
    ca-certificates \
    iptables \
    dumb-init \
    iproute2 \
    btrfs-progs \
    file \
    git \
    build-essential \
    unzip \
    libbtrfs-dev \
    pkg-config \
    seccomp \
    libseccomp-dev \
    containerd \
    runc

WORKDIR /concourse/js
COPY ./web/public .
RUN ls -ls

ENV CONCOURSE_WEB_PUBLIC_DIR=/concourse/js

STOPSIGNAL SIGUSR2

ADD https://raw.githubusercontent.com/concourse/concourse-docker/348721737346643958d17f837be27aff9a157035/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["dumb-init", "/usr/local/bin/entrypoint.sh"]
