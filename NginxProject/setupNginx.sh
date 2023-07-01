#!/usr/bin/env bash

#set nginx web root directory RUN ONCE
sed -i '/.*set \$rtdir.*/c\set $rtdir '"$(pwd)"';' $(pwd)/nginx/conf/nginx.conf
