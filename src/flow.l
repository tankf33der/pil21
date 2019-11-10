# 01nov19 Software Lab. Alexander Burger

(compile) (redefine)

(de redefine (Ex S X)
   (set S X)
   )

# (quote . any) -> any
(de _quote (X)
   (cdr X) )

# (de sym . any) -> sym
(de _de (X)
   (let S (cadr X)
      (redefine X S (cddr X))
      S ) )

# (meth 'obj ['any ..]) -> any
(de _meth (X)
   X )

# (and 'any ..) -> any
(de _and (X)
   (>>> X)
   (loop T
      (let A (eval (car X))
         (? (nil? A) A)
         (set $At A)
         (? (atom (>>> X)) A) ) ) )

# (if 'any1 any2 . prg) -> any
(de _if (X)
   (>>> X)
   (let A (eval (++ X))
      (if (nil? A)
         (run (cdr X))
         (set $At A)
         (eval (car X)) ) ) )

# (bye ['cnt])
(de _bye (X)
   (let N (eval (cadr X))
      (bye
         (if (nil? N)
            0
            (i32 (int N)) ) ) ) )
