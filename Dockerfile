# nginx HTTP Server
#

FROM nginx:stable-alpine

# remove default configuration
RUN rm -r /etc/nginx/conf.d

ADD ./nginx.conf /etc/nginx/
ADD ./htpasswd_admin /etc/nginx/
ADD ./content /www
