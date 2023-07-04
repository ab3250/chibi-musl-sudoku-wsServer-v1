#!/usr/bin/env bash


sudo killall chibi-scheme > /dev/null 2>&1
sudo killall civetweb > /dev/null 2>&1
civetweb -document_root ./www -listening_ports 8000 &

/usr/bin/google-chrome-stable http://localhost:8000/index.html 2> /dev/null  &

LD_LIBRARY_PATH=$(pwd)/../lib CHIBI_MODULE_PATH="$(pwd)/../lib/chibi" CHIBI_IGNORE_SYSTEM_PATH=1 ../lib/chibi-scheme-static+ -Q -r main.scm &
