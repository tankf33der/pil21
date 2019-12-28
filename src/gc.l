# 28dec19 Software Lab. Alexander Burger

(compile) (mark gc cons consSym boxNum box64 consNum)

(de void mark (E)
   (let X 0  # Clear TOS
      (loop
         (until (cnt? E)
            (let P (any (& E -16))  # Cell pointer
               (? (=0 (& (cdr P) 1)))  # Already marked
               (set 2 P (& (cdr P) -2))  # Mark cell
               (? (big? E)
                  (let Y (val (big E))
                     (until (cnt? Y)
                        (let Z (val (big Y))  # Mark big digits
                           (set (big Y) (& Z -2))  # Mark
                           (setq Y Z) ) ) ) )  # Next digit
               (let Y E  # Previous item
                  (setq E (val P))  # Get CAR
                  (set P (| X 1))  # Keep TOS first visit
                  (setq X Y) ) ) )  # TOS on previous
         (let P NIL
            (loop
               (setq P (any (& X -16)))  # TOS cell pointer
               (and (=0 P) (ret))  # Empty
               (? (=0 (& (val P) 1)))  # Second visit
               (let Tmp X
                  (setq X (cdr P))  # TOS up
                  (set 2 P E)  # Restore CDR
                  (setq E Tmp) ) )  # E up
            (let Y (val P)  # Up pointer
               (set P E)  # Restore CAR
               (setq E (cdr P))  # Get CDR
               (set 2 P (& Y -2)) ) ) ) ) )  # Store up pointer

(de void gc ()
   #{..}#
   (val $Heaps)
   )

# (gc ['cnt [cnt2]]) -> cnt | NIL
(de _gc (Exe)
   (let (X (cdr Exe)  Y (eval (++ X)))  # MiBs
      (set $At $Nil  $At2 $Nil)
      (cond
         ((nil? Y) (gc))
         (T
            (set $GcCount (shl (xCnt Exe Y) 16))  # Multiply with CELLS
            (gc)
            (set $GcCount
               (if (atom X)
                  CELLS
                  (shl (evCnt Exe X) 16) ) ) ) )  # New default
      Y ) )

(de cons (Car Cdr)
   (let P (val $Avail)
      (when (=0 P)
         (let A (save Car Cdr)
            (gc) )
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Car)
      (set 2 P Cdr)
      P ) )

(de consSym (Name Val)
   (if (== Name ZERO)
      $Nil
      (let P (val $Avail)
         (when (=0 P)
            (let A (save Name Val)
               (gc) )
            (setq P (val $Avail)) )
         (set $Avail (car P))
         (set P Name)
         (prog1
            (sym P)
            (set @ (if (=0 Val) @ Val)) ) ) ) )

(de boxNum (Dig)
   (let P (val $Avail)
      (when (=0 P)
         (gc)
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Dig)
      (set 2 P ZERO)
      (big P) ) )

(de box64 (N)
   (if (=0 (& N (hex "F000000000000000")))  # Fit in short number
      (cnt N)
      (boxNum N) ) )

(de consNum (Dig Big)
   (let P (val $Avail)
      (when (=0 P)
         (let A (save Big)
            (gc) )
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Dig)
      (set 2 P Big)
      (big P) ) )
