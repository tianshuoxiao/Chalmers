# Build
FROM ubuntu:22.04 as builder

RUN apt-get update 
RUN apt-get install -y build-essential cmake software-properties-common
RUN add-apt-repository -y ppa:chrberger/libcluon
RUN apt-get update
RUN apt-get install libcluon

ADD . /opt/sources
WORKDIR /opt/sources

RUN mkdir /tmp/build && cd /tmp/build && \
    cmake /opt/sources && \
    make && make test && cp helloworld /tmp

# Deploy
FROM ubuntu:22.04
WORKDIR /opt/sources
COPY --from=builder /tmp/helloworld /usr/bin
CMD ["/usr/bin/helloworld"]

