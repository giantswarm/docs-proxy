FROM gsoci.azurecr.io/giantswarm/nginx:1.31.9-alpine

USER 0

# remove default configuration
RUN rm -r /etc/nginx/conf.d && chmod 1777 /var/cache/nginx

ADD ./nginx.conf /etc/nginx/
ADD ./search.js /etc/nginx/
ADD ./content /www

USER 101

EXPOSE 8000
