# 28dec19 Software Lab. Alexander Burger

(compile) (apply)

(de apply (Exe Fun Lst)
   $T )

# (apply 'fun 'lst ['any ..]) -> any
(de _apply (Exe)
   (let
      (X (cdr Exe)
         Fun (save (eval (++ X)))
         Lst (eval (++ X))
         P (link (push Lst NIL)) )
      (when (pair X)
         (let Q Lst
            (setq Lst
               (setq P
                  (set P (push (eval (++ X)) Q)) ) )
            (while (pair X)
               (setq P
                  (set 2 P (push (eval (++ X)) Q)) ) ) ) )
      (apply Exe Fun Lst) ) )
