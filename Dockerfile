# Builder image
FROM golang:1.13-alpine3.10 as builder
MAINTAINER Tom Kirkpatrick <tkp@kirkdesigns.co.uk>

# Add build tools.
RUN apk --no-cache --virtual build-dependencies add \
  build-base \
  git

# Grab and install the latest version of lnd and all related dependencies.
WORKDIR $GOPATH/src/github.com/lightningnetwork/lnd
RUN git config --global user.email "tkp@kirkdesigns.co.uk" \
  && git config --global user.name "Tom Kirkpatrick" \
  && git clone https://github.com/lightningnetwork/lnd . \
  && git reset --hard v0.8.1-beta \
  && make \
  && make install tags="experimental monitoring autopilotrpc chainrpc invoicesrpc routerrpc signrpc walletrpc watchtowerrpc wtclientrpc" \
  && cp /go/bin/lncli /bin/ \
  && cp /go/bin/lnd /bin/

# Grab and install the latest version of lndconnect.
WORKDIR $GOPATH/src/github.com/LN-Zap/lndconnect
RUN git clone https://github.com/LN-Zap/lndconnect . \
  && git reset --hard b20ee064b02307f74782f9d84169bb4a4a8d3a10 \
  && make \
  && make install \
  && cp /go/bin/lndconnect /bin/

# Final image
FROM alpine:3.10 as final
MAINTAINER Tom Kirkpatrick <tkp@kirkdesigns.co.uk>

# Add utils.
RUN apk --no-cache add \
  bash \
  curl \
  su-exec \
  dropbear-dbclient \
  dropbear-scp \
  ca-certificates \
  && update-ca-certificates

ARG USER_ID
ARG GROUP_ID

ENV HOME /lnd

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -g ${GROUP_ID} -S lnd && \
  adduser -u ${USER_ID} -S lnd -G lnd -s /bin/bash -h /lnd lnd

# Copy the compiled binaries from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/
COPY --from=builder /go/bin/lndconnect /bin/

## Set BUILD_VER build arg to break the cache here.
ARG BUILD_VER=unknown

ADD ./bin /usr/local/bin

VOLUME ["/lnd"]

# Expose p2p port
EXPOSE 9735

# Expose grpc port
EXPOSE 10009

WORKDIR /lnd

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["lnd_oneshot"]
