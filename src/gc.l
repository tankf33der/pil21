# 15oct19 Software Lab. Alexander Burger

(compile) (mark gc cons)

(de void mark (X)
   #{..}#
   (mark X) )

(de void gc ((i64 . C))
   #{..}#
   (val $Heaps)
   )

# (gc ['cnt]) -> cnt | NIL
(de $gc (X)
   #{..}#
   (gc CELLS)
   $Nil )

(de cons (Car Cdr)
   (let P (val $Avail)
      (when (=0 P)
         (save Car Cdr
            (gc CELLS) )
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Car)
      (set (i P) Cdr)
      P ) )

(de consSym (Name Val)
   #? ZERO name -> NIL
   (let P (val $Avail)
      (when (=0 P)
         (save Name Val
            (gc CELLS) )
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Name)
      (prog1
         (sym P)
         (set @ (if (=0 Val) @ Val)) ) ) )

(de boxNum (Dig)
   (let P (val $Avail)
      (when (=0 P)
         (gc CELLS)
         (setq P (val $Avail)) )
      (set $Avail (car P))
      (set P Dig)
      (set (i P) ZERO)
      (big P) ) )

(de box64 (N)
   (if (=0 (& N (hex "F000000000000000")))  # Fit in short number
      (cnt N)
      (boxNum N) ) )
