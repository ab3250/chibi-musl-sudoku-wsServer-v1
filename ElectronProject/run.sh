#!/usr/bin/env bash
sudo killall chibi-scheme > /dev/null 2>&1
sudo killall electron > /dev/null 2>&1
./node_modules/electron/dist/electron . 2>&1 &
disown
sleep 1
LD_LIBRARY_PATH=$(pwd)/../lib CHIBI_MODULE_PATH="$(pwd)/../lib/chibi" CHIBI_IGNORE_SYSTEM_PATH=1 ../lib/chibi-scheme -r main.scm &
disown
exit
exit
