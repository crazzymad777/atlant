FROM debian:bookworm-slim

RUN apt-get update
RUN apt-get install -y openssl
RUN apt-get install -y file

COPY atlant /bin/atlant
WORKDIR /usr/share/atlant/html

# Labels
LABEL org.opencontainers.image.source "https://github.com/crazzymad777/atlant"
LABEL org.opencontainers.image.description "Static Web Server Atlant"
LABEL org.opencontainers.image.licenses "BSD-3-Clause-Clear"

ENTRYPOINT ["/bin/atlant"]
