# 10nov19 Software Lab. Alexander Burger

(compile) (openErr closeErr eofErr badInput closeOnExec initInFile initOutFile
closeInFile closeOutFile slow slowNb stdinByte waitFd _getStdin getChar skipC
comment skip testEsc anonymous rdAtom rdList read0 read1 _putStdout newline
space outWord outNum outString print load)

(de NIL openErr ()
   (err 0 0 ($ "%s open: %s") (strErrno)) )

(de NIL closeErr ()
   (err 0 0 ($ "Close error: %s") (strErrno)) )

(de NIL eofErr ()
   (err 0 0 ($ "EOF Overrun") null) )

(de NIL badInput ()
   (let S (b8 2)
      (set S (i8 (val $Chr)))
      (set (i S) 0)
      (err 0 0 ($ "Bad input '%c'") S) ) )

(de void closeOnExec (Exe (i32 . Fd))
   (when (lt0 (fcntlCloExec Fd))
      (err Exe 0 ($ "SETFD %s") (strErrno)) ) )

(de i8* initInFile ((i32 . Fd) (i8* . Nm))
   (let I (val $InFDs)
      (when (>= Fd I)
         (let P
            (set $InFiles
               (i8**
                  (alloc
                     (i8* (val $InFiles))
                     (i64 (* 8 (set $InFDs (+ Fd 1)))) ) ) )
            (loop
               (set (ofs P I) null)
               (? (== I Fd))
               (inc 'I) ) ) ) )
   (let
      (P (ofs (val $InFiles) Fd)
         V (set P (alloc (val P) (inFile T)))
         F (inFile V) )
      (F fd Fd)
      (F ix (F cnt (F next 0)))
      (F line (F src 1))
      (F name Nm)
      V ) )

(de i8* initOutFile ((i32 . Fd))
   (let I (val $OutFDs)
      (when (>= Fd I)
         (let P
            (set $OutFiles
               (i8**
                  (alloc
                     (i8* (val $OutFiles))
                     (i64 (* 8 (set $OutFDs (+ Fd 1)))) ) ) )
            (loop
               (set (ofs P I) null)
               (? (== I Fd))
               (inc 'I) ) ) ) )
   (let
      (P (ofs (val $OutFiles) Fd)
         V (set P (alloc (val P) (outFile T)))
         F (outFile V) )
      (F tty (n0 (isatty (F fd Fd))))
      (F ix 0)
      V ) )

(de void closeInFile ((i32 . Fd))
   (when (> (val $InFDs) Fd)
      (let (P (ofs (val $InFiles) Fd)  V (val P))
         (unless (=0 V)
            (when (== V (val $InFile))
               (set $InFile null) )
            (free ((inFile V) name))
            (free V)
            (set P null) ) ) ) )

(de void closeOutFile ((i32 . Fd))
   (when (> (val $OutFDs) Fd)
      (let (P (ofs (val $OutFiles) Fd)  V (val P))
         (unless (=0 V)
            (when (== V (val $OutFile))
               (set $OutFile null) )
            (free V)
            (set P null) ) ) ) )

(de i32 slow ((i8* . In))
   (let F (inFile In)
      (F ix (F cnt 0))
      (loop T
         (let N (read (F fd) (F buf T) 4096)
            (? (ge0 N) (F cnt (i32 N))) )
         (? (<> (xErrno) EINTR) 0)
         (unless (=0 (val $Signal))
            (sighandler 0) ) ) ) )

(de i32 slowNb ((i8* . In))
   (let F (inFile In)
      (F ix (F cnt 0))
      (loop T
         (let
            (Flg (nonBlocking (F fd))
               N (read (F fd) (F buf T) 4096) )
            (fcntlSetFl (F fd) Flg)
            (? (gt0 N) (F cnt (i32 N)))
            (? (=0 N)
               (F ix (F cnt -1))
               0 ) )
         (let E (xErrno)
            (? (== E EAGAIN) -1)
            (? (<> E EINTR) 0) )
         (unless (=0 (val $Signal))
            (sighandler 0) ) ) ) )

(de i32 stdinByte ()
   (getchar) )

(de i64 waitFd (Exe (i32 . Fd) (i64 . Ms))
   (loop T
      (let
         (S (stack)
            P (b64 (+ (+ (length (val $Run)) (val $Children)) 3)) )
         #! ...
         (stack S) )
      (? (=0 Fd) 0) ) )

(de i32 _getStdin ()
   (let F (inFile (val $InFile))
      (set $Chr
         (cond T
            ((=0 (F)) -1)  # EOF
            ((n0 (F fd))  # Not stdin
               (if
                  (and
                     (== (F ix) (F cnt))
                     (or (lt0 (F ix)) (=0 (slow (F)))) )
                  -1
                  (let I (F ix)
                     (prog1
                        (i32 (val (ofs (F buf T) I)))
                        (when (== @ (char "\n"))
                           (F line (+ (F line) 1)) )
                        (F ix (+ I 1)) ) ) ) )
            ((atom (val $Led))  # No line editor
               (waitFd 0 0 -1)
               (stdinByte) )
            (T
               (when (=0 (val (i $Line)))  # First call
                  (let S (run (val $Led))
                     (set $Line 0)
                     (set (i $Line)
                        (if (nil? S)
                           ZERO
                           (name S) ) ) ) )
               (let B (numByte $Line)  # Extract next byte
                  (if (=0 B)
                     (char "\n")
                     (i32 B) ) ) ) ) ) ) )

(de i32 getChar ((i32 . C))
   (cond T
      ((>= 127 C) C)  # Single byte
      ((== C (hex "FF")) (i32 TOP))  # Infinite
      (T
         (let B
            (if (=0 (& C (hex "20")))  # Two bytes
               (& C (hex "1F"))  # First byte 110xxxxx
               (let A
                  (if (=0 (& C (hex "10")))  # Three bytes
                     (& C (hex "0F"))  # First byte 1110xxxx
                     (|  # Four bytes
                        (shl (& C 7) 6)  # First byte 11110xxx
                        (& (call $Get) (hex "3F")) ) )  # 10xxxxxx
                  (| (shl A 6) (& (call $Get) (hex "3F"))) ) )
            (| (shl B 6) (& (call $Get) (hex "3F"))) ) ) ) )

(de i32 skipC ((i32 . C))
   0 )

(de i32 comment ()
   (call $Get) )

(de i32 skip ()
   (let C (val $Chr)
      (loop
         (when (lt0 C)
            (ret C) )
         (loop
            (? (> C (char " ")))
            (when (lt0 (setq C (call $Get)))
               (ret C) ) )
         (when (<> C (char "#"))
            (ret C) )
         (setq C (comment)) ) ) )

(de i1 testEsc ((i32 . C))
   (loop T
      (? (lt0 C) NO)
      (? (== C (char "\^"))  # Control character
         (setq C (call $Get))
         (when (== C (char "@"))
            (badInput) )
         (set $Chr
            (if (== C (char "?"))
               127
               (& C (hex "1F")) ) )
         YES )
      (? (<> C (char "\\"))  # No Backslash
         (set $Chr (getChar C))
         YES )
      (? (<> 10 (setq C (call $Get)))  # Backslash: Skip '\'
         (case C
            ((char "n") (set $Chr (char "\n")))
            ((char "r") (set $Chr (char "\r")))
            ((char "t") (set $Chr (char "\t")))
            (T
               (when (and (>= C (char "0")) (>= (char "9") C))
                  (setq C (- C (char "0")))
                  (until (== (call $Get) (char "\\"))
                     (unless
                        (and
                           (>= (val $Chr) (char "0"))
                           (>= (char "9") (val $Chr)) )
                        (badInput) )
                     (setq C
                        (+ (* C 10) (- (val $Chr) (char "0"))) ) ) )
               (set $Chr C) ) )
         YES )
      (loop
         (? (== (setq C (call $Get)) (char " ")))
         (? (== C (char "\t"))) ) ) )

(de anonymous ()
   $Nil )

(de rdAtom ((i32 . C))
   (let (P (push 4 ZERO T NIL)  Q (link (any (i P))))  # [cnt name cell]
      (byteNum C P)
      (setq C (val $Chr))
      (while (and (gt0 C) (=0 (strchr $Delim C)))
         (when (== C (char "\\"))
            (setq C (call $Get)) )
         (byteNum C P)
         (setq C (call $Get)) )
      (prog1
         (let (Nm (val Q)  Num (symToNum Nm 0 (char ".") 0))
            (cond T
               ((n0 Num) Num)
               (T (findSym Nm)) ) )
         (drop Q) ) ) )

(de rdList ()
   (call $Get)
   (let
      (P (push NIL T NIL)
         X
         (loop T
            (let C (skip)
               (when (== C (char ")"))  # Empty list
                  (call $Get)
                  (ret $Nil) )
               (when (== C (char "]"))  # Empty list
                  (ret $Nil) )
               (? (<> C (char "~"))  # Read macro
                  (set (link P) (cons (read0 NO) $Nil)) )
               (call $Get)
               (let Y (set (link P) (read0 NO))
                  (? (pair (setq Y (eval (val P))))
                     (while (pair (cdr Y))
                        (>>> Y) )
                     Y ) )
               (drop P) ) ) )
      (loop
         (let C (skip)
            (? (== C (char ")"))
               (call $Get) )
            (? (== C (char "]")))
            (cond
               ((== C (char "."))
                  (? (n0 (strchr $Delim (call $Get)))
                     (setq X
                        (set (i X)
                           (if
                              (or
                                 (== (setq C (skip)) (char ")"))
                                 (== C (char "]")) )
                              (val P)
                              (read0 NO) ) ) )
                     (cond
                        ((== (skip) (char ")"))
                           (call $Get) )
                        ((<> (val $Chr) (char "]"))
                           (err 0 X ($ "Bad dotted pair") null) ) ) )
                  (setq X
                     (set (i X) (cons (rdAtom (char ".")) $Nil)) ) )
               ((== C (char "~"))
                  (call $Get)
                  (set (i X)
                     (eval
                        (set (i X) (read0 NO)) ) )
                  (while (pair (cdr X))
                     (>>> X) ) )
               (T
                  (setq X
                     (set (i X) (cons (read0 NO) $Nil)) ) ) ) ) )
      (pop P) ) )

(de read0 ((i1 . Top))
   (let C (skip)
      (cond T
         ((lt0 C)
            (unless Top (eofErr))
            $Nil )
         #((and Top ..)
         #   .. )
         ((== C (char "("))
            (prog1
               (rdList)
               (and
                  Top
                  (== (val $Chr) (char "]"))
                  (call $Get) ) ) )
         ((== C (char "["))
            (let X (rdList)
               (when (== (val $Chr) (char "]"))
                  (err 0 X ($ "Super parentheses mismatch") null) )
               (call $Get)
               X ) )
         ((== C (char "'"))
            (call $Get)
            (cons $Quote (read0 Top)) )
         #((== C (char ","))
         #   )
         ((== C (char "`"))
            (call $Get)
            (save (read0 Top) T
               (eval @) ) )
         ((== C (char "\""))
            (if (== (setq C (call $Get)) (char "\""))
               (prog (call $Get) $Nil)  # Empty string
               (unless (testEsc C) (eofErr))
               (let (P (push 4 ZERO T NIL)  Q (link (any (i P))))  # [cnt name cell]
                  (loop
                     (charNum (val $Chr) P)
                     (? (== (setq C (call $Get)) (char "\"")))
                     (unless (testEsc C) (eofErr)) )
                  (call $Get)  # Skip "\""
                  (prog1
                     (intern 0 0 (val Q) $Transient $Nil)
                     (drop Q) ) ) ) )
         #((== C (char "{"))
         #   )
         ((or (== C (char ")")) (== C (char "]")) (== C (char "~")))
            (badInput) )
         (T
            (when (== C (char "\\"))
               (call $Get) )
            (setq C (val $Chr))
            (call $Get)
            (rdAtom C) ) ) ) )

(de read1 ((i32 . End))
   (when (=0 (val $Chr))
      (call $Get) )
   (if (== End (val $Chr))
      $Nil
      (read0 YES) ) )

(de void _putStdout ((i32 . C))
   (putchar C) )

(de void newline ()
   (call $Put (char "\n")) )

(de void space ()
   (call $Put (char " ")) )

# Output decimal number
(de void outWord ((i64 . N))
   (when (> N 9)
      (outWord (/ N 10))
      (setq N (% N 10)) )
   (call $Put (+ (i32 N) (char "0"))) )

(de void outNum (X)
   (when (sign? X)
      (call $Put (char "-")) )
   (outWord (shr (i64 X) 4)) )

# Output octal number
(de void outOct ((i64 . N))
   (when (> N 7)
      (outOct (shr N 3))
      (setq N (& N 7)) )
   (call $Put (+ (i32 N) (char "0"))) )

# Output A-O encoding
(de void outAo ((i64 . N))
   (when (> N 15)
      (outAo (shr N 4))
      (setq N (& N 15)) )
   (call $Put (+ (i32 N) (char "@"))) )

# Output external symbol name
(de void prExt (Nm)
   (let F (objFile Nm)
      (unless (=0 F)
         (outAo F) )
      (outOct (objId Nm)) ) )

# Output string
(de void outString ((i8* . S))
   (while (n0 (val S))
      (call $Put (i32 (val S)))
      (inc 'S) ) )

(de void print (X)
   (cond
      ((cnt? X) (outNum X))
      ((big? X) (outString ($ "<big>")))
      ((sym? X)
         (let Nm (name (val (tail X)))
            (cond
               ((== Nm ZERO)  # Anonymous
                  (call $Put (char "$"))
                  (outOct (int X)) )
               ((sym? (val (tail X)))  # External
                  (call $Put (char "{"))
                  (prExt Nm)
                  (call $Put (char "}")) )
               ((isIntern X Nm
                     (val (car (val $Intern)))
                     (cdr (val $Intern)) )
                  (let (P (push 0 (i64 Nm))  B (numByte P))  # [cnt name]
                     (loop
                        (call $Put (i32 B))
                        (? (=0 (setq B (numByte P)))) ) ) )
               (T  # Transient
                  (call $Put (char "\""))
                  (let (P (push 0 (i64 Nm))  B (numByte P))  # [cnt name]
                     (loop
                        (call $Put (i32 B))
                        (? (=0 (setq B (numByte P)))) ) )
                  (call $Put (char "\"")) ) ) ) )
      ((and (== (car X) $Quote) (<> X (cdr X)))
         (call $Put (char "'"))
         (print (cdr X)) )
      (T
         (call $Put (char "("))
         (loop
            (print (car X))
            (? (== $Nil (>>> X)))
            (? (atom X)
               (outString ($ " . "))
               (print X) )
            (space) )
         (call $Put (char ")")) ) ) )

(de load (Exe (i32 . Pr) X)
   (setq X $Nil)
   (loop
      (when (and (n0 Pr) (=0 (val $Chr)))
         (call $Put Pr)
         (space) )
      (let Y (read1 (char "\n"))
         (while (gt0 (val $Chr))
            (? (== (val $Chr) (char "\n"))
               (set $Chr 0) )
            (if (== (val $Chr) (char "#"))
               (comment)
               (? (> (val $Chr) (char " ")))
               (call $Get) ) )
         (when (nil? Y)
            (exit 0) #{ret X)}# )
         (let A (val $At)
            (save Y A
               (setq X (set $At (eval Y)))
               (set $At3 (val $At2))
               (set $At2 A)
               (outString ($ "-> "))
               (print X)
               (newline) ) ) ) ) )

# (in 'any . prg) -> any
(de _in (X)
   (let F (inFile)
      X ) )