#!/bin/sh

sed -i "s/\%\%UPSTREAM_IP\%\%/${UPSTREAM_PORT_8000_TCP_ADDR}/" /etc/nginx/nginx.conf
sed -i "s/\%\%UPSTREAM_PORT\%\%/${UPSTREAM_PORT_8000_TCP_PORT}/" /etc/nginx/nginx.conf

nginx
