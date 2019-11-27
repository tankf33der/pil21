# 24nov19 Software Lab. Alexander Burger

(compile) (length finish giveup bye alloc heapAlloc sig sighandler err numErr
needNum undefined evExpr evListSave evList evSym equal compare natRet main)

(begin "base")
(load "vers.l" "defs.l" "glob.l" "dec.l")

# Utilities
(inline length (X)
   (let N (i32 0)
      (while (pair X)
         (inc 'N)
         (>>> X) )
      N ) )

# Exit
(de NIL finish ((i32 . N))
   #(setCooked)
   (exit N) )

(de NIL giveup ((i8* . Msg))
   (stderrMsg Msg 0)
   (finish 1) )

(de NIL bye ((i32 . N))
   (finish N) )

# Memory
(de i8* alloc ((i8* . Ptr) (i64 . Siz))
   (let P (realloc Ptr Siz)  # Reallocate pointer
      (when (=0 P)
         (giveup ($ "No memory")) )
      P ) )

(de void heapAlloc ()
   (let H (any (alloc null (* 8 (inc HEAP))))
      (set
         (ofs H HEAP) (val $Heaps)
         $Heaps H )
      (let (P (ofs H (- HEAP 2))  A (val $Avail))
         (loop
            (set P A)  # Link avail
            (setq
               A P
               P (ofs P -2) )  # Back one cell
            (? (== P H)) )
         (set $Avail A) ) ) )

# Signals
(de void sig((i32 . N))
   (let I (val $TtyPid)
      (ifn (=0 I)
         (kill I N)
         (set $Signal (+ (val $Signal) 1))
         (let P (ofs $Signal (xSignal N))
            (set P (+ (val P) 1)) ) ) ) )

(de void sighandler (Exe)
   (when (=0 (val $Protect))
      (set $Protect 1)
      (loop
         (let P (ofs $Signal SIGIO)
            (unless (=0 (val P))
               (set $Signal (- (val $Signal) 1))
               (set P (- (val P) 1))
               (run (val $Sigio)) ) )
         (let P (ofs $Signal SIGUSR1)
            (unless (=0 (val P))
               (set $Signal (- (val $Signal) 1))
               (set P (- (val P) 1))
               (run (val $Sig1)) ) )
         (let P (ofs $Signal SIGUSR2)
            (unless (=0 (val P))
               (set $Signal (- (val $Signal) 1))
               (set P (- (val P) 1))
               (run (val $Sig2)) ) )
         (let P (ofs $Signal SIGALRM)
            (unless (=0 (val P))
               (set $Signal (- (val $Signal) 1))
               (set P (- (val P) 1))
               (run (val $Alarm)) ) )
         #! ...
         (? (=0 (val $Signal))) )
      (set $Protect 0) ) )

# Error handling
(de NIL err (Exe X (i8* . Fmt) (i8* . Arg))
   (set $Up (if (=0 Exe) $Nil Exe))
   (unless (=0 X)
      (link (push X T NIL)) )  # Save
   (let Msg (b8 240)
      (xprintf Msg 240 Fmt Arg)
      (unless (=0 (val Msg))
         (set $Msg (mkStr Msg))
         (let P (val $Catch)
            (until (=0 P)
               (let (Frame (catchFrame P)  Tag (Frame tag))
                  (unless (=0 Tag)
                     (while (pair Tag)
                        (when (subStr (car Tag) (val $Msg))
                           (set $Thrown
                              (if (nil? (car Tag))
                                 (val $Msg)
                                 (car Tag) ) )
                           #! (unwind Frame)
                           (longjmp (Frame rst T) 1) )
                        (>>> Tag) ) )
                  (setq P (Frame link)) ) ) ) )

      (set $Chr (set $ExtN 0))
      (set $Break NO)

      (giveup Msg) ) )

(de numErr (Exe X)
   (err Exe X ($ "Number expected") null) )

# Argument checks
(inline needNum (Exe X)
   (unless (num? X)
      (numErr Exe X) )
   X )

# Evaluation
(de NIL undefined (Fun Exe)
   (err Exe Fun ($ "Undefined") null) )

# Apply EXPR to CDR of list
(de evExpr (Exe Lst)
   (let
      (X (cdr Lst)  # Arguments
         Y (car Exe)  # Parameters
         Q (link (push $At (val $At) NIL (val $Bind) Lst)) )  # [@ [@] LINK Bind Exe]
      (while (pair Y)
         (link
            (push  # [sym val]
               (++ Y)  # Next parameter
               (eval (++ X))  # Evaluate next argument
               NIL ) ) )
      (prog1
         (let P (val $Link)
            (if (== Y $At)  # VarArgs
               (let Next (push (val $Next))
                  (if (atom X)
                     (set $Next $Nil)
                     (let L (link (push (eval (car X)) $Nil NIL))  # [arg1 next]
                        (while (pair (>>> X))
                           (let Z (push (eval (car X)) $Nil NIL)  # [argN next]
                              (set (i L) Z)
                              (setq L Z) ) ) )
                     (set $Next (val $Link)) )
                  (set $Bind P)
                  (loop
                     (let (S (val P)  V (val S))  # Symbol, old value
                        (set S (val (i P)))  # Set new value
                        (set (i P) V)  # Save old value
                        (? (== Q P))
                        (setq P (val (ii P))) ) )
                  (prog1
                     (run (cdr Exe))  # Run body
                     (set $Next (val Next)  $Link (val $Bind)) ) )
               (unless (== Y $Nil)
                  (link (push Y (val Y) NIL))  # Last parameter
                  (set Y X) )  # Set to unevaluated argument(s)
               (set $Bind (val $Link))
               (loop
                  (let (S (val P)  V (val S))  # Symbol, old value
                     (set S (val (i P)))  # Set new value
                     (set (i P) V)  # Save old value
                     (? (== Q P))
                     (setq P (val (ii P))) ) )
               (run (cdr Exe)) ) )  # Run body
         (let P (val $Link)
            (loop
               (set (val P) (val (i P)))  # Restore values
               (? (== Q P))
               (setq P (val (ii P))) )
            (set $Link (val (ii P))) )
         (set $Bind (val (iii Q))) ) ) )

(de i1 sharedLib (Sym)
   NO )

(de evListSave (Fun Exe)
   (save Fun T  # Save computed function
      (loop T
         (unless (=0 (val $Signal))
            (sighandler Exe) )
         (? (num? Fun) (subr Fun Exe))
         (? (pair Fun) (evExpr Fun Exe))
         (let V (val Fun)
            (? (== V (val V))
               (if (sharedLib Fun)
                  (subr (val Fun) Exe)
                  (undefined Fun Exe) ) )
            (setq Fun V) ) ) ) )

(de evList (Exe)
   (let Fun (car Exe)
      (cond T
         ((num? Fun) Exe)  # Number: Return list
         ((sym? Fun)  # Symbol: Find function
            (loop T
               (unless (=0 (val $Signal))
                  (sighandler Exe) )
               (let V (val Fun)  # Get VAL
                  (? (num? V) (subr V Exe))
                  (? (pair V) (evExpr V Exe))
                  (? (== V (val V))
                     (if (sharedLib Fun)
                        (subr (val Fun) Exe)
                        (undefined Fun Exe) ) )
                  (setq Fun V) ) ) )
         (T (evListSave (evList Fun) Exe)) ) ) )  # List: Evaluate

(de evSym (Exe)
   (xSym (eval (car Exe))) )

(load "gc.l" "big.l" "sym.l" "db.l")

# Comparisons
(de i1 equal (X Y)
   (: 1
      (cond T
         ((== X Y) YES)
         ((cnt? X) NO)
         ((big? X)
            (if (big? Y)
               NO
               (when (sign? X)
                  (when (sign? Y)
                     (ret NO) )
                  (setq X (pos X)  Y (pos Y)) )
               (loop T
                  (? (<> (val (dig X)) (val (dig Y))) NO)
                  (?
                     (==
                        (setq X (val (big X)))
                        (setq Y (val (big Y))) )
                     YES )
                  (? (cnt? X) NO)
                  (? (cnt? Y) NO) ) ) )
         ((sym? X)
            (cond T
               ((num? Y) NO)
               ((pair Y) NO)
               ((== ZERO (setq X (name (val (tail X))))) NO)
               ((== ZERO (setq Y (name (val (tail Y))))) NO)
               (T (goto 1)) ) )
         ((atom Y) NO)
         (T
            NO ) ) ) )

(de i32 compare (X Y)
   (cond T
      ((== X Y) (i32 0))
      ((nil? X) (i32 -1))
      ((== X $T) (i32 +1))
      ((num? X)
         (cond T
            ((num? Y) (cmpNum X Y))
            ((nil? Y) (i32 +1))
            (T (i32 -1)) ) )
      ((sym? X)
         (cond T
            ((or (num? Y) (nil? Y))
               (i32 +1) )
            ((or (pair Y) (== Y $T))
               (i32 -1) )
            (T
               (let (A (name (val (tail X)))  B (name (val (tail X))))
                  (i32 0) ) ) ) )
      ((atom Y)
         (if (== Y $T) (i32 -1) (i32 +1)) )
      (T
         (let (A X  B Y)
            (loop T
               (let N (compare (car X) (car Y))
                  (? (n0 N) N) )
               (? (atom (>>> X))
                  (compare X (cdr Y)) )
               (? (atom (>>> Y))
                  (if (== Y $T) (i32 -1) (i32 +1)) )
               (? (and (== X A) (== Y B))
                  (i32 0) ) ) ) ) ) )

(load "io.l" "apply.l" "flow.l" "subr.l" "net.l")

(de natRet (Spec Val)
   (cond T
      ((== Spec $I) (cnt Val))
      ((== Spec $N) (box64 Val))
      ((== Spec $S) (mkStr (i8* Val)))
      (T $Nil) ) )

# (native 'cnt1|sym1 'cnt2|sym2 'any 'any ..) -> any
(de _native (Exe)
   (let
      (X (cdr Exe)
         Y (eval (++ X))  # Eval library 'cnt1|sym1'
         Lib
         (cond T
            ((cnt? Y) (i8* (int Y)))
            ((big? Y) (i8* (val (dig Y))))
            (T
               (let P
                  (dlOpen
                     (if
                        (==
                           (| 2 (>> -4 (char "@")))  # "@"
                           (name (val (tail Y))) )
                        null
                        (pathString Y (b8 (pathSize Y))) ) )
                  (when (=0 P)
                     (err Exe Y ($ "[DLL] %s") (dlerror)) )
                  (set Y (box64 (i64 P)))
                  P ) ) )
         Fun (eval (++ X))  # Eval function 'cnt2|sym2'
         Args (link (push (eval (car X)) $Nil NIL))
         L Args )  # [ret args]
      (while (pair (>>> X))
         (let Z (push (eval (car X)) $Nil NIL)  # [argN next]
            (set (i L) Z)
            (setq L Z) ) )
      (prog1
         (natRet
            (car Args)
            (ffiCall
               (cond T
                  ((cnt? Fun) (i8* (int Fun)))
                  ((big? Fun) (i8* (val (dig Fun))))
                  (T
                     (let P (ffiPrep Lib (bufString Fun (b8 (bufSize Fun))) Args)
                        (when (=0 P)
                           (err Exe 0 ($ "Bad ffi") null) )
                        (set Fun (box64 (i64 P)))
                        P ) ) )
               Args ) )
         (drop Args) ) ) )

# (args) -> flg
(de _args (X)
   (if (pair (val $Next)) $T $Nil) )

# (next) -> any
(de _next (X)
   (set $Next (cdr (setq X (val $Next))))
   (car X) )

# (rest) -> lst
(de _rest (X)
   (if (atom (setq X (val $Next)))
      X
      (let (Y (cons (car X) $Nil)  P (link (push Y T NIL)))
         (while (pair (>>> X))
            (setq Y
               (set (i Y) (cons (car X) $Nil)) ) )
         (pop P) ) ) )

# Main entry point
(de i32 main ((i32 . Ac) (i8** . Av))
   (set $AV0 (val Av))  # Save command
   (set $AV (setq Av (i Av)))  # and argument vector
   # Check debug mode
   (let P (ofs Av (- Ac 2))
      (when (=0 (strcmp (val P) ($ "+")))
         (set $Dbg $T  P null) ) )
   # Locate home directory
   (let P (val Av)  # First argument
      (unless (or (=0 P) (== (val P) (char "-")))
         (let Q (strrchr P (char "/"))
            (unless
               (or
                  (=0 Q)
                  (and
                     (== Q (+ P 1))
                     (== (val P) (char ".")) ) )
               (let (N (+ (- Q P) 1)  H (malloc (+ N 1)))
                  (set $Home H)
                  (memcpy H P N)
                  (set (ofs H N) 0) ) ) ) ) )
   # Initialize globals
   (set $Pid (cnt (i64 (getpid))))
   #! Stack0, Stack1, StkLimit
   (heapAlloc)
   (let P $Nil  # Init internal symbols
      (loop
         (let Nm (val (tail P))
            (when (cnt? Nm)
               (intern P 0 Nm $Pico $Nil)
               (? (== P $LastSym)) ) )
         (setq P (ii P)) ) )
   (set
      (tail $Db1) DB1  # Name of external root symbol '{1}'
      $Extern (cons $Db1 $Nil) )  # External symbol tree root node
   (initOutFile 2)  # Standard error
   (set $OutFile (initOutFile 1))  # Standard output
   (set $InFile (initInFile 0 null))  # Standard input
   (when (=0 (catchQuit))
      (loadAll 0)  # Load arguments
      )
   (loop
      (repl $Nil (char ":") $Nil) ) )

(end)
