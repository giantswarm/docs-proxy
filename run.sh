#!/bin/sh

echo "Environment variables for nginx:"
echo "UPSTREAM_PORT_8000_TCP_ADDR: ${UPSTREAM_PORT_8000_TCP_ADDR}"
echo "UPSTREAM_PORT_8000_TCP_PORT: ${UPSTREAM_PORT_8000_TCP_PORT}"
echo "SITESEARCH_PORT_9200_TCP_ADDR: ${SITESEARCH_PORT_9200_TCP_ADDR}"
echo "SITESEARCH_PORT_9200_TCP_PORT: ${SITESEARCH_PORT_9200_TCP_PORT}"

# set UPSTREAM ip/port in nginx conf
sed -i "s/\%\%UPSTREAM_IP\%\%/${UPSTREAM_PORT_8000_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%UPSTREAM_PORT\%\%/${UPSTREAM_PORT_8000_TCP_PORT}/" /etc/nginx/nginx.conf

# set SITESEARCH ip/port in nginx conf
sed -i "s/\%\%SITESEARCH_IP\%\%/${SITESEARCH_PORT_9200_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%SITESEARCH_PORT\%\%/${SITESEARCH_PORT_9200_TCP_PORT}/" /etc/nginx/nginx.conf

# debugging
#echo ""
#cat /etc/nginx/nginx.conf
#echo ""

exec nginx
