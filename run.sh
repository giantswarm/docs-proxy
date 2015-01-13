#!/bin/sh

echo "Environment variables for nginx:"
echo "MKDOCSMASTER_PORT_8000_TCP_ADDR: ${MKDOCSMASTER_PORT_8000_TCP_ADDR}"
echo "MKDOCSMASTER_PORT_8000_TCP_PORT: ${MKDOCSMASTER_PORT_8000_TCP_PORT}"
echo "MKDOCSSLAVE_PORT_8000_TCP_ADDR: ${MKDOCSSLAVE_PORT_8000_TCP_ADDR}"
echo "MKDOCSSLAVE_PORT_8000_TCP_PORT: ${MKDOCSSLAVE_PORT_8000_TCP_PORT}"
echo "SITESEARCH_PORT_9200_TCP_ADDR: ${SITESEARCH_PORT_9200_TCP_ADDR}"
echo "SITESEARCH_PORT_9200_TCP_PORT: ${SITESEARCH_PORT_9200_TCP_PORT}"

# set MKDOCSMASTER ip/port in nginx conf
sed -i "s/\%\%MKDOCSMASTER_IP\%\%/${MKDOCSMASTER_PORT_8000_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%MKDOCSMASTER_PORT\%\%/${MKDOCSMASTER_PORT_8000_TCP_PORT}/" /etc/nginx/nginx.conf

# set MKDOCSSLAVE ip/port in nginx conf
sed -i "s/\%\%MKDOCSSLAVE_IP\%\%/${MKDOCSSLAVE_PORT_8000_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%MKDOCSSLAVE_PORT\%\%/${MKDOCSSLAVE_PORT_8000_TCP_PORT}/" /etc/nginx/nginx.conf

# set SITESEARCH ip/port in nginx conf
sed -i "s/\%\%SITESEARCH_IP\%\%/${SITESEARCH_PORT_9200_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%SITESEARCH_PORT\%\%/${SITESEARCH_PORT_9200_TCP_PORT}/" /etc/nginx/nginx.conf

# debugging
#echo ""
#cat /etc/nginx/nginx.conf
#echo ""

exec nginx
