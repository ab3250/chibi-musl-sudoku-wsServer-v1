#!/usr/bin/env bash


	sudo killall chibi-scheme > /dev/null 2>&1
# 	sudo killall civetweb > /dev/null 2>&1
# 	civetweb -document_root ./www -listening_ports 8000 &


	sudo killall nginx > /dev/null 2>&1
	#set nginx web root directory
	sed -i '/.*set \$rtdir.*/c\set $rtdir '"$(pwd)"';' $(pwd)/nginx/conf/nginx.conf
	sudo $(pwd)/nginx/sbin/nginx -c $(pwd)/nginx/conf/nginx.conf


/usr/bin/google-chrome-stable http://localhost:8000/www/index.html 2> /dev/null  &

LD_LIBRARY_PATH=$(pwd)/../lib CHIBI_MODULE_PATH="$(pwd)/../lib/chibi" CHIBI_IGNORE_SYSTEM_PATH=1 ../lib/chibi-scheme -r main.scm &
