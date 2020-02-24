# 24feb20 Software Lab. Alexander Burger

(compile) (dbfErr extern)

(de NIL dbfErr (Exe)
   (err Exe 0 ($ "Bad DB file") null) )

# Intern an external symbol
(de extern (Name)
   (let (X (val $Extern)  C 0  Sym NIL)
      (loop
         (inc 'C)  # Next level
         (setq Sym (car X))  # Next symbol
         (let Nm (& (name (val (tail Sym))) (hex "3FFFFFFFFFFFFFF7"))  # Mask status and extern bits
            (? (== Nm Name))  # Found
            (if (> Name Nm)  # Symbol is smaller
               (let Y (cdr X)  # Get link cell
                  (? (atom Y)  # No link yet
                     (set 2 X
                        (cons $Nil (cons (setq Sym (consExt Name)) $Nil)) ) )
                  (? (atom (setq Y (cdr (setq X Y))))
                     (set 2 X
                        (cons (setq Sym (consExt Name)) $Nil) ) )
                  (setq X Y) )
               (let Y (cdr X)  # Get link cell
                  (? (atom Y)  # No link yet
                     (set 2 X
                        (cons (cons (setq Sym (consExt Name)) $Nil) $Nil) ) )
                  (? (atom (setq Y (cdr (setq X Y))))
                     (set X
                        (cons (setq Sym (consExt Name)) $Nil) ) )
                  (setq X Y) ) ) ) )
      (setq C (shr C 1))  # Half depth
      (when (> (shl 1 C) (val $ExtCnt))  # 2 ** (C/2)
         (setq X (val $Extern))
         (let N (val $ExtSkip)  # Levels to skip
            (if (> (inc 'N) C)  # Beyond half depth
               (set $ExtSkip 0)  # Don't skip
               (set $ExtSkip N)
               (loop  # Skip
                  (setq X
                     (if
                        (>
                           Name
                           (&
                              (name (val (tail (++ X))))
                              (hex "3FFFFFFFFFFFFFF7") ) )
                        (cdr X)
                        (car X) ) )
                  (? (=0 (dec 'C))) ) ) )
         (loop  # Pivot
            (let
               (Nm
                  (&
                     (name (val (tail (car X))))
                     (hex "3FFFFFFFFFFFFFF7") )
                  Y (cdr X) )
            (? (== Nm Name))  # Done
            (if (> Name Nm)  # Symbol is smaller
               (let Z (cdr Y)  # Get right node
                  (? (atom (cdr Z)))
                  (xchg Z X)  # Pivot left
                  (setq Z (cdr Z)  X (cdr Z))
                  (set  # Rotate pointers
                     2 Z (val Z)
                     Z (val Y)
                     Y (cdr Y)
                     2 Y X) )
               (let Z (car Y)  # Get left node
                  (? (atom (cdr Z)))
                  (xchg Z X)  # Pivot right
                  (setq Z (cdr Z)  X (val Z))
                  (set  # Rotate pointers
                     Z (cdr Z)
                     2 Z (cdr Y)
                     2 Y (val Y)
                     Y X) ) ) ) ) )
      Sym ) )

(compile) (getAdr setAdr extNm objFile objId packAO packOct packExtNm chopExtNm)

# 6 bytes in little endian format
# Get block address from buffer
(de i64 getAdr ((i8* . P))
   (|
      (shl
         (|
            (shl
               (|
                  (shl
                     (|
                        (shl
                           (|
                              (shl (i64 (val 6 P)) 8)
                              (i64 (val 5 P)) )
                           8 )
                        (i64 (val 4 P)) )
                     8 )
                  (i64 (val 3 P)) )
               8 )
            (i64 (val 2 P)) )
         8 )
      (i64 (val P)) ) )

# Set block address in buffer
(de void setAdr ((i64 . N) (i8* . P))
   (set P (i8 N))
   (set 2 P (i8 (setq N (shr N 8))))
   (set 3 P (i8 (setq N (shr N 8))))
   (set 4 P (i8 (setq N (shr N 8))))
   (set 5 P (i8 (setq N (shr N 8))))
   (set 6 P (i8 (setq N (shr N 8)))) )

# Build external symbol name
(de extNm ((i64 . File) (i64 . Obj))
   (cnt
      (|
         (& Obj (hex "FFFFF"))  # Lowest 20 bits
         (|
            (shl (& File (hex "FF")) 20)  # Lower 8 bits
            (|
               (shl
                  (& (setq Obj (shr Obj 20)) (hex "FFF"))  # Middle 12 bits
                  28 )
               (|
                  (shl (shr File 8) 40)  # Upper 8 bits
                  (shl (shr Obj 12) 48) ) ) ) ) ) )  # Highest 10 bits

# Get file number from external symbol name
(de i64 objFile (Name)
   (|
      (& (setq Name (shr Name 24)) (hex "FF"))  # Low 8 bits
      (& (shr Name 12) (hex "FF00")) ) )  # High 8 bits

# Get object ID from external symbol name
(de i64 objId (Name)
   (|
      (|
         (& (setq Name (shr Name 4)) (hex "FFFFF"))  # Lowest 20 bits
         (& (setq Name (shr Name 8)) (hex "FFF00000")) )  # Middle 12 bits
      (& (shr Name 8) (hex "3FF00000000")) ) )  # Highest 10 bits

# Pack external symbol name
(de void packAO ((i64 . File) (i64* . P))
   (when (> File 15)
      (packAO (shr File 4) P) )  # Divide by 16
   (byteNum (+ (& (i8 File) 15) (char "@")) P) )  # Make ASCII letter

(de void packOct ((i64 . Obj) (i64* . P))
   (when (> Obj 7)
      (packOct (shr Obj 3) P) )  # Divide by 8
   (byteNum (+ (& (i8 Obj) 7) (char "0")) P) )  # Make ASCII digit

(de packExtNm (Name)
   (let (P (push 4 ZERO NIL)  Q (link (ofs P 1)))  # [cnt name link]
      (let File (objFile Name)
         (unless (=0 File)
            (packAO File P) ) )
      (packOct (objId Name) P)
      (prog1
         (consSym (val Q) 0)
         (drop Q) ) ) )

# Chop external symbol name
(de chopExtNm (Name)
   (let (R (link (push $Nil NIL))  N (objId Name))
      (loop
         (let A (+ (& N 7) (char "0"))  # Make ASCII digit
            (unless (=0 (setq N (shr N 3)))
               (setq A
                  (|
                     (shl A 8)
                     (+ (& N 7) (char "0")) ) )  # Second octal digit
               (unless (=0 (setq N (shr N 3)))
                  (setq A
                     (|
                        (shl A 8)
                        (+ (& N 7) (char "0")) ) ) ) )  # Third octal digit
            (set R
               (cons (consSym (cnt A) 0) (val R)) ) )
         (? (=0 (setq N (shr N 3)))) )
      (unless (=0 (setq N (objFile Name)))
         (let F 0
            (loop
               (setq F
                  (| F (+ (& N 15) (char "@"))) )  # Make ASCII letter
               (? (=0 (setq N (shr N 4))))
               (setq F (shl F 8)) )
            (set R
               (cons (consSym (cnt F) 0) (val R)) ) ) )
      (pop R) ) )

(compile) (rdLockDb wrLockDb unLockDb tryLock)

# Locking
(de void rdLockDb ()
   (unless (== $T (val $Solo))  # Not already locked whole DB
      (while (lt0 (rdLock ((dbFile (val $DbFiles)) fd) 0 1))  # Descriptor of first file
         (unless (== (xErrno) EINTR)
            (lockErr) ) ) ) )

(de void wrLockDb ()
   (unless (== $T (val $Solo))  # Not already locked whole DB
      (while (lt0 (wrLock ((dbFile (val $DbFiles)) fd) 0 1 YES))  # Descriptor of first file
         (unless (== (xErrno) EINTR)
            (lockErr) ) ) ) )

(de void unLockDb ((i64 . Len))
   (unless (== $T (val $Solo))  # Not already locked whole DB
      (when (=0 Len)
         (let (P (val $DbFiles)  C (val $DBs))
            (until (=0 (dec 'C))
               (let Db: (dbFile (setq P (ofs P (dbFile T))))  # Skip first, increment by size of dbFile
                  (when (Db: lck)
                     (unLock (Db: fd) 0 0)
                     (Db: lck NO) ) ) ) )
         (set $Solo ZERO) )
      (unLock ((dbFile (val $DbFiles)) fd) 0 Len) ) )  # Descriptor of first file

(de i32 tryLock ((i64 . N) (i64 . Len))
   (let Db: (dbFile (val $DbFile))
      (loop
         (when (ge0 (wrLock (Db: fd) N Len NO))  # Try to lock
            (Db: lck YES)  # Set lock flag
            (cond
               ((=0 N) (set $Solo $T))  # Set solo mode
               ((== $T (val $Solo)) (set $Solo $Nil)) )  # Clear solo mode
            (ret 0) )
         (let E (xErrno)
            (or
               (== E EINTR)  # Interrupted
               (== E EACCES)  # Locked by another process
               (== E EAGAIN)  # Memory-mapped by another process
               (lockErr) ) )
         (let Pid NIL
            (while (lt0 (setq Pid (getLock (Db: fd) N Len)))
               (unless (== (xErrno) EINTR)
                  (lockErr) ) )
            (when (gt0 Pid)
               (ret Pid) ) ) ) ) )

# (pool ['sym1 ['lst] ['sym2] ['sym3]]) -> T
(de _pool (Exe)
   Exe )


(compile) (dbTouch)

(de dbTouch (Sym)
   Sym )
