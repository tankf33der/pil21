# 28dec19 Software Lab. Alexander Burger

(compile) (apply)

(de apply (Exe Fun Lst)
   $T )

# (apply 'fun 'lst ['any ..]) -> any
(de _apply (Exe)
   (let (X (cdr Exe)  Fun (save (eval (++ X)))  Lst (save (eval (++ X))))
      (apply Exe Fun Lst)
      $T ]
