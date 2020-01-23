# 22jan20 Software Lab. Alexander Burger

(compile) (numByte numChar byteNum charNum zapZero twiceBig twice half tenfold
shlu shru andu oru xoru addu subu incs decs cmpu cmpNum symToNum fmtWord fmtNum)

### Bignum byte access ###
(de i8 numByte ((i64* . P))
   (let C (val P)  # Get cnt
      (when (=0 C)  # New round
         (let Nm (val 2 P)
            (cond
               ((== Nm ZERO) (ret (i8 0)))  # Done
               ((cnt? Nm)  # Short
                  (setq C (shr Nm 4))
                  (set 2 P ZERO) )
               (T  # Big: Next digit
                  (setq C (set P (val (dig Nm))))
                  (set 2 P (val (big Nm))) ) ) ) )
      (set P (shr C 8))
      (i8 C) ) )

(de i32 numChar ((i64* . P))
   (let C (i32 (numByte P))
      (cond
         ((>= 127 C) C)  # Single byte
         ((== C (hex "FF")) (i32 TOP))  # Infinite
         (T
            (|
               (shl
                  (if (=0 (& C (hex "20")))
                     (& C (hex "1F"))
                     (|
                        (shl
                           (if (=0 (& C (hex "10")))
                              (& C (hex "0F"))
                              (|
                                 (shl (& C (hex "7")) 6)
                                 (& (i32 (numByte P)) (hex "3F")) ) )
                           6 )
                        (& (i32 (numByte P)) (hex "3F")) ) )
                  6 )
               (& (i32 (numByte P)) (hex "3F")) ) ) ) ) )

(de void byteNum ((i32 . C) (i64* . P))
   (let (Cnt (val P)  Name (val 2 P))
      (unless (big? Name)  # Short name
         # 0000.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx.xxxxxxx0010
         #   60      52      44      36      28      20      12       4
         (when (> 60 Cnt)  # Digit not full
            (set 2 P
               (| Name (shl (i64 C) Cnt)) )
            (set P (+ Cnt 8))
            (ret) )
         (set 3 P
            (set 2 P
               (boxNum  # Make big
                  (|  # Combine byte with digit
                     (shr Name 4)  # De-normalize short number
                     (shl (i64 C) 56) ) ) ) )  # Adjust byte
         (set P 4)  # Start new digit
         (ret) )
      (let (Q (val 3 P)  N (val (big Q)))
         (when (> 60 Cnt)  # Digit not full
            (set
               (big Q)
               (| N (shl (i64 C) Cnt)) )
            (set P (+ Cnt 8))
            (ret) )
         (set 3 P
            (set (big Q)
               (boxNum  # Make big
                  (|  # Combine byte with digit
                     (shr N 4)  # De-normalize short number
                     (shl (i64 C) 56) ) ) ) )  # Adjust byte
         (set P 4) ) ) )  # Start new digit

(de void charNum ((i32 . C) (i64* . P))
   (cond
      ((>= 127 C) (byteNum C P))  # Single byte
      ((== TOP C) (byteNum (hex "FF") P))  # Infinite
      (T
         (cond
            ((> (hex "800") C)  # Double-byte
               (byteNum (| (hex "C0") (& (shr C 6) (hex "1F"))) P) )  # 10xxxxx 10xxxxxx
            ((> (hex "10000") C)  # Three bytes
               (byteNum (| (hex "E0") (& (shr C 12) (hex "0F"))) P)  # 1110xxxx 10xxxxxx 10xxxxxx
               (byteNum (| (hex "80") (& (shr C 6) (hex "3F"))) P) )
            (T
               (byteNum (| (hex "F0") (& (shr C 18) (hex "07"))) P)  # 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
               (byteNum (| (hex "80") (& (shr C 12) (hex "3F"))) P)
               (byteNum (| (hex "80") (& (shr C 6) (hex "3F"))) P) ) )
         (byteNum (| (hex "80") (& C (hex "3F"))) P) ) ) )

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
      (let X (add N N)  # Shift left
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
   (if (cnt? N)
      (box64 (* 10 (int N)))
      (let (X N  A (mul 10 (val (dig X)))  B @@)
         (loop
            (set (dig X) A)
            (? (cnt? (setq A (val (big X)))))
            (setq X A  A (mul 10 (val (dig X))))
            (let C @@
               (setq A (add A B)  B (add C @@)) ) )
         (set (big X)
            (box64 (+ B (mul 10 (int A)))) )
         N ) ) )

### Non-destructive primitives ###
# Multiply (unsigned) number by 2
(de shlu (N)
   (if (big? N)
      (let
         (A (val (dig N))
            X (boxNum (shl A 1))
            Y (val (big N))
            P (link (push X NIL)) )
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
      (let X (add N N)  # Shift left
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
                  P (link (push Y NIL)) )
               (loop
                  (setq A B  N X)
                  (? (cnt? (setq X (val (big X)))))
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
   (if (cnt? A)
      # A is short
      (if (cnt? B)
         (box64 (+ (int A) (int B)))
         (xchg 'A 'B)
         (goto 1) )
      # A is big
      (if (cnt? B)
         (: 1
            (let N (val (big A))
               (setq B (add (val (dig A)) (int B)))
               (ifn @@
                  (consNum B N)  # No carry
                  (let P (link (push (setq B (consNum B N)) NIL))  # Else build new head
                     (loop
                        (? (cnt? N)
                           (setq N (add N (hex "10")))  # Add carry
                           (set (big B)
                              (ifn @@  # No further carry
                                 N  # Append it
                                 (boxNum (| (int N) (hex "1000000000000000"))) ) ) )  # Set top bit
                        (let D (val (dig N))  # Next digit
                           (setq
                              N (val (big N))
                              D (add D 1) )  # Add carry
                           (? (not @@)  # No carry
                              (set (big B) (consNum D N)) )
                           (setq B (set (big B) (consNum D N))) ) )
                     (pop P) ) ) ) )
         # Both are big
         (let P (link (push ZERO NIL))  # Result
            (pop P) ) ) ) )

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
      (cond
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

# Make number from symbol
(de symToNum (Name (i32 . Scl) (i32 . Sep) (i32 . Ign))
   (let
      (P (push 0 (i64 Name))  # [cnt name]
         Num (push ZERO NIL)  # Result
         Sign NO
         Frac NO
         B NIL )
      (while (>= (char " ") (setq B (numByte P)))  # Skip white space
         (when (=0 B)  # None
            (ret 0) ) )
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
      (until (=0 (setq B (numByte P)))
         (when (>= (setq B (- B (char "0"))) 10)
            (drop Num)
            (ret 0) )
         (set Num
            (addu
               (tenfold (val Num))
               (cnt (i64 B)) ) ) )
      (cond
         ((== ZERO (setq Num (pop Num))) ZERO)
         (Sign (sign Num))
         (T Num) ) ]

(de i32 fmtWord ((i64 . N) (i32 . Scl) (i32 . Sep) (i32 . Ign) (i64* . P))
   (when (> N 9)
      (setq Scl (fmtWord (/ N 10) Scl Sep Ign P))
      (cond
         ((=0 Scl) (charNum Sep P))
         ((and (n0 Ign) (gt0 Scl) (=0 (% Scl 3)))
            (charNum Ign P) ) )
      (dec 'Scl)
      (setq N (% N 10)) )
   (byteNum (+ (i32 N) (char "0")) P)
   Scl )

# Format number to output, length, or symbol
(de fmtNum (Num (i32 . Scl) (i32 . Sep) (i32 . Ign) (i64* . P))
   (let (Sign (sign? Num)  Len (i32 (+ 19 17)))  # Length of 'cnt' (60 bit) plus round up div/18
      # Calculate buffer size
      (let N (setq Num (& Num -9))  # Clear sign bit
         (until (cnt? N)  # Calculate length
            (setq Len (+ Len 20)  N (val (big N))) ) )  # Add length of 'digit'
      (setq Len (/ Len 18))  # Divide by 18 (rounded), word count
      (let (Acc (b64 Len)  TopA Acc)
         # Build BCD
         (let (Inc (b64 Len)  TopI Inc)
            (set Acc 0  Inc 1)  # Init accumulator to 0 and incrementor to 1
            (loop
               (let (Dig Num  Mask 16)
                  (when (big? Num)  # and first digit and mask
                     (setq Dig (val (dig Num))  Mask 1) )
                  (loop
                     (unless (=0 (& Dig Mask))  # Bit is set
                        # Add incrementor to accumulator
                        (let (A Acc  I Inc  C 0)  # Carry for BCD addition
                           (loop
                              (let N (+ (val A) (val I) C)  # Add BCDs and Carry
                                 (setq C
                                    (if (> 1000000000000000000 N)
                                       0
                                       (setq N (- N 1000000000000000000))  # BCD overflow
                                       1 ) )
                                 (set A N) )
                              (? (> (inc 'I) TopI))
                              (when (> (inc 'A) TopA)
                                 (inc 'TopA)  # Extend accumulator
                                 (set A 0) ) )  # with 0
                           (unless (=0 C) # BCD-Carry
                              (set (inc 'TopA) 1) ) ) )  # Extend accumulator with 1
                     # Shift incrementor left
                     (let (I Inc  C 0)
                        (loop
                           (let N (val I)
                              (setq C
                                 (if (> 1000000000000000000 (setq N (+ N N C)))  # Double digit
                                    0
                                    (setq N (- N 1000000000000000000))  # BCD overflow
                                    1 ) )
                              (set I N) )
                           (? (> (inc 'I) TopI)) )
                        (unless (=0 C) # BCD-Carry
                           (inc 'TopI)  # Extend incrementor
                           (set I 1) ) )  # with 1
                     (? (=0 (setq Mask (shl Mask 1)))) ) )
               (? (cnt? Num))
               (setq Num (val (big Num))) ) )
         (cond
            ((ge0 Scl)  # Build symbol
               (when Sign
                  (byteNum (char "-") P) )
               (let N (* (shr (i32 (- TopA Acc)) 3) 18)  # Calculate length~1
                  (let D (val TopA)
                     (until (=0 (setq D (/ D 10)))
                        (inc 'N) ) )
                  (when (lt0 (setq Scl (- N Scl)))
                     (byteNum (char "0") P)
                     (byteNum Sep P)
                     (while (> -1 Scl)
                        (inc 'Scl)
                        (byteNum (char "0") P) ) ) )
               (setq Scl (fmtWord (val TopA) Scl Sep Ign P))  # Pack highest word
               (while (>= (dec 'TopA) Acc)
                  (let (N (val TopA)  D 100000000000000000)
                     (loop
                        (cond
                           ((=0 Scl) (charNum Sep P))
                           ((and (n0 Ign) (gt0 Scl) (=0 (% Scl 3)))
                              (charNum Ign P) ) )
                        (dec 'Scl)
                        (byteNum (+ (i32 (/ N D)) (char "0")) P)
                        (setq N (% N D))
                        (? (== 1 (setq D (/ D 10)))) )
                     (byteNum (+ (i32 N) (char "0")) P) ) )
               0 )
            ((== Scl -1)  # Direct print
               (when Sign
                  (call $Put (char "-")) )  # Output sign
               (outWord (val TopA))  # Output highest word
               (while (>= (dec 'TopA) Acc)
                  (let (N (val TopA)  D 100000000000000000)
                     (loop
                        (call $Put (+ (i32 (/ N D)) (char "0")))  # Output next digit
                        (setq N (% N D))
                        (? (== 1 (setq D (/ D 10)))) )
                     (call $Put (+ (i32 N) (char "0"))) ) )  # Output last digit
               0 )
            (T  # Calculate length
               (let (N (* (shr (- TopA Acc) 3) 18)  D (val Acc))
                  (loop
                     (inc 'N)
                     (? (=0 (setq D (/ D 10)))) )
                  (when Sign
                     (inc 'N) )
                  (cnt N) ) ) ) ) ) )

# (+ 'num ..) -> num
(de _add (Exe)
   (let (X (cdr Exe)  A (eval (++ X)))
      (if (nil? A)
         A
         (let R (link (push (needNum Exe A) NIL))
            (while (pair X)
               (let B (eval (++ X))
                  (? (nil? B) (set R B))
                  (set R (addu (val R) (needNum Exe B))) ) )
            (pop R) ) ) ) )

# (- 'num ..) -> num
(de _sub (Exe)
   (let (X (cdr Exe)  A (eval (++ X)))
      (if (nil? A)
         A
         (let R (link (push (needNum Exe A) NIL))
            (while (pair X)
               (let B (eval (++ X))
                  (? (nil? B) (set R B))
                  (set R (subu (val R) (needNum Exe B))) ) )
            (pop R) ) ) ) )

# (inc 'num) -> num
# (inc 'var ['num]) -> num
(de _inc (Exe)
   (let (X (cdr Exe)  A (save (eval (++ X))))
      (if (nil? A)
         A
         (if (num? A)
            (incs A)
            ZERO
            ]

# (dec 'num) -> num
# (dec 'var ['num]) -> num
(de _dec (Exe)
   (let (X (cdr Exe)  A (save (eval (++ X))))
      (if (nil? A)
         A
         (if (num? A)
            (decs A)
            ZERO
            ]
