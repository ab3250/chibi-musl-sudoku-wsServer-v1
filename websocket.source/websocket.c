
#include <chibi/eval.h>
#include "stdio.h"
#include "stdbool.h"
#include "stdlib.h"
#include "stdio.h"
#include "unistd.h"
#include "ws.h"

static sexp ctx2;

void onopen(int fd)
{ 
 sexp ctx = ctx2;
 sexp_gc_var1(cmd); 
 sexp_gc_preserve1(ctx,cmd);
 cmd = sexp_list2(ctx, sexp_intern(ctx, "onopen", -1),sexp_make_integer(ctx, fd));
 sexp_eval(ctx, cmd, NULL);
 sexp_gc_release1(ctx);
}

void onclose(int fd)
{
 sexp ctx = ctx2;
 sexp_gc_var1(cmd); 
 sexp_gc_preserve1(ctx,cmd);
 cmd = sexp_list2(ctx, sexp_intern(ctx, "onclose", -1),sexp_make_integer(ctx, fd));
 sexp_eval(ctx, cmd, NULL);
 sexp_gc_release1(ctx); 
}

void onmessage(int fd, const unsigned char *msg, uint64_t size, int type)
{  
 sexp ctx = ctx2;
 sexp_gc_var1(cmd); 
 sexp_gc_preserve1(ctx,cmd);
 cmd = sexp_list3(ctx,sexp_c_string(ctx, msg, -1),
        sexp_make_integer(ctx, size),sexp_make_integer(ctx, type));
 cmd = sexp_cons(ctx,sexp_make_integer(ctx, fd), cmd);
 cmd = sexp_cons(ctx,sexp_intern(ctx, "onmessage", -1),cmd); 
 sexp_eval(ctx, cmd, NULL);
 sexp_gc_release1(ctx);   
}

int ws_start(void)
{
 sexp ctx = ctx2;
 struct ws_events evs;
 evs.onopen    = &onopen;
 evs.onclose   = &onclose;
 evs.onmessage = &onmessage;
 usleep(500000);
 setbuf(stdout, NULL); 
 printf("Server Initialized!\n");  
 ws_socket(&evs, 8000, 0); 

 	
}
 
