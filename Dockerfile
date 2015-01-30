# nginx HTTP Server
#
# VERSION 0.0.1

FROM debian:wheezy

MAINTAINER Timo Derstappen, Marian Steinbach <marian@giantswarm.io>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -q && \
    apt-get -y -q install nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN rm -v /etc/nginx/nginx.conf
ADD ./nginx.conf /etc/nginx/
ADD ./htpasswd_admin /etc/nginx/
ADD ./run.sh /

ADD ./content /www

EXPOSE 80

CMD ["/run.sh"]
