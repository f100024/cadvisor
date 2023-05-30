# Builder
FROM golang:1.20.4-bullseye as builder

RUN apt-get update && apt-get install -y git dmsetup && apt-get clean

COPY . /go/src/github.com/google/cadvisor
WORKDIR /go/src/github.com/google/cadvisor

RUN make build

# Image for usage
FROM alpine:3.18 as main

COPY --from=builder /go/src/github.com/google/cadvisor/_output/cadvisor /usr/bin/cadvisor

EXPOSE 8080
ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]