// 07nov19 Software Lab. Alexander Burger

#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>

// Lisp data access
#define cnt(x) (x & 2)
#define big(x) (x & 4)
#define numb(x) (x & 6)
#define symb(x) (x & 8)
#define atom(x) (x & 15)

int64_t car(int64_t);
int64_t cdr(int64_t);
int64_t box(int64_t);
int64_t num(int64_t);
int length(int64_t);

extern int64_t SymTab[];
#define Nil (0+1)
// Sync src/glob.l 'T'
#define T (9*2+1)
#define I (10*2+1)
#define N (11*2+1)
#define S (12*2+1)
#define C (13*2+1)
#define B (14*2+1)

int32_t bufSize(int64_t);
char *bufString(int64_t, char*);