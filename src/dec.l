# 20nov19 Software Lab. Alexander Burger

(compile) (inFile outFile child ioFrame catchFrame)

(struct inFile
   (fd 4 i32)
   (ix 4 i32)
   (cnt 4 i32)
   (next 4 i32)
   (line 8 i64)
   (src 8 i64)
   (name 8 i8*)
   (buf BUFSIZ i8) )

(struct outFile
   (fd 4 i32)
   (ix 4 i32)
   (buf BUFSIZ i8)
   (tty 8 i1) )

(struct child
   (buf 8 i8*)
   (pid 4 i32)
   (hear 4 i32)
   (tell 4 i32)
   (ofs 4 i32)
   (cnt 4 i32) )

(struct ioFrame
   (link 8 i8*)
   (fd 4 i32)
   (pid 4 i32)
   (fun 8 i8*) )

(struct catchFrame
   (link 8 i8*)
   (tag 8 any)
   (fin 8 any)
   (env (env T) i8)
   (rst 0 i8) )

# System
(compile) (malloc realloc free getpid isatty read write strdup strcmp strchr
strrchr dlerror kill exit)

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
(de T i8* dlerror ())
(de T i32 close (i32))
(de T i32 setjmp (i8*))
(de T NIL longjmp (i8* i32))
(de T i32 kill (i32 i32))
(de T NIL exit (i32))

# Glue lib.c
(compile) (JmpBufSize stderrMsg strErrno openRdonly openAppend fcntlCloExec
fcntlSetFl nonBlocking pollIn pollOut xPoll readyIn readyOut xSignal xErrno
getTime catchQuit throwQuit dlOpen ffiPrep ffiCall)

(var JmpBufSize i32 NIL)

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
(de T i32 catchQuit ())
(de T NIL throwQuit (i32))

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
