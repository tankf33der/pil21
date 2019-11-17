# 17nov19 Software Lab. Alexander Burger

# Constants
(compile) (HEAP CELLS STACK TOP DB1 SIGHUP SIGINT SIGUSR1 SIGUSR2 SIGPIPE
SIGALRM SIGTERM SIGCHLD SIGCONT SIGSTOP SIGTSTP SIGTTIN SIGTTOU SIGIO ENOENT
EINTR EBADF EAGAIN EACCES EPIPE ECONNRESET )

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
