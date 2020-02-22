# 22feb20 Software Lab. Alexander Burger

(compile) (dbfErr)

(de NIL dbfErr (Exe)
   (err Exe 0 ($ "Bad DB file") null) )

# 6 bytes in little endian format
(compile) (getAdr setAdr extNm objFile objId packAO packOct packExtNm chopExtNm
extern)

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

# Intern an external symbol
(de extern (Name)
   (consSym (| Name 8) $Nil) )


# (pool ['sym1 ['lst] ['sym2] ['sym3]]) -> T
(de _pool (Exe)
   Exe )


(compile) (dbTouch)

(de dbTouch (Sym)
   Sym )
