// 15nov19 Software Lab. Alexander Burger

#include "pico.h"

// I/O
void stderrMsg(char *s, int64_t n) {
   fprintf(stderr, "%s %lX\n", s, n);
}

char *strErrno(void) {
   return strerror(errno);
}

int32_t openRdonly(char *nm) {
   return open(nm, O_RDONLY);
}

int32_t openAppend(char *nm) {
   return open(nm, O_APPEND|O_CREAT|O_RDWR, 0666);
}

int32_t fcntlCloExec(int32_t fd) {
   return fcntl(fd, F_SETFD, FD_CLOEXEC);
}

int32_t fcntlSetFl(int32_t fd, int32_t flg) {
   return fcntl(fd, F_SETFL, flg);
}

int32_t nonBlocking(int32_t fd) {
   int flg = fcntl(fd, F_GETFL, 0);

   fcntlSetFl(fd, flg | O_NONBLOCK);
   return flg;
}

void pollIn(int32_t fd, struct pollfd *p) {
   p->fd = fd;
   p->events = POLLIN;
}

void pollOut(int32_t fd, struct pollfd *p) {
   p->fd = fd;
   p->events = POLLOUT;
}

int xPoll(struct pollfd *fds, int64_t nfds, int64_t timeout) {
   return poll(fds, (nfds_t)nfds, (int)timeout);
}

int readyIn(struct pollfd *p) {
   return p->revents & POLLIN;
}

int readyOut(struct pollfd *p) {
   return p->revents & POLLOUT;
}

// Sync src/defs.l 'SIGHUP' and src/glob.l '$Signal'
int32_t xSignal(int32_t n) {
   switch (n) {
   case SIGHUP:  return 1;
   case SIGINT:  return 2;
   case SIGUSR1: return 3;
   case SIGUSR2: return 4;
   case SIGPIPE: return 5;
   case SIGALRM: return 6;
   case SIGTERM: return 7;
   case SIGCHLD: return 8;
   case SIGCONT: return 9;
   case SIGSTOP: return 10;
   case SIGTSTP: return 11;
   case SIGTTIN: return 12;
   case SIGTTOU: return 13;
   case SIGIO:   return 14;
   }
   return 0;
}

// Sync src/defs.l 'ENOENT'
int32_t xErrno(void) {
   switch (errno) {
   case ENOENT:     return 1;
   case EINTR:      return 2;
   case EBADF:      return 3;
   case EAGAIN:     return 4;
   case EACCES:     return 5;
   case EPIPE:      return 6;
   case ECONNRESET: return 7;
   }
   return 0;
}

int64_t getTime (void) {
   struct timeval tim;

   if (gettimeofday(&tim, NULL))
      return 0;
   return (int64_t)tim.tv_sec * 1000 + ((int64_t)tim.tv_usec + 500) / 1000;
}

// Lisp data access
int64_t car(int64_t x) {
   return *(int64_t*)x;
}

int64_t cdr(int64_t x) {
   return *((int64_t*)x + 1);
}

int64_t box(int64_t n) {
   if (n >= 0)
      return n << 4 | 2;
   return -n << 4 | 10;
}

int64_t num(int64_t x) {
   if ((x & 8) == 0)
      return x >> 4;
   return -(x >> 4);
}

int length(int64_t x) {
   int n = 0;

   while (!atom(x))
      ++n,  x = cdr(x);
   return n;
}

// Native library interface
#include <dlfcn.h>
#include <ffi.h>

typedef struct ffi {
   ffi_cif cif;
   void (*fun)(void);
   ffi_type *args[0];
} ffi;

void *dlOpen(char *lib) {
   return dlopen(lib, RTLD_LAZY | RTLD_GLOBAL);
}

ffi *ffiPrep(void *lib, char *fun, int64_t lst) {
   int64_t x = car(lst);
   int64_t y = cdr(lst);
   int i, nargs = length(y);
   ffi *p = malloc(sizeof(ffi) + nargs * sizeof(ffi_type*));
   ffi_type *rtype;

   if (x == (int64_t)(SymTab + Nil))
      rtype = &ffi_type_void;
   else if (x == (int64_t)(SymTab + I))
      rtype = &ffi_type_sint32;
   else if (x == (int64_t)(SymTab + N))
      rtype = &ffi_type_sint64;
   else if (x == (int64_t)(SymTab + C))
      rtype = &ffi_type_uint32;
   else if (x == (int64_t)(SymTab + B))
      rtype = &ffi_type_uint8;
   //else if ()
   //   rtype = &ffi_type_float;
   //else if ()
   //   rtype = &ffi_type_double;
   else
      rtype = &ffi_type_pointer;
   for (i = 0; i < nargs; ++i, y = cdr(y)) {
      x  = car(y);
      if (cnt(x))
         p->args[i] = &ffi_type_sint64;
      else if (symb(x))
         p->args[i] = &ffi_type_pointer;
   }
   if (ffi_prep_cif(&p->cif, FFI_DEFAULT_ABI, nargs, rtype, p->args) == FFI_OK  &&  (p->fun = dlsym(lib, fun)))
      return p;
   free(p);
   return NULL;
}

int64_t ffiCall(ffi *p, int64_t lst) {
   int64_t x = car(lst);
   int64_t y = cdr(lst);
   int i, nargs = length(y);
   int64_t val[nargs];
   void *ptr[nargs];
   int64_t rc;

   for (i = 0; i < nargs; ++i, y = cdr(y)) {
      x  = car(y);
      ptr[i] = &val[i];
      if (cnt(x))
         *(int64_t*)&val[i] = num(x);
      else if (symb(x))
         bufString(x, (char*)(val[i] = (int64_t)alloca(bufSize(x))));
   }
   ffi_call(&p->cif, p->fun, &rc, ptr);
   return rc;
}
