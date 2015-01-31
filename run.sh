#!/bin/sh

echo "Environment variables for nginx:"
echo "DOCSMASTER_PORT_80_TCP_ADDR: ${DOCSMASTER_PORT_80_TCP_ADDR}"
echo "DOCSMASTER_PORT_80_TCP_PORT: ${DOCSMASTER_PORT_80_TCP_PORT}"
echo "DOCSSLAVE_PORT_80_TCP_ADDR: ${DOCSSLAVE_PORT_80_TCP_ADDR}"
echo "DOCSSLAVE_PORT_80_TCP_PORT: ${DOCSSLAVE_PORT_80_TCP_PORT}"
echo "SITESEARCH_PORT_9200_TCP_ADDR: ${SITESEARCH_PORT_9200_TCP_ADDR}"
echo "SITESEARCH_PORT_9200_TCP_PORT: ${SITESEARCH_PORT_9200_TCP_PORT}"

# set DOCS_MASTER ip/port in nginx conf
sed -i "s/\%\%DOCS_MASTER_IP\%\%/${DOCSMASTER_PORT_80_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%DOCS_MASTER_PORT\%\%/${DOCSMASTER_PORT_80_TCP_PORT}/" /etc/nginx/nginx.conf

# set DOCS_SLAVE ip/port in nginx conf
sed -i "s/\%\%DOCS_SLAVE_IP\%\%/${DOCSSLAVE_PORT_80_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%DOCS_SLAVE_PORT\%\%/${DOCSSLAVE_PORT_80_TCP_PORT}/" /etc/nginx/nginx.conf

# set SITESEARCH ip/port in nginx conf
sed -i "s/\%\%SITESEARCH_IP\%\%/${SITESEARCH_PORT_9200_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%SITESEARCH_PORT\%\%/${SITESEARCH_PORT_9200_TCP_PORT}/" /etc/nginx/nginx.conf

# debugging
#echo ""
#cat /etc/nginx/nginx.conf
#echo ""

exec nginx
