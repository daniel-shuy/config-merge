FROM golang:alpine as build

ARG TARGETPLATFORM

RUN apk add --update git

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      export GOARCH=amd64; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      export GOARCH=arm64; \
    else \
      echo "Unsupported TARGETPLATFORM: $TARGETPLATFORM"; \
      exit 1; \
    fi && \
    env GOOS=linux GOARCH=$GOARCH CGO_ENABLED=0 go install github.com/a8m/envsubst/cmd/envsubst@latest


FROM node:18-alpine

COPY --from=build /go/bin/envsubst /usr/local/bin/envsubst

COPY config-merge.js source.sh package.json wrapper.sh /usr/local/config-merge/
RUN cd /usr/local/config-merge \
    && yarn install \
    && ln -s /usr/local/config-merge/wrapper.sh /usr/local/bin/config-merge

WORKDIR /home/node
USER node:node
ENTRYPOINT ["config-merge"]
