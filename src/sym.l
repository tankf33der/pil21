# 10nov19 Software Lab. Alexander Burger

(compile) (name bufSize pathSize bufString pathString cmpLong mkStr intern
findSym isIntern)

(de name (Tail)
   (setq Tail (any (& (i64 Tail) -9)))  # Clear 'extern' tag
   (until (num? Tail)
      (>>> Tail) )
   Tail )

(de i32 bufSize (Sym)
   (let (X (name (val (tail Sym)))  N (i32 1))
      (while (big? X)
         (setq N (+ N 8)  X (val (big X))) )
      (setq X (int X))
      (until (=0 X)
         (inc 'N)
         (setq X (shr X 8)) )
      N ) )

(de i32 pathSize (Sym)
   (bufSize Sym) )  #!

(de i8* bufString (X (i8* . P))
   (let (Q (push 0 (i64 (name (val (tail X)))))  B (numByte Q))  # [cnt name]
      (prog1 P
         (until (=0 (set P B))
            (inc 'P)
            (setq B (numByte Q)) ) ) ) )

(de i8* pathString (X (i8* . P))
   (bufString X P) )  #!

(de i32 cmpLong (X Y)
   (loop T
      (? (n0 (- (val (dig X)) (val (dig Y))))
         (if @@ (i32 -1) (i32 +1)) )
      (setq X (val (big X))  Y (val (big Y)))
      (? (cnt? X)
         (cond T
            ((big? Y) (i32 -1))
            ((== Y X) (i32 0))
            ((> Y X) (i32 -1))
            (T (i32 +1)) ) )
      (? (cnt? Y) (i32 +1)) ) )

(de mkStr ((i8* . Str))
   (if (=0 Str)
      $Nil
      (let C (val Str)
         (if (=0 C)
            $Nil
            (let (P (push 4 ZERO T NIL)  Q (link (any (i P))))  # [cnt name cell]
               (byteNum (i32 C) P)
               (until (=0 (setq C (val (inc 'Str))))
                  (byteNum (i32 C) P) )
               (prog1
                  (consSym (val Q) 0)
                  (drop Q) ) ) ) ) ) )

(de intern (Sym Val Name Tree More)
   (when (cnt? Name)  # Short name
      (let X (car Tree)  # First tree
         (when (atom X)  # Empty
            # .. check More
            (when (=0 Sym)  # New symbol
               (setq Sym (consSym Name Val)) )
            (set Tree (cons Sym $Nil))
            (ret Sym) )
         (loop
            (let Nm (name (val (tail (car X))))
               (cond
                  ((== Name Nm) (ret (car X)))  # Found symbol
                  ((> Name Nm)  # Symbol is smaller
                     (when (atom (cdr X))  # No link yet
                        # .. check More
                        (when (=0 Sym)  # New symbol
                           (setq Sym (consSym Name Val)) )
                        (set (i X) (cons $Nil (cons Sym $Nil)))
                        (ret Sym) )
                     (if (pair (cdr (>>> X)))
                        (setq X (cdr X))
                        # .. check More
                        (when (=0 Sym)  # New symbol
                           (setq Sym (consSym Name Val)) )
                        (set (i X) (cons Sym $Nil))
                        (ret Sym) ) )
                  (T  # Symbol is greater
                     (when (atom (cdr X))  # No link yet
                        # .. check More
                        (when (=0 Sym)  # New symbol
                           (setq Sym (consSym Name Val)) )
                        (set (i X) (cons (cons Sym $Nil) $Nil))
                        (ret Sym) )
                     (if (pair (car (>>> X)))
                        (setq X (car X))
                        # .. check More
                        (when (=0 Sym)  # New symbol
                           (setq Sym (consSym Name Val)) )
                        (set X (cons Sym $Nil))
                        (ret Sym) ) ) ) ) ) ) )
   # Long name
   (let X (cdr Tree)  # Second tree
      (when (atom X)  # Empty
         # .. check More
         (when (=0 Sym)  # New symbol
            (setq Sym (consSym Name Val)) )
         (set (i Tree) (cons Sym $Nil))
         (ret Sym) )
      (loop
         (let (Nm (name (val (tail (car X))))  I (cmpLong Nm Name))
            (cond
               ((=0 I) (ret (car X)))  # Found symbol
               ((lt0 I)  # Symbol is smaller
                  (when (atom (cdr X))  # No link yet
                     # .. check More
                     (when (=0 Sym)  # New symbol
                        (setq Sym (consSym Name Val)) )
                     (set (i X) (cons $Nil (cons Sym $Nil)))
                     (ret Sym) )
                  (if (pair (cdr (>>> X)))
                     (setq X (cdr X))
                     # .. check More
                     (when (=0 Sym)  # New symbol
                        (setq Sym (consSym Name Val)) )
                     (set (i X) (cons Sym $Nil))
                     (ret Sym) ) )
               (T  # Symbol is greater
                  (when (atom (cdr X))  # No link yet
                     # .. check More
                     (when (=0 Sym)  # New symbol
                        (setq Sym (consSym Name Val)) )
                     (set (i X) (cons (cons Sym $Nil) $Nil))
                     (ret Sym) )
                  (if (pair (car (>>> X)))
                     (setq X (car X))
                     # .. check More
                     (when (=0 Sym)  # New symbol
                        (setq Sym (consSym Name Val)) )
                     (set X (cons Sym $Nil))
                     (ret Sym) ) ) ) ) ) ) )

(de i1 isIntern (Sym Name Tree More)
   (if (cnt? Name)  # Short name
      (let X (car Tree)  # First tree
         (loop
            (when (atom X)  # Empty
               # .. check More
               (ret NO) )
            (let Nm (name (val (tail (car X))))
               (? (== Name Nm))
               (setq X
                  (if (> Name Nm)  # Symbol is smaller
                     (cddr X)
                     (cadr X) ) ) ) )
         (cond
            ((=0 Sym)  # No symbol given
               (set $FoundSym (car X)) )  # Found one
            ((<> Sym (car X))  # Different Symbol
               (ret NO)  # .. check More
               ) )
         YES )
      # Long name
      (let X (cdr Tree)  # Second tree
         (loop
            (when (atom X)  # Empty
               # .. check More
               (ret NO) )
            (let (Nm (name (val (tail (car X))))  I (cmpLong Nm Name))
               (? (=0 I))
               (setq X
                  (if (lt0 I)  # Symbol is smaller
                     (cddr X)
                     (cadr X) ) ) ) )
         (cond
            ((=0 Sym)  # No symbol given
               (set $FoundSym (car X)) )  # Found one
            ((<> Sym (car X))  # Different Symbol
               (ret NO)  # .. check More
               ) )
         YES ) ) )

(de findSym (Name)
   (intern 0 $Nil Name
      (val (car (val $Intern)))
      (cdr (val $Intern)) ) )