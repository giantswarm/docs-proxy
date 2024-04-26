FROM gsoci.azurecr.io/giantswarm/nginx-unprivileged:1.26-alpine

USER 0

# remove default configuration
RUN rm -r /etc/nginx/conf.d

ADD ./nginx.conf /etc/nginx/
ADD ./content /www

USER 101

EXPOSE 8000
