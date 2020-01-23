# 23jan20 Software Lab. Alexander Burger

(compile) (mark gc cons consSym boxNum box64 consNum)

(de void mark (E)
   (let X 0  # Clear TOS
      (loop
         (until (cnt? E)
            (let P (any (& E -16))  # Cell pointer
               (? (=0 (& (cdr P) 1)))  # Already marked
               (set 2 P (& (cdr P) -2))  # Mark cell
               (? (big? E)
                  (let Y (cdr P)
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
   (set $DB ZERO)  # Cut off DB root
   # Prepare
   (let P $Nil  # Symbol table
      (set P (| (val P) 1))  # Set mark bit
      (setq P (ofs P 4))  # Skip NIL tail
      (loop
         (set P (| (val P) 1))  # Set mark bit
         (? (== P $LastSym))
         (setq P (ofs P 2)) ) )  # Next symbol
   (let P (val $Heaps)
      (loop
         (let C CELLS
            (loop
               (set 2 P (| (cdr P) 1))  # Set mark bit
               (? (=0 (dec 'C)))
               (setq P (ofs P 2)) ) )  # Next cell
         (setq P (val P))  # Next heap
         (? (=0 P)) ) )
   # Mark
   (let P (any (gcData))  # Globals
      (loop
         (mark (val P))  # Mark
         (? (== P $LispEnd))
         (>>> P) ) )  # Next global
   (mark $Intern)  # Current namespaces
   (let P (val $Link)  # Stack(s)
      (until (=0 P)
         (mark (val P))  # Mark item
         (>>> P) ) )
   (let Ca (val $Catch)  # Catch frames
      (until (=0 Ca)
         (let Ca: (caFrame Ca)
            (unless (=0 (Ca: tag))  # Mark 'tag'
               (mark (Ca: tag)) )
            (mark (Ca: fin))  # Mark 'fin'
            (mark (Ca: (env $Intern any)))
            (setq Ca (Ca: link)) ) ) )
   (let Crt (val $Coroutines)  # Coroutines
      (until (=0 Crt)
         (let Crt: (coroutine Crt)
            (unless (or (=0 (Crt: tag)) (=0 (Crt: at)))
               (mark (Crt: tag))
               (mark (Crt: prg))
               (mark (Crt: at))
               (mark (Crt: (env $Intern any)))
               (let P (Crt: (env $Link any))
                  (until (=0 P)
                     (mark (val P))
                     (>>> P) ) )
               (let Ca (Crt: (env $Catch))
                  (until (=0 Ca)
                     (let Ca: (caFrame Ca)
                        (unless (=0 (Ca: tag))  # Mark 'tag'
                           (mark (Ca: tag)) )
                        (mark (Ca: fin))
                        (mark (Ca: (env $Intern any)))
                        (setq Ca (Ca: link)) ) ) )
               (setq Crt (Crt: next)) ) ) ) )
   (let (P (val $Extern)  X 0)  # Externals
      (loop
         (loop
            (set 2 P (& (cdr P) -2))  # Clear mark bit
            (let (Y (cdr P)  Z (cdr Y))  # Right subtree
               (set 2 Y (& Z -2))  # Clear mark bit
               (? (atom Z))
               (let Tmp P  # Go right
                  (setq P Z)  # Invert tree
                  (set 2 Y X)  # TOS
                  (setq X Tmp) ) ) )
         (loop
            (let S (val P)  # Get external symbol
               (unless (=0 (& (val S) 1))  # Not marked
                  (let N (val (tail S))
                     (unless (num? N)  # Has properties
                        (setq N (& N -10))  # Clear 'extern' tag and mark bit
                        (until (num? (setq N (cdr N)))  # Skip property
                           (setq N (& N -2)) ) )  # Clear mark bit
                     (add N N)  # Get carry
                     (when @@  # Dirty or deleted
                        (mark S) ) ) ) )
            (let (Y (cdr P)  Z (car Y))  # Left subtree
               (? (atom Z)
                  (let Tmp P  # Go left
                     (setq P Z)  # Invert tree
                     (set Y X)  # TOS
                     (setq X (sym Tmp)) ) ) )  # First visit
            (loop
               (when (=0 X)  # TOS
                  (goto 1) )
               (? (sym? X)  # Second visit
                  (let Y (cdr X)  # Nodes
                     (setq X (cdr Y))  # TOS on up link
                     (set 2 Y P)
                     (setq P X) ) )
               (setq X (& X -9))  # Clear 'sym' bit
               (let Y (cdr X)  # Nodes
                  (setq X (car Y))
                  (set Y P)
                  (setq P X) ) ) ) ) )
   (: 1
      (set $DB $Db1)  # Restore DB root
      (unless (=0 (& (val $Db1) 1))  # Not marked
         (set
            $Db1 $Nil  # Clear
            (tail $Db1) DB1 ) ) )  # Set to "not loaded"
   (let (P (val $Extern)  X 0)  # Externals
      (: 2
         (loop
            (loop
               (let (Y (cdr P)  Z (cdr Y))  # Right subtree
                  (? (atom Z))
                  (let Tmp P  # Go right
                     (setq P Z)  # Invert tree
                     (set 2 Y X)  # TOS
                     (setq X Tmp) ) ) )
            (loop
               (unless (=0 (& (val (val P)) 1))  # External symbol not marked
                  (set $ExtCnt (- (val $ExtCnt) 1))
                  #!
                  )
               (: 3
                  (let (Y (cdr P)  Z (car Y))  # Left subtree
                     (? (atom Z)
                        (let Tmp P  # Go left
                           (setq P Z)  # Invert tree
                           (set Y X)  # TOS
                           (setq X (sym Tmp)) ) ) ) )  # First visit
               (: 4
                  (loop
                     (when (=0 X)  # TOS
                        (goto 5) )
                     (? (sym? X)  # Second visit
                        (let Y (cdr X)  # Nodes
                           (setq X (cdr Y))  # TOS on up link
                           (set 2 Y P)
                           (setq P X) ) )
                     (setq X (& X -9))  # Clear 'sym' bit
                     (let Y (cdr X)  # Nodes
                        (setq X (car Y))
                        (set Y P)
                        (setq P X) ) ) ) ) ) )
      (: 5 (set $Extern P)) )
   # Sweep
   #!
   )

# (gc ['cnt [cnt2]]) -> cnt | NIL
(de _gc (Exe)
   (let (X (cdr Exe)  Y (eval (++ X)))  # MiBs
      (set $At $Nil  $At2 $Nil)
      (if (nil? Y)
         (gc)
         (set $GcCount (shl (xCnt Exe Y) 16))  # Multiply with CELLS
         (gc)
         (set $GcCount
            (if (atom X)
               CELLS
               (shl (evCnt Exe X) 16) ) ) )  # New default
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
