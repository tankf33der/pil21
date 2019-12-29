# 29dec19 Software Lab. Alexander Burger

(compile) ()

# (apply 'fun 'lst ['any ..]) -> any
(de _apply (X)
   (>>> X)
   (let Exe (save (push NIL $Nil ZERO (eval (++ X))))
      (set Exe (ofs Exe 3))
      (let (Lst (save+ (eval (++ X)))  P Exe)
         (while (pair X)
            (setq P
               (set 2 P
                  (push NIL $Nil ZERO (eval (++ X))) ) )
            (set P (ofs P 3)) )
         (while (pair Lst)
            (setq P
               (set 2 P (push NIL $Nil ZERO (++ Lst))) )
            (set P (ofs P 3)) )
         (evList Exe) ) ) )
