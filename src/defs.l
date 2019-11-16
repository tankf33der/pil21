# 15nov19 Software Lab. Alexander Burger

# Constants
(compile) (HEAP CELLS STACK TOP DB1 SIGHUP SIGINT SIGUSR1 SIGUSR2 SIGPIPE
SIGALRM SIGTERM SIGCHLD SIGCONT SIGSTOP SIGTSTP SIGTTIN SIGTTOU SIGIO ENOENT
EINTR EBADF EAGAIN EACCES EPIPE ECONNRESET ioFrame inFile outFile child)

(setq
   HEAP (*/ 1024 1024 8)   # Heap size (number of pointers)
   CELLS (/ HEAP 2)        # Number of cells in a heap (65536)
   STACK (* 64 1024)       # Default coroutine stack segment size (64 kB)
   TOP (hex "110000")      # Character top
   BUFSIZ 4096             # I/O buffer size
   DB1 (hex "1A") )        # Name of '{1}'

## Sync src/lib.c 'xSignal' and src/glob.l '$Signal'
(setq
   SIGHUP    1
   SIGINT    2
   SIGUSR1   3
   SIGUSR2   4
   SIGPIPE   5
   SIGALRM   6
   SIGTERM   7
   SIGCHLD   8
   SIGCONT   9
   SIGSTOP  10
   SIGTSTP  11
   SIGTTIN  12
   SIGTTOU  13
   SIGIO    14 )

## Sync src/lib.c 'xErrno'
(setq
   ENOENT     1      # No such file or directory
   EINTR      2      # Interrupted system call
   EBADF      3      # Bad file number
   EAGAIN     4      # Try again
   EACCES     5      # Permission denied
   EPIPE      6      # Broken pipe
   ECONNRESET 7 )    # Connection reset by peer

(struct ioFrame
   (link 8 i8*)
   (fd 4 i32)
   (pid 4 i32)
   (fun 8 i8*) )

(struct inFile
   (fd 4 i32)
   (ix 4 i32)
   (cnt 4 i32)
   (next 4 i32)
   (line 8 i64)
   (src 8 i64)
   (name 8 i8*)
   (buf `BUFSIZ i8) )

(struct outFile
   (fd 4 i32)
   (ix 4 i32)
   (buf `BUFSIZ i8)
   (tty 8 i1) )

(struct child
   (buf 8 i8*)
   (pid 4 i32)
   (hear 4 i32)
   (tell 4 i32)
   (ofs 4 i32)
   (cnt 4 i32) )

# System
(compile) (malloc realloc free getpid isatty read write strdup strcmp strchr
strrchr memcpy dlerror kill exit)

(de T i8* malloc (i64))
(de T i8* realloc (i8* i64))
(de T void free (i8*))
(de T i32 getpid ())
(de T i32 isatty (i32))
(de T i64 read (i32 i8* i64))
(de T i64 write (i32 i8* i64))
(de T i8* strdup (i8*))
(de T i32 strcmp (i8* i8*))
(de T i8* strchr (i8* i32))
(de T i8* strrchr (i8* i32))
(de T i8* memcpy (i8* i8* i64))
(de T i8* dlerror ())
(de T i32 close (i32))
(de T i32 kill (i32 i32))
(de T NIL exit (i32))

# Glue lib.c
(compile) (stderrMsg strErrno openRdonly openAppend fcntlCloExec fcntlSetFl
nonBlocking pollIn pollOut xPoll readyIn readyOut xSignal xErrno dlOpen ffiPrep
ffiCall)

(de T void stderrMsg (i8* i64))
(de T i8* strErrno ())
(de T i32 openRdonly (i8*))
(de T i32 openAppend (i8*))
(de T i32 fcntlCloExec (i32))
(de T i32 fcntlSetFl (i32 i32))
(de T i32 nonBlocking (i32))
(de T void pollIn (i32 i64*))
(de T void pollOut (i32 i64*))
(de T i32 xPoll (i64* i64 i64))
(de T i32 readyIn (i64*))
(de T i32 readyOut (i64*))
(de T i32 xSignal (i32))
(de T i32 xErrno ())
(de T i64 getTime ())

# Native lib.c
(de T i8* dlOpen (i8*))
(de T i8* ffiPrep (i8* i8* i64))
(de T i64 ffiCall (i8* i64))

### Forward references
(compile) (evList read0 newline space print)

# main.l
(de evList (any))
# io.l
(de read0 (i1))
(de void newline ())
(de void space ())
(de void print (any))
