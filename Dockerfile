FROM nginxinc/nginx-unprivileged:1.16-alpine

# remove default configuration
RUN rm -r /etc/nginx/conf.d

ADD ./nginx.conf /etc/nginx/
ADD ./htpasswd_admin /etc/nginx/
ADD ./content /www
