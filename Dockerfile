# nginx HTTP Server
#
# VERSION 0.0.1

FROM ubuntu:14.04

MAINTAINER Timo Derstappen

RUN apt-get update -qq && apt-get -y -qq install nginx

RUN rm -v /etc/nginx/nginx.conf
ADD ./nginx.conf /etc/nginx/
ADD ./htpasswd /etc/nginx/
ADD ./run.sh /

ADD ./content /www

EXPOSE 80

CMD ["/run.sh"]
