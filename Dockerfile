# nginx HTTP Server
#
# VERSION 0.0.1

FROM debian:wheezy

MAINTAINER Timo Derstappen, Marian Steinbach <marian@giantswarm.io>

ENV DEBIAN_FRONTEND noninteractive

# configure apt
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ wheezy nginx" >> /etc/apt/sources.list

ENV NGINX_VERSION 1.7.9-1~wheezy

RUN apt-get update -q && \
    apt-get -y -q --no-install-recommends install nginx=${NGINX_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN rm -v /etc/nginx/nginx.conf
ADD ./nginx.conf /etc/nginx/
ADD ./htpasswd_admin /etc/nginx/
ADD ./run.sh /

ADD ./content /www

EXPOSE 80

CMD ["/run.sh"]
