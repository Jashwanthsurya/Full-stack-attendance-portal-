FROM alpine:latest

RUN apk add --no-cache jq

RUN mkdir -p /data

COPY data/ /data/

RUN chmod 755 /data
RUN chmod 644 /data/*.json

VOLUME ["/data"]

CMD ["tail", "-f", "/dev/null"]