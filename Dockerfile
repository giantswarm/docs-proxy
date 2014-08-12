# Apache HTTP Server
#
# VERSION 0.0.1

FROM ubuntu:14.04

MAINTAINER Timo Derstappen

RUN apt-get update && apt-get -y install nginx

RUN rm -v /etc/nginx/nginx.conf
ADD ./nginx.conf /etc/nginx/
ADD ./htpasswd /etc/nginx/
ADD ./run.sh /

EXPOSE 80

CMD ["/run.sh"]
