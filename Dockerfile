# Builder image
FROM golang:1.11-alpine3.8 as builder
MAINTAINER Tom Kirkpatrick <tkp@kirkdesigns.co.uk>

# Add build tools.
RUN apk --no-cache --virtual build-dependencies add \
	build-base \
	git

# Grab and install the latest version of lnd and all related dependencies.
WORKDIR $GOPATH/src/github.com/lightningnetwork/lnd
RUN git clone https://github.com/lightningnetwork/lnd . \
  && git reset --hard a8b2c093aafeea024570440efc7a96b149acea85 \
  && make \
  && make install \
  && cp /go/bin/lncli /bin/ \
  && cp /go/bin/lnd /bin/

# Grab and install the latest version of lndconnect.
WORKDIR $GOPATH/src/github.com/LN-Zap/lndconnect
RUN git clone https://github.com/LN-Zap/lndconnect . \
  && git reset --hard 7d5798e813763af4e5e39646d9acb899f0289bed \
  && make \
  && make install \
  && cp /go/bin/lndconnect /bin/

# Final image
FROM alpine:3.8 as final
MAINTAINER Tom Kirkpatrick <tkp@kirkdesigns.co.uk>

# Add utils.
RUN apk --no-cache add \
	bash \
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
