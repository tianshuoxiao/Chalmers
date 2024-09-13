# Build
FROM alpine:3.17 as builder
RUN apk update && \
    apk --no-cache add \
        ca-certificates \
        cmake \
        g++ \
        make \
        linux-headers
RUN apk add libcluon --no-cache --repository \
      https://chrberger.github.io/libcluon/alpine/v3.13 --allow-untrusted
ADD . /opt/sources
WORKDIR /opt/sources
RUN mkdir /tmp/build && cd /tmp/build && \
    cmake /opt/sources && \
    make && cp opendlv-logic-tianshuo /tmp

# Deploy
FROM alpine:3.17
RUN apk update && \
    apk --no-cache add \
        libstdc++
COPY --from=builder /tmp/opendlv-logic-tianshuo /usr/bin
CMD ["/usr/bin/opendlv-logic-tianshuo"]
