# 26dec19 Software Lab. Alexander Burger

(compile) (mark gc cons)

(de void mark (X)
   #{..}#
   (mark X) )

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
         (save Car Cdr
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
            (save Name Val
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
         (save Big T
            (gc) )
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Dig)
      (set 2 P Big)
      (big P) ) )
