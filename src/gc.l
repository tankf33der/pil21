# 27dec19 Software Lab. Alexander Burger

(compile) (mark gc cons consSym boxNum box64 consNum)

(de void mark (Exe)
   (let X 0
      (loop
         (until (cnt? Exe)
            (let P (any (& Exe -16))
               (? (=0 (& P 1)))  # Already marked
               (set 2 P (& (cdr P) -2))  # Mark cell
               (? (big? Exe)
                  (let Y (cdr P)
                     (until (cnt? Y)
                        (let Z (big Y)
                           (? (=0 (& (val Z) 1)))  # Marked
                           (set Z (& (val Z) -2))  # Mark
                           (setq Y Z) ) ) ) )  # Next digit
               )
            ) ) ) )

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
         (save Car (save Cdr (gc)))
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
            (save Name (save Val (gc)))
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
         (save Big (gc))
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Dig)
      (set 2 P Big)
      (big P) ) )
