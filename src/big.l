# 10nov19 Software Lab. Alexander Burger

(compile) (numByte numChar byteNum charNum zapZero twiceBig twice half tenfold
shlu shru andu oru xoru addu subu incs decs cmpu cmpNum symToNum)

### Bignum byte access ###
(de i8 numByte ((i64* . P))
   (let C (val P)  # Get cnt
      (when (=0 C)  # New round
         (let Nm (val (i P))
            (cond
               ((== Nm ZERO) (ret (i8 0)))  # Done
               ((cnt? Nm)  # Short
                  (setq C (shr Nm 4))
                  (set (i P) ZERO) )
               (T  # Big: Next digit
                  (setq C (set P (val (dig Nm))))
                  (set (i P) (val (big Nm))) ) ) ) )
      (set P (shr C 8))
      (i8 C) ) )

#! numChar

(de void byteNum ((i32 . C) (i64* . P))
   (let (Cnt (val P)  Name (val (i P)))
      (unless (big? Name)  # Short name
         # 0000.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx0010
         #   60      52      44      36      28      20      12       4
         (when (> 60 Cnt)  # Digit not full
            (set
               (i P)
               (| Name (shl (i64 C) Cnt)) )
            (set P (+ Cnt 8))
            (ret) )
         (set (ii P)
            (set (i P)
               (boxNum  # Make big
                  (|  # Combine byte with digit
                     (shr Name 4)  # De-normalize short number
                     (shl (i64 C) 56) ) ) ) )  # Adjust byte
         (set P 4)  # Start new digit
         (ret) )
      (let (Q (val (ii P))  N (val (big Q)))
         (when (> 60 Cnt)  # Digit not full
            (set
               (big Q)
               (| N (shl (i64 C) Cnt)) )
            (set P (+ Cnt 8))
            (ret) )
         (set (ii P)
            (set (big Q)
               (boxNum  # Make big
                  (|  # Combine byte with digit
                     (shr N 4)  # De-normalize short number
                     (shl (i64 C) 56) ) ) ) )  # Adjust byte
         (set P 4) ) ) )  # Start new digit

(de void charNum ((i32 . C) (i64* . P))
   (cond
      ((> 128 C) (byteNum C P))  # Single byte
      ((== TOP C) (byteNum (hex "FF") P))  # Infinite
      (T
         (cond
            ((> (hex "800") C)  # Double-byte
               (byteNum (| (hex "C0") (& (hex "1F") (shr C 6))) P) )  # 10xxxxx 10xxxxxx
            ((> (hex "10000") C)  # Three bytes
               (byteNum (| (hex "E0") (& (hex "0F") (shr C 12))) P)  # 1110xxxx 10xxxxxx 10xxxxxx
               (byteNum (| (hex "80") (& (hex "3F") (shr C 6))) P) )
            (T
               (byteNum (| (hex "F0") (& (hex "07") (shr C 18))) P)  # 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
               (byteNum (| (hex "80") (& (hex "3F") (shr C 12))) P)
               (byteNum (| (hex "80") (& (hex "3F") (shr C 6))) P) ) )
         (byteNum (| (hex "80") (& (hex "3F") (shr C 6))) P) ) ) )

### Destructive primitives ###
# Remove leading zeroes
(de zapZero (N)
   (let (P (push N)  X P  Y P  Z (val (big N)))
      (until (cnt? Z)  # Last cell
         (unless (=0 (val (dig N)))  # Null digit?
            (setq X Y) )  # New null-tail
         (setq
            Y (big N)  # New short-tail
            N (val Y)  # Next cell
            Z (val (big N)) ) )
      (when (== Z ZERO)
         (nond
            ((=0 (setq N (val (dig N))))  # Final digit
               (when (=0 (& N (hex "F000000000000000")))
                  (set Y (cnt N)) ) )  # Store in short-tail
            ((=0
                  (&
                     (val (dig (val X)))  # Digit in null-tail
                     (hex "F000000000000000") ) )
               (set (big (val X)) ZERO) )  # Trim null-tail
            (NIL (set X (cnt N))) ) )  # Store in null-tail
      (val P) ) )

# Multiply (unsigned) number by 2
(de twiceBig (N)
   (let (X N  A (val (dig X))  Y (val (big X)))
      (set (dig X) (shl A 1))
      (while (big? Y)
         (let B (val (dig Y))
            (set (dig (setq X Y))
               (| (shl B 1) (shl 0 A 1)) )
            (setq A B  Y (val (big Y))) ) )
      (set (big X)
         (box64
            (| (shl (shr Y 4) 1) (shl 0 A 1)) ) ) )
   N )

(de twice (N)
   (if (big? N)
      (twiceBig N)
      (let X (+ N N)  # Shift left
         (if @@  # Overflow
            (boxNum (shr N 3))  # Make big
            (x| X 6) ) ) ) )  # Fix tag bit

# Divide (unsigned) number by 2
(de half (N)
   (if (big? N)
      (let (X N  A (shr (val (dig X)) 1)  Y (val (big X)))
         (if (big? Y)
            (let (B (val (dig Y))  Z (val (big Y)))
               (loop
                  (set (dig X) (| (shr B 0 1) A))
                  (setq A (shr B 1))
                  (? (cnt? Z))
                  (setq X Y  Y Z) )
               (setq A (| (shr Z 0 5) A))
               (if
                  (and
                     (=0 (setq Z (shr Z 5)))
                     (=0 (& A (hex "F000000000000000"))) )
                  (set (big X) (cnt A))
                  (set (dig Y) A)
                  (set (big Y) (cnt Z)) ) )
            (setq A (| (shr Y 0 5) A))
            (and
               (=0 (setq Y (shr Y 5)))
               (=0 (& A (hex "F000000000000000")))
               (ret (cnt A)) )
            (set (dig X) A)
            (set (big X) (cnt Y)) )
         N )
      (| (& (shr N 1) -10) 2) ) )  # (not 9) Clear lowest bit and tag

# Multiply (unsigned) number by 10
(de tenfold (N)
   (if (big? N)
      (let (X N  A (mul 10 (val (dig X)))  B @@)
         (loop
            (set (dig X) A)
            (? (cnt? (setq A (val (big X)))))
            (setq X A  A (mul 10 (val (dig X))))
            (let C @@
               (setq A (+ A B)  B (+ C @@)) ) )
         (set (big X)
            (+ B (mul 10 (int A))) )
         N )
      (box64 (* 10 (int N))) ) )

### Non-destructive primitives ###
# Multiply (unsigned) number by 2
(de shlu (N)
   (if (big? N)
      (let
         (A (val (dig N))
            X (boxNum (shl A 1))
            Y (val (big N))
            P (link (push X T NIL)) )
         (while (big? Y)
            (let B (val (dig Y))
               (setq X
                  (set (big X)
                     (boxNum (| (shl B 1) (shl 0 A 1))) ) )
               (setq A B  Y (val (big Y))) ) )
         (set (big X)
            (box64
               (| (shl (shr Y 4) 1) (shl 0 A 1)) ) )
         (pop P) )
      (let X (+ N N)  # Shift left
         (if @@  # Overflow
            (boxNum (shr N 3))  # Make big
            (x| X 6) ) ) ) )  # Fix tag bit

# Divide (unsigned) number by 2
(de shru (N)
   (if (big? N)
      (let (A (shr (val (dig N)) 1)  X (val (big N)))
         (if (big? X)
            (let
               (B (val (dig X))
                  Y (boxNum (| (shr B 0 1) A))
                  P (link (push Y T NIL)) )
               (loop
                  (setq A B  N X)
                  (? (cnt? (setq X (big X))))
                  (setq
                     B (val (dig X))
                     Y
                     (set (big Y)
                        (boxNum (| (shr B 0 1) A)) ) ) )
               (setq A (| (shr X 0 5) A))
               (set (big Y)
                  (if
                     (and
                        (=0 (setq X (shr X 5)))
                        (=0 (& A (hex "F000000000000000"))) )
                     (cnt A)
                     (prog1
                        (boxNum A)
                        (set (big @) (cnt X)) ) ) )
               (pop P) )
            (setq A (| (shr X 0 5) A))
            (if
               (and
                  (=0 (setq X (shr X 5)))
                  (=0 (& A (hex "F000000000000000"))) )
               (cnt A)
               (prog1
                  (boxNum A)
                  (set (big @) (cnt X)) ) ) ) )
      (| (& (shr N 1) -10) 2) ) )  # (not 9) Clear lowest bit and tag

#{
# Bitwise AND of two (unsigned) numbers
(de andu (N)
   )

# Bitwise OR of two (unsigned) numbers
(de oru (N)
   )

# Bitwise XOR of two (unsigned) numbers
(de xoru (N)
   )
}#

# Add two (unsigned) numbers
(de addu (A B)
   (cnt (+ (int A) (int B))) )

# Subtract two (unsigned) numbers
(de subu (A B)
   (cnt (- (int A) (int B))) )


(de incs (A)
   (if (sign? A)
      (let B (subu (pos A) ONE)
         (if (== B ZERO) B (sign B)) )
      (addu A ONE) ) )

(de decs (A)
   (if (sign? A)
      (let B (addu (pos A) ONE)
         (if (== B ZERO) B (sign B)) )
      (subu A ONE) ) )

(de i32 cmpu (X Y)
   (if (cnt? X)  # X is short
      (cond T
         ((big? Y) (i32 -1))  # Y is big
         ((== Y X) (i32 0))  # X = Y
         ((> Y X) (i32 -1))
         (T (i32 +1)) )
      (if (cnt? Y)  # X is big and Y short
         (i32 +1)
         (i32 0) ) ) )

(de i32 cmpNum (X Y)
   (ifn (sign? X)  # X positive
      (ifn (sign? Y)  # Y also positive
         (cmpu X Y)  # compare unsigned
         (i32 +1) )  # else X is greater
      (ifn (sign? Y)  # X negative, Y positive
         (i32 -1)
         (cmpu (pos Y) (pos X)) ) ) )

(de symToNum (Name (i32 . Scl) (i32 . Sep) (i32 . Ign))
   (let
      (P (push 0 (i64 Name))  # [cnt name]
         Num (push ZERO T NIL)  # Result
         B (numByte P)
         Sign NO
         Frac NO )
      (while (>= (char " ") B)  # Skip white space
         (when (=0 B)  # None
            (ret 0) )
         (setq B (numByte P)) )
      (cond
         ((== B (char "+"))
            (goto 1) )
         ((== B (char "-"))
            (setq Sign YES)
            (: 1
               (when (=0 (setq B (numByte P)))
                  (ret 0) ) ) ) )
      (when (>= (setq B (- B (char "0"))) 10)
         (ret 0) )
      (set (link Num) (cnt (i64 B)))
      (while (n0 (setq B (numByte P)))
         (when (>= (setq B (- B (char "0"))) 10)
            (drop Num)
            (ret 0) )
         (set Num
            (addu
               (tenfold (val Num))
               (cnt (i64 B)) ) ) )
      (cond T
         ((== ZERO (setq Num (pop Num))) ZERO)
         (Sign (sign Num))
         (T Num) ) ]

# (+ 'num ..) -> num
(de _add (Exe)
   (let (X Exe  A (eval (car (>>> X))))
      (if (nil? A)
         A
         (let R (link (push (needNum Exe A) ZERO NIL))
            (while (pair (>>> X))
               (let B (eval (car X))
                  (? (nil? B) (set R B))
                  (set R (addu (val R) (needNum Exe B))) ) )
            (pop R) ) ) ) )

# (- 'num ..) -> num
(de _sub (Exe)
   (let (X Exe  A (eval (car (>>> X))))
      (if (nil? A)
         A
         (let R (link (push (needNum Exe A) ZERO NIL))
            (while (pair (>>> X))
               (let B (eval (car X))
                  (? (nil? B) (set R B))
                  (set R (subu (val R) (needNum Exe B))) ) )
            (pop R) ) ) ) )

# (inc 'num) -> num
# (inc 'var ['num]) -> num
(de _inc (X)
   (let (L (cdr X)  A (eval (car L)))
      (if (nil? A)
         A
         (save A T
            (if (num? A)
               (incs A)
               ZERO
               ]

# (dec 'num) -> num
# (dec 'var ['num]) -> num
(de _dec (X)
   (let (L (cdr X)  A (eval (car L)))
      (if (nil? A)
         A
         (save A T
            (if (num? A)
               (decs A)
               ZERO
               ]
