FROM debian:bookworm-slim

RUN apt-get update
RUN apt-get install -y openssl
RUN apt-get install -y file

COPY atlant /bin/atlant
WORKDIR /usr/share/atlant/html

ENTRYPOINT ["/bin/atlant"]
