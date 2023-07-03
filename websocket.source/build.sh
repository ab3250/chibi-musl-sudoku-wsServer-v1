musl-gcc -c  -Iinclude  -DSEXP_USE_NTPGETTIME -DSEXP_USE_INTTYPES -Wall -g -g3 -O3  -fPIC -o base64.o base64.c
musl-gcc -c  -Iinclude  -DSEXP_USE_NTPGETTIME -DSEXP_USE_INTTYPES -Wall -g -g3 -O3  -fPIC -o handshake.o handshake.c
musl-gcc -c  -Iinclude  -DSEXP_USE_NTPGETTIME -DSEXP_USE_INTTYPES -Wall -g -g3 -O3  -fPIC -o sha1.o sha1.c
musl-gcc -c  -Iinclude  -DSEXP_USE_NTPGETTIME -DSEXP_USE_INTTYPES -Wall -g -g3 -O3  -fPIC -o utf8.o utf8.c
musl-gcc -c  -Iinclude  -DSEXP_USE_NTPGETTIME -DSEXP_USE_INTTYPES -Wall -g -g3 -O3  -fPIC -o ws.o ws.c
musl-gcc -c  -Iinclude  -DSEXP_USE_NTPGETTIME -DSEXP_USE_INTTYPES -Wall -g -g3 -O3  -fPIC -o chibized-websocket.o chibized-websocket.c
musl-gcc -fPIC -std=c99 -pedantic -pthread -shared -o websocket.so -pedantic chibized-websocket.o ws.o base64.o handshake.o sha1.o utf8.o

