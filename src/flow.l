# 20nov19 Software Lab. Alexander Burger

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
   (let Frame (catchFrame (b8 (+ (val JmpBufSize) (catchFrame T))))
      (>>> X)
      (Frame tag (eval (++ X)))
      (Frame link (val $Catch))
      (set $Catch (Frame))
      (Frame fin ZERO)
      (memcpy (Frame env T) (env) (env T))
      (prog1
         (if (=0 (setjmp (Frame rst T)))
            (run X)
            (val $Thrown) )
         (set $Catch (Frame link)) ) ) )

# (throw 'sym 'any)
(de _throw (Exe)
   (let (X (cdr Exe)  Tag (eval (++ X)))
      (save Tag T
         (set $Thrown (eval (car X))) )
      (let P (val $Catch)
         (until (=0 P)
            (let Frame (catchFrame P)
               (when (or (== $T (Frame tag)) (== Tag (Frame tag)))
                  #! (unwind Frame)
                  (longjmp (Frame rst T) 1) )
               (setq P (Frame link)) ) ) )
      (err Exe Tag ($ "Tag not found") null null) ) )

# (bye ['cnt])
(de _bye (X)
   (let N (eval (cadr X))
      (bye
         (if (nil? N)
            0
            (i32 (int N)) ) ) ) )
