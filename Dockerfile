# Builder image
FROM golang:1.10-alpine3.8 as builder
MAINTAINER Tom Kirkpatrick <tkp@kirkdesigns.co.uk>

# Add build tools.
RUN apk --no-cache --virtual build-dependencies add \
	build-base \
	git

WORKDIR $GOPATH/src/github.com/lightningnetwork/lnd

# Grab and install the latest version of lnd and all related dependencies.
RUN git clone https://github.com/lightningnetwork/lnd . \
  && git reset --hard 4f43c1c9434f2f1186abfe5a8ccb6de688426e1e \
  && make \
  && make install \
  && cp /go/bin/lncli /bin/ \
  && cp /go/bin/lnd /bin/

# Install zapconnect
RUN go get -d github.com/LN-Zap/zapconnect
WORKDIR $GOPATH/src/github.com/LN-Zap/zapconnect
RUN make

# Final image
FROM alpine:3.8 as final
MAINTAINER Tom Kirkpatrick <tkp@kirkdesigns.co.uk>

# Add utils.
RUN apk --no-cache add \
	bash \
	su-exec \
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
COPY --from=builder /go/bin/zapconnect /bin/

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
