# 05jan20 Software Lab. Alexander Burger

(compile) (inFile outFile dbFile ioFrame caFrame coroutine coFrame child)

# I/O
(struct inFile
   (fd 4 i32)           # File descriptor
   (ix 4 i32)           # Buffer index
   (cnt 4 i32)          # Buffer byte count
   (next 4 i32)         # Saved next character
   (name 8 i8*)         # Current file name
   (line 8 i64)         # Current line number
   (src 8 i64)          # Source start line
   (buf BUFSIZ i8) )    # Buffer

(struct outFile
   (fd 4 i32)           # File descriptor
   (ix 4 i32)           # Buffer index
   (buf BUFSIZ i8)      # Buffer
   (tty 1 i1) )         # TTY flag

(struct dbFile
   (fd 4 i32)           # File descriptor
   (db 4 i32)           # File number
   (sh 4 i32)           # Block shift
   (siz 4 i32)          # Block size (64 << sh)
   (mark 8 i8*)         # Mark bit vector
   (mrks 4 i32)         # Mark vector size
   (flu 4 i32)          # Free list use count
   (lck 1 i1)           # Lock flag
   (drt 1 i1) )         # Dirty flag

(struct ioFrame
   (link 8 i8*)         # Frame link
   (fd 4 i32)           # File descriptor
   (pid 4 i32)          # Process ID
   (fun 8 i8*) )        # Function pointer

# Catch/throw
(struct caFrame
   (link 8 i8*)         # Frame link
   (tag 8 any)          # Catch tag
   (fin 8 any)          # 'finally' expression
   (env (env T) i8)     # Saved environment
   (rst 0 i8) )         # Restart jmp_buf (JmpBufSize)

# Coroutines
(struct coroutine
   (tag 8 any)          # Coroutine tag
   (next 8 i8*)         # Next coroutine
   (prg 8 any)          # Code body
   (lim 8 i8*)          # Stack limit
   (at 8 any)           # Saved [@]
   (env (env T) i8)     # Saved environment
   (rst 0 i8) )         # Restart jmp_buf (JmpBufSize)

(struct coFrame
   (link 8 i8*)         # Frame link
   (crt 8 i8*) )        # Coroutine

# Family IPC
(struct child
   (buf 8 i8*)          # Buffer pointer
   (pid 4 i32)          # Process ID
   (hear 4 i32)         # Hear pipe
   (tell 4 i32)         # Tell pipe
   (ofs 4 i32)          # Buffer offset
   (cnt 4 i32) )        # Buffer byte count

# System
(compile) (malloc realloc free getpid isatty read write strdup strcmp strchr
strrchr dlerror close setjmp longjmp kill exit)

(de T i8* malloc (i64))
(de T i8* realloc (i8* i32))
(de T void free (i8*))
(de T i32 getpid ())
(de T i32 isatty (i32))
(de T i64 read (i32 i8* i64))
(de T i64 write (i32 i8* i64))
(de T i8* strdup (i8*))
(de T i32 strcmp (i8* i8*))
(de T i8* strchr (i8* i32))
(de T i8* strrchr (i8* i32))
(de T i8* dlerror ())
(de T i32 close (i32))
(de T i32 setjmp (i8*))
(de T NIL longjmp (i8* i32))
(de T i32 kill (i32 i32))
(de T NIL exit (i32))

# Glue lib.c
(compile) (JmpBufSize stderrMsg xprintf strErrno openRdonly openAppend
fcntlCloExec fcntlSetFl nonBlocking pollIn pollOut xPoll readyIn readyOut
xSignal xErrno getTime catchQuit throwQuit dlOpen ffiPrep ffiCall)

(var JmpBufSize i32 NIL)

(de T void stderrMsg (i8* i64))
(de T i32 xprintf (i8* i32 i8* i8*))
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
(de T i32 catchQuit ())
(de T NIL throwQuit ())

# Native lib.c
(de T i8* dlOpen (i8*))
(de T i8* ffiPrep (i8* i8* i64))
(de T i64 ffiCall (i8* i64))

### Forward references
(compile) (evList mkStr subStr read0 pushOutFiles newline space outWord
outString print repl)

# main.l
(de evList (any))
# sym.l
(de mkStr (i8*))
(de xSym (any))
(de i1 subStr (any any))
# io.l
(de read0 (i1))
(de void pushOutFiles (i8*))
(de void newline ())
(de void space ())
(de void outWord (i64))
(de void outString (i8*))
(de void print (any))
(de repl (any i32 any))
