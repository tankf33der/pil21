# 15dec19 Software Lab. Alexander Burger

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

# (catch 'any . prg) -> any
(de _catch (X)
   (let Ctch (catchFrame (b8 (+ (val JmpBufSize) (catchFrame T))))
      (>>> X)
      (Ctch tag (eval (++ X)))
      (Ctch link (val $Catch))
      (set $Catch (Ctch))
      (Ctch fin ZERO)
      (memcpy (Ctch (env)) (env) (env T))
      (prog1
         (if (=0 (setjmp (Ctch (rst))))
            (run X)
            (val $Thrown) )
         (set $Catch (Ctch link)) ) ) )

# (throw 'sym 'any)
(de _throw (Exe)
   (let (X (cdr Exe)  Tag (eval (++ X)))
      (save Tag T
         (set $Thrown (eval (car X))) )
      (let Ctch (catchFrame (val $Catch))
         (until (=0 (Ctch))
            (when (or (== $T (Ctch tag)) (== Tag (Ctch tag)))
               (unwind (Ctch))
               (longjmp (Ctch (rst)) 1) )
            (setq Ctch (catchFrame (Ctch link))) ) )
      (err Exe Tag ($ "Tag not found") null) ) )

# (bye ['cnt])
(de _bye (X)
   (let N (eval (cadr X))
      (bye
         (if (nil? N)
            0
            (i32 (int N)) ) ) ) )
