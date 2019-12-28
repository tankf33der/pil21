# 28dec19 Software Lab. Alexander Burger

(compile) (redefine evMethod)

(de redefine (Exe S X)
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

# (dm sym . fun|cls2) -> sym
# (dm (sym . cls) . fun|cls2) -> sym
# (dm (sym sym2 [. cls]) . fun|cls2) -> sym
(de _dm (X)
   $Nil )

# Apply METH to CDR of list
(de evMethod (Obj Cls Key Exe Lst)
   (let
      (X (cdr Lst)  # Arguments
         Y (car Exe)  # Parameters
         Q (link (push (val $At) NIL $At (val $Bind) Lst)) )  # [[@] LINK @ Bind Exe]
      (link (push Obj NIL $This))
      (while (pair Y)
         (link
            (push  # [val LINK sym]
               (eval (++ X))  # Evaluate next argument
               NIL
               (++ Y) ) ) )  # Next parameter
      (prog1
         (let P (val $Link)
            (if (== Y $At)  # VarArgs
               (let Next (push (val $Next))
                  (cond
                     ((atom X) (set $Next $Nil))
                     (T
                        (let L (link (push T NIL))  # [lst LINK]
                           (set $Next
                              (set L (push (eval (car X)) $Nil)) )  # [arg1 next]
                           (while (pair (>>> X))
                              (let Z (push (eval (car X)) $Nil NIL)  # [argN next]
                                 (set 2 L Z)
                                 (setq L Z) ) ) ) ) )
                  (set $Bind P)
                  (loop
                     (let (S (val 3 P)  V (val S))  # Symbol, old value
                        (set S (val P))  # Set new value
                        (set P V)  # Save old value
                        (? (== Q P))
                        (>>> P) ) )
                  (let (C (val $Cls)  K (val $Key))
                     (prog1
                        (run (cdr Exe))  # Run body
                        (set
                           $Key K
                           $Cls C
                           $Next (val Next)
                           $Link (val $Bind) ) ) ) )
               (unless (== Y $Nil)
                  (link (push (val Y) NIL Y))  # Last parameter
                  (set Y X) )  # Set to unevaluated argument(s)
               (set $Bind (val $Link))
               (loop
                  (let (S (val 3 P)  V (val S))  # Symbol, old value
                     (set S (val P))  # Set new value
                     (set P V)  # Save old value
                     (? (== Q P))
                     (>>> P) ) )
               (let (C (val $Cls)  K (val $Key))
                  (set $Cls Cls)
                  (set $Key Key)
                  (run (cdr Exe))  # Run body
                  (set $Key K  $Cls C) ) ) )
         (let P (val $Link)
            (loop
               (set (val 3 P) (val P))  # Restore values
               (? (== Q P))
               (>>> P) )
            (drop P) )
         (set $Bind (val 4 Q)) ) ) )

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
   (let (X (cdr Exe)  Tag (save (eval (++ X))))
      (set $Thrown (eval (car X)))
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
