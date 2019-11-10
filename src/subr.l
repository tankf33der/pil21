# 17oct19 Software Lab. Alexander Burger

(compile) ()

# (car 'var) -> any
(de _car (X)
   (car (eval (cadr X))) )

# (cdr 'lst) -> any
(de _cdr (X)
   (cdr (eval (cadr X))) )

# (cons 'any ['any ..]) -> lst
(de _cons (X)
   (let (Y (cons (eval (car (>>> X))) $Nil)  P (link (push Y T NIL)))
      (while (pair (cdr (>>> X)))
         (setq Y
            (set (i Y) (cons (eval (car X)) $Nil)) ) )
      (set (i Y) (eval (car X)))
      (pop P) ) )

# (list 'any ['any ..]) -> lst
(de _list (X)
   (let (Y (cons (eval (car (>>> X))) $Nil)  P (link (push Y T NIL)))
      (while (pair (>>> X))
         (setq Y
            (set (i Y) (cons (eval (car X)) $Nil)) ) )
      (pop P) ) )

# (= 'any ..) -> flg
(de _equal (X)
   (let (A (eval (car (>>> X)))  P (link (push A T NIL)))
      (while (pair (>>> X))
         (let B (eval (car X))
            (unless (equal A B)
               (drop P)
               (ret $Nil) ) ) )
      (drop P)
      $T ) )

# (>= 'any ..) -> flg
(de _ge (X)
   (let (A (eval (car (>>> X)))  P (link (push A T NIL)))
      (while (pair (>>> X))
         (let B (eval (car X))
            (when (lt0 (compare A B))
               (drop P)
               (ret $Nil) )
            (setq A (set P B)) ) )
      (drop P)
      $T ) )
