FROM alpine:edge

ENV PROXYCHAINS_CONF=/etc/proxychains.conf \
    TOR_CONF=/etc/torrc.default \
    TOR_LOG_DIR=/var/log/s6/tor \
    DNSMASQ_CONF=/etc/dnsmasq.conf \
    DNSMASQ_LOG_DIR=/var/log/s6/dnsmasq

RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> \
      /etc/apk/repositories && \
    echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> \
      /etc/apk/repositories && \
    apk --no-cache add --update \
      dnsmasq \
      openssl \
      proxychains-ng \
      s6 \
      curl \
      nmap \
      nmap-scripts \
      nmap-doc \
      nmap-nping \
      nmap-ncat \
      tor@edge && \
    rm -rf /var/cache/apk/*

COPY etc /etc/
COPY run.sh bin /custom/bin/

RUN chmod +x /custom/bin/* && \
    mkdir -p "$TOR_LOG_DIR" "$DNSMASQ_LOG_DIR" && \
    chown tor $TOR_CONF && \
    chmod 0644 $PROXYCHAINS_CONF && \
    chmod 0755 \
      /etc/s6/*/log/run \
      /etc/s6/*/run

ENV PATH="/custom/bin:${PATH}"
ENTRYPOINT ["/custom/bin/run.sh"]
