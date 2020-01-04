# 04jan20 Software Lab. Alexander Burger

(compile) (redefine evMethod findCo)

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
         (if (n0 (setjmp (Ctch (rst))))
            (val $Ret)
            (run X) )
         (set $Catch (Ctch link)) ) ) )

# (throw 'sym 'any)
(de _throw (Exe)
   (let (X (cdr Exe)  Tag (eval (++ X)))
      (set $Ret (eval (car X)))
      (let Ctch (catchFrame (val $Catch))
         (until (=0 (Ctch))
            (when (or (== $T (Ctch tag)) (== Tag (Ctch tag)))
               (unwind (Ctch))
               (longjmp (Ctch (rst)) 1) )
            (setq Ctch (catchFrame (Ctch link))) ) )
      (err Exe Tag ($ "Tag not found") null) ) )

# (finally exe . prg) -> any
(de _finally (Exe)
   $Nil )

(de i8* findCo (Tag)
   (let Co (coroutine (val $Coroutines))
      (loop T
         (? (== Tag (Co tag)) (Co))
         (? (=0 (setq Co (Co next))) null) ) ) )

# (co 'sym [. prg]) -> any
(de _co (Exe)
   (let (X (cdr Exe)  Tag (eval (++ X)))
      (if (atom X)
         $Nil  # Stop coroutine
         (when (=0 (val $Coroutines))  # First call
            (let Main (coroutine (alloc null (+ (val JmpBufSize) (coroutine T))))
               (Main tag $T)  # Tag 'T'
               (Main next null)
               (Main prg $Nil)
               (Main lim null)
               (set $Coroutines (Main))
               (let Cf (coFrame (alloc null (coFrame T)))
                  (Cf link null)
                  (Cf crt (Main))
                  (set $CoFrames (Cf)) ) ) )
         (let Src (coroutine ((coFrame (val $CoFrames)) crt))
            (Src at (val $At))
            (memcpy (Src (env)) (env) (env T))
            (prog1
               (if (n0 (setjmp (Src (rst))))
                  (val $Ret)  # Yielded
                  (let (Cf (coFrame (b8 (coFrame T)))  P (findCo Tag))
                     (Cf link (val $CoFrames))
                     (set $CoFrames (Cf))
                     (unless (=0 P)
                        (let Dst (coroutine P)
                           (Cf crt (Dst))
                           (longjmp (Dst (rst)) 1) ) )
                     (setq P (findCo 0))  # Find unused coroutine
                     (when (=0 P)
                        (setq P (b8 (+ (val $StkSize) (coroutine T)))) )
                     (let Dst (coroutine P)
                        (Dst tag Tag)
                        (Dst next (val $Coroutines))
                        (Dst prg X)
                        (Dst lim null)
                        (set $Coroutines (Dst))
                        (Cf crt (Dst))
                        (set  # Init co-local env
                           $Make 0
                           $Yoke 0
                           #{$StkLimit (- .. 4096 (val $StkSize)))}# )
                        (prog1
                           (run X)
                           (Dst tag 0)  # Mark as unused
                           (set $CoFrames (Cf link)) ) ) ) )
               (memcpy (env) (Src (env)) (env T))
               (set $At (Src at)) ) ) ) ) )

# (yield 'any ['sym]) -> any
(de _yield (Exe)
   (let (X (cdr Exe)  Val (save (eval (++ X)))  Tag (eval (++ X)))
      (let
         (Cf (coFrame (val $CoFrames))
            Src (coroutine (Cf crt))
            Dst (coroutine ((coFrame (Cf link)) crt)) )
         (Src at (val $At))
         (memcpy (Src (env)) (env) (env T))
         (when (=0 (setjmp (Src (rst))))
            (set $Ret Val)
            (longjmp (Dst (rst)) 1) )
         (memcpy (env) (Src (env)) (env T))
         (set $At (Src at))
         (val $Ret) ) ) )

# (bye ['cnt])
(de _bye (X)
   (let N (eval (cadr X))
      (bye
         (if (nil? N)
            0
            (i32 (int N)) ) ) ) )
