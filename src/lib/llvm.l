# 10nov19 Software Lab. Alexander Burger

(de compile ()
   (symbols '(llvm pico))
   (local) )

## PicoLisp LLVM frontend ##
(symbols 'llvm 'pico)

(local) (void null i1 i1* i1** i8 i8* i8** i8*** i32 i32* i32** i64 i64* i64**
any YES NO ZERO ONE begin end $ ? short global var str const globals array table
symTab inline define struct $Nil)

(def 'void 'void)
(def 'null 'null)

(def 'NO (def "0" 'i1))  # Booleans
(def 'YES (def "1" 'i1))
(def 'ZERO (def "2" 'any))  # Short number '0'
(def 'ONE (def "18" 'any))  # Short number '1'


## Cross-compiler local ##
(symbols 'cc 'llvm 'pico)

(local) (*Strings *Ssa *Lbl *Curr *? *Exit *Bind *Phi *Ret log asm ssa phi +phi
br label +lbl +bind type func ptr pointee store A B C I L N P V X Y Exe Prg Prg2
Bnd2 Typ Sym Ret Args Ext Body Var Val Lst Lbl Flg Skip True False Beg End)

(import llvm~any pico~inc pico~dec pico~++ #{pico~>>>}#)


# Generate LLVM-IR
(de begin (Name)
   (off *Strings)
   (prinl "source_filename = \"" Name ".l\"")
   (prinl)
   (prinl "declare {i64, i1} @llvm.uadd.with.overflow.i64(i64, i64)")
   (prinl "declare {i64, i1} @llvm.usub.with.overflow.i64(i64, i64)")
   (prinl "declare i64 @llvm.fshl.i64(i64, i64, i64)")
   (prinl "declare i64 @llvm.fshr.i64(i64, i64, i64)")
   (prinl "declare i8* @llvm.stacksave()")
   (prinl "declare void @llvm.stackrestore(i8*)")
   (prinl) )

(de end ()
   (prinl)
   (for L *Strings
      (prinl (caddr L) " = " (cdddr L)) ) )

(de log (Exe)
   (when *Lbl
      (let L (chop (symbols '(llvm pico cc) (sym Exe)))
         (and (nth L 65) (con @ "..."))
         (link (cons NIL L)) ) ) )

(de asm Lst
   (for L (cddr Lst)
      (def (car L)
         (bind (car Lst)
            (mapc set (car Lst) (cdr L))
            (cons (caadr Lst)
               '(log (up))
               (let @@ '@@
                  (fill (cdadr Lst)) ) ) ) ) ) )

(de ssa (N . @)
   (link
      (cons
         (pack "%" N)
         (pass pack) ) ) )

(de phi (Lbl Var)
   (if (asoq Lbl *Phi)
      (let L @
         (if (asoq Var L)
            (conc @ (list (cons *Curr (val Var))))
            (con L
               (cons
                  (list Var NIL (cons *Curr (val Var)))
                  (cdr L) ) ) ) )
      (queue '*Phi
         (list Lbl (list Var NIL (cons *Curr (val Var)))) ) ) )

(de +phi (Lbl)
   (let M NIL
      (for Var *Bind
         (unless (memq Var M)
            (phi Lbl Var)
            (push 'M Var) ) ) )
   Lbl )

(de br (A B C)
   (link
      (if B
         (pack "br i1 " A ", label %$" (+phi B) ", label %$" (+phi C))
         (pack "br label %$" (+phi A)) ) ) )

(de label (N)
   (for L (cdr (asoq (link (setq *Curr N)) *Phi))
      (when
         (or
            (not (name (car L)))
            (memq (car L) *Bind) )
         (set
            (car L)  # Var
            (set
               (cdr L)  # Ssa
               (def
                  (pack "%" (inc '*Ssa))
                  (or
                     (pick
                        '((X)
                           (and (sym? (cdr X)) (val (cdr X))) )
                        (cddr L) )
                     'i64 ) ) ) ) ) ) )

(de +lbl ()
   (inc '*Lbl) )

(de +bind (Lst Var)
   (when
      (fish
         '((X)
            (when (pair X)
               (or
                  (and
                     (memq (car X) '(llvm~inc llvm~dec))
                     (== 'quote (caadr X))
                     (== Var (cdadr X)) )
                  (and
                     (memq (car X) '(setq llvm~++ llvm~>>>))
                     (for (L (cdr X)  L  (cddr L))
                        (T (== Var (car L)) T) ) ) ) ) )
         Lst )
      (push '*Bind Var) ) )

(de type (Typ)
   (cond
      ((== 'any Typ) 'i64)
      ((== null Typ) 'i8*)
      ((pair Typ) (func @))
      (T Typ) ) )

(de func (Lst)
   (pack
      (type (car Lst))
      "("
      (glue "," (mapcar type (cdr Lst)))
      ")*" ) )

(de ptr (Typ)
   (or
      (pair Typ)
      (if (== 'any Typ)
         'any
         (intern (pack Typ "*")) ) ) )

(de pointee (Typ)
   (intern (pack (head -1 (chop Typ)))) )

(de store (X P)
   (nond
      ((== 'any (val P))
         (when (num? X)
            (setq X (def (format X) (pointee (val P)))) )
         (link
            (pack "store " (type (val X))
               " " X ", " (val P) " " P ) ) )
      ((pre? "@" P)
         (ssa (inc '*Ssa) "inttoptr i64 " P " to i64*")
         (link (pack "store i64 " X ", i64* %" *Ssa)) )
      (NIL
         (link (pack "store i64 " X ", i64* " P)) ) )
   X )

(de $ (Str)
   (if (assoc Str *Strings)
      (cadr @)
      (let
         (Sym (pack "@$" (inc (length *Strings)))
            Arr (pack "[" (inc (size Str)) " x i8]")
            Val (pack "bitcast (" Arr "* " Sym " to i8*)") )
         (push '*Strings
            (cons Str Val Sym
               (pack
                  (make
                     (link "private constant " Arr " c\"")
                     (for C (chop Str)
                        (if (or (> " " C) (sub? C "\""))
                           (link "\\" (pad 2 (hex (char C))))
                           (link C) ) )
                     (link "\\00\"") ) ) ) )
         Val ) ) )

(de short (N)
   (| 2 (>> -4 N)) )

(de global (Sym Typ Val)
   (prinl
      "@" Sym " = global " (type Typ) " "
      (cond
         ((pre? "_" Val) (pack "@" @))
         ((pre? "$" Val)
            (if (; Val offset)
               (pack
                  "ptrtoint (i8* getelementptr (i8, i8* bitcast (["
                  (; Val table length)
                  " x i64]* @"
                  (; Val table)
                  " to i8*), i32 "
                  @
                  ") to i64)" )
               (pack "ptrtoint ("
                  (if (== 'any Typ) 'i64 Typ)
                  "* @" @ " to "
                  (if (== 'any Typ) 'i64 Typ)
                  ")" ) ) )
         (T Val) ) )
   (def Sym (def (pack "@" Sym) (ptr Typ))) )

(de var Lst
   (global
      (++ Lst)
      (if (cdr Lst) (++ Lst) 'any)
      (eval (car Lst)) ) )

(de str Lst
   (let ((Sym Val) Lst  Arr (pack "[" (inc (size Val)) " x i8]"))
      (def Sym (pack "bitcast (" Arr "* @" Sym " to i8*)"))
      (prin "@" Sym " = constant " Arr " c\"")
      (for C (chop Val)
         (if (or (> " " C) (sub? C "\""))
            (prin "\\" (pad 2 (hex (char C))))
            (prin C) ) )
      (prinl "\\00\"") ) )

(de const (Val)
   (cond
      ((pre? "_" Val)
         (prin
            "i64 ptrtoint (i8* getelementptr (i8, i8* bitcast (i64(i64)* @"
            @
            " to i8*), i32 2) to i64)" ) )
      ((pre? "$" Val)
         (if (; Val offset)
            (prin
               "  i64 ptrtoint (i8* getelementptr (i8, i8* bitcast (["
               (; Val table length)
               " x i64]* @"
               (; Val table)
               " to i8*), i32 "
               @
               ") to i64)" )
            (prin Val) ) )
      (T
         (prin "  i64 " (eval Val)) ) ) )

(de array Lst
   (let (Sym (++ Lst)  Typ (++ Lst)  Len (length Lst))
      (def Sym
         (def
            (pack
               "bitcast (["
               Len " x " (setq Typ (type Typ))
               "]* @" Sym " to " (ptr Typ) ")" )
            (ptr Typ) ) )
      (prinl "@" Sym " = global [" Len " x " Typ "] [")
      (for (I . X) Lst
         (prinl
            "  " Typ " " (eval X)
            (unless (== I Len) ",") ) )
      (prinl "]") ) )

(de table Args
   (let (Table (++ Args)  I 0)
      (put Table 'length (length Args))
      (prinl "@" Table " = global [" (; Table length) " x i64] [")
      (for (I . Lst) Args
         (let Typ (if (caddr Lst) (cadr Lst) 'any)
            (let? Sym (car Lst)
               (put Sym 'table Table)
               (put Sym 'offset (* 8 (dec I)))
               (def Sym
                  (def
                     (pack
                        (if (== 'any Typ)
                           "ptrtoint (i8* getelementptr (i8, i8* bitcast (["
                           "bitcast (i8* getelementptr (i8, i8* bitcast ([" )
                        (; Table length)
                        " x i64]* @"
                        Table
                        " to i8*), i32 "
                        (; Sym offset)
                        ") to "
                        (type Typ)
                        (unless (== 'any Typ) "*")
                        ")" )
                     (ptr Typ) ) ) )
            (nond
               ((caddr Lst) (const (cadr Lst)))
               ((pair Typ)
                  (prin
                     "  i64 "
                     (if (sub? "*" Typ) "ptrtoint" "sext")
                     " (" (cadr Lst) " " (caddr Lst) " to i64)") )
               (NIL
                  (prin "  i64 ptrtoint (" (func @) " @" (caddr Lst) " to i64)") ) )
            (prinl (unless (== Lst (last Args)) ",")) ) ) )
   (prinl "], align 8") )

(de symTab Args
   (let (Table 'SymTab  I 0)
      (put Table 'length
         (sum
            '((L)
               (if (> (length (cadr L)) 7) 4 2) )
            Args ) )
      (prinl "@" Table " = global [" (; Table length) " x i64] [")
      (for Lst Args
         (let? Sym (car Lst)
            (put Sym 'table Table)
            (put Sym 'offset (+ I (or (cadddr Lst) 8)))
            (def Sym
               (def
                  (pack
                     "ptrtoint (i8* getelementptr (i8, i8* bitcast ([" (; Table length) " x i64]* @"
                     Table
                     " to i8*), i32 "
                     (; Sym offset)
                     ") to i64)" )
                  'any ) ) )
         (let Name
            (when (str? (cadr Lst))
               (prinl "  ; # [" I "] " @)
               (let L (chop (cadr Lst))
                  (make
                     (when (nth L 8)  # Max 15 ASCII characters
                        (let (D 0  N 0)
                           (do 8
                              (setq
                                 N (| N (>> D (char (++ L))))
                                 D (- D 8) ) )
                           (link N) ) )
                     (let (D 0  N 0)
                        (while L
                           (setq
                              N (| N (>> D (char (++ L))))
                              D (- D 8) ) )
                        (link (short N)) ) ) ) )
            (nond  # Name
               (Name
                  (const (cadr Lst))
                  (prinl ",") )
               ((cdr Name)
                  (prinl "  i64 " (car Name) ",") )
               (NIL
                  (prinl
                     "  i64 ptrtoint (i8* getelementptr (i8, i8* bitcast ([" (; Table length) " x i64]* @"
                     Table
                     " to i8*), i32 "
                     (+ I 16 4)
                     ") to i64)," ) ) )
            (const (caddr Lst))  # Value
            (when (cdr Name)  # Long name
               (prinl ",")
               (inc 'I 16)
               (prinl "  i64 " (car Name) ",")
               (prin "  i64 " (cadr Name)) ) )
         (prinl (unless (== Lst (last Args)) ","))
         (inc 'I 16) ) )
   (prinl "], align 16") )

(de inline Lst
   (def (++ Lst)
      (let ((@Args . @Body) Lst)
         (fill
            '(@Args
               (log (up))
               (use *Bind
                  (for Var '@Args
                     (+bind '@Body Var) )
                  . @Body ) ) ) ) ) )

(de define (Ext Ret Sym Args Body)
   (and Body (prinl))
   (setq *Ssa -1)
   (off *Bind *Phi *?)
   (with Sym
      (setq *Ret
         (if Ret
            (type @)
            (=: noreturn T)
            void ) )
      (cond
         (Ext (prin "declare " *Ret " @" Sym "("))
         (Body (prin "define " *Ret " @" Sym "(")) )
      (when
         (=: args
            (replace
               (ifn Body
                  Args
                  (mapcar
                     '((A)
                        (+bind Body (fin A))
                        (set
                           (set (fin A) (pack "%" (inc '*Ssa)))
                           (if (atom A) 'any (car A)) ) )
                     Args ) )
               'any 'i64 ) )
         (when (or Ext Body)
            (prin (car (: args)))
            (for A (cdr (: args))
               (prin ", " A) ) ) )
      (cond
         (Ext (prinl ")"))
         (Body (prinl ") {")) )
      (def This
         (list '@
            (make
               (link 'let 'A
                  (list 'mapcar
                     ''((Typ) (pack Typ " " (next)))
                     (lit (: args)) ) )
               (link '(log (up)))
               (let L
                  (list
                     "call " (lit *Ret) " @" (lit Sym)
                     "(" '(glue ", " A) ")" )
                  (link
                     (if (== void *Ret)
                        (list 'link (cons 'pack L))
                        (cons 'ssa '(inc '*Ssa) L) ) ) )
               (if (: noreturn)
                  (link '(link "unreachable") NIL)
                  (link
                     (or
                        (== void *Ret)
                        (list 'def '(pack "%" *Ssa) (lit Ret)) ) ) ) ) ) ) )
   (when Body
      (let *Lbl 1
         (for X
            (make
               (label *Lbl)
               (let? R (run Body)
                  (if (== void *Ret)
                     (link "ret void")
                     (link (pack "ret " *Ret " " R)) ) ) )
            (cond
               ((num? X)
                  (prinl "$" X ":")
                  (for L (cdr (asoq X *Phi))
                     (when (cadr L)
                        (prin
                           "  " (cadr L) " = phi "
                           (type (val (cadr L)))
                           " [" (cdaddr L) ", %$" (caaddr L) "]" )
                        (for X (cdddr L)
                           (prin ", [" (cdr X) ", %$" (car X) "]") )
                        (prinl " ; # " (or (name (car L)) "->")) ) ) )
               ((atom X) (prinl "  " X))
               ((not (car X)) (prinl "; # " (cdr X)))
               (T (prinl "  " (car X) " = " (cdr X))) ) ) )
      (prinl "}") ) )

(de struct Lst
   (def (car Lst)
      (let
         (@N 0
            @L
            (mapcar
               '((X)
                  (prog1
                     (cons (car X) @N (cddr X))
                     (inc '@N (cadr X)) ) )
               (cdr Lst) ) )
         (curry (@N @L) (P)
            (if (=T P)
               @N
               (let @P (or P (llvm~b8 @N))
                  (curry (@P) Args
                     (nond
                        (Args '@P)
                        ((assoc (car Args) '@L)
                           (quit "Bad struct item" (car Args)) )
                        (NIL
                           (let P ((ptr (cddr @)) (llvm~ofs '@P (cadr @)))
                              (nond
                                 ((cadr Args) (llvm~val P))
                                 ((=T @) (llvm~set P (eval @)))
                                 (NIL P) ) ) ) ) ) ) ) ) ) ) )

## Cross compiler overridden ##
(symbols '(cc pico llvm))

(de llvm~de Lst
   (define
      (and (=T (car Lst)) (++ Lst))
      (if (lst? (cadr Lst)) 'any (++ Lst))
      (car Lst)
      (cadr Lst)
      (cddr Lst) ) )

# Type casts
(asm ()
   ((X)
      (if (num? X)
         (def (format X) 'i8)
         (let V (val X)
            (casq V
               ((i32 i64) (ssa (inc '*Ssa) "trunc " V " " X " to i8"))
               (T (quit "Bad type" V)) ) )
         (def (pack "%" *Ssa) 'i8) ) )
   (llvm~i8) )

(asm ()
   ((X)
      (if (num? X)
         (def (format X) 'i32)
         (let V (val X)
            (casq V
               ((i1 i8) (ssa (inc '*Ssa) "zext " V " " X " to i32"))
               (i64 (ssa (inc '*Ssa) "trunc " V " " X " to i32"))
               (T (quit "Bad type" V)) ) )
         (def (pack "%" *Ssa) 'i32) ) )
   (llvm~i32) )

(asm ()
   ((X)
      (let V (val X)
         (if (== 'any V)
            (def (name X) 'i64)
            (casq V
               ((i1 i8) (ssa (inc '*Ssa) "zext " V " " X " to i64"))
               (i32 (ssa (inc '*Ssa) "sext " V " " X " to i64"))
               ((i1* i8* i32* i64*)
                  (ssa (inc '*Ssa) "ptrtoint " V " " X " to i64") )
               (T (quit "Bad type" V)) )
            (def (pack "%" *Ssa) 'i64) ) ) )
   (llvm~i64) )

(asm (@Typ)
   ((X)
      (let V (val X)
         (cond
            ((memq V '(any i64))
               (ssa (inc '*Ssa) "inttoptr i64 " X " to " '@Typ) )
            ((sub? "*" V)
               (ssa (inc '*Ssa) "bitcast " V " " X " to " '@Typ) )
            (T (quit "Bad type" V)) )
         (def (pack "%" *Ssa) '@Typ) ) )
   (llvm~i1* llvm~i1*)
   (llvm~i8* llvm~i8*)
   (llvm~i8** llvm~i8**)
   (llvm~i32* llvm~i32*)
   (llvm~i64* llvm~i64*) )

(asm ()
   ((X)
      (if (num? X)
         (def (format X) 'any)
         (let V (val X)
            (if (== 'i64 V)
               (def (name X) 'any)
               (casq V
                  ((i1* i8* i32* i64*)
                     (ssa (inc '*Ssa) "ptrtoint " V " " X " to i64") )
                  (T (quit "Bad type" V)) ) )
            (def (pack "%" *Ssa) 'any) ) ) )
   (llvm~any) )

# (Un)Boxing
(asm ()
   ((X)
      (ssa (inc '*Ssa) "lshr i64 " X ", 4")
      (def (pack "%" *Ssa) 'i64) )
   (llvm~int) )

(asm ()
   ((X)
      (ssa (inc '*Ssa) "shl i64 " X ", 4")
      (ssa (inc '*Ssa) "or i64 %" (dec *Ssa) ", 2")
      (def (pack "%" *Ssa) 'any) )
   (llvm~cnt 2) )

(asm (@Tag)
   ((X)
      (let V (val X)
         (casq V
            ((any i64)
               (ssa (inc '*Ssa) "add i64 " X ", " @Tag)
               (def (pack "%" *Ssa) 'any) )
            ((i1* i8* i32* i64*)
               (ssa (inc '*Ssa) "ptrtoint " V " " X " to i64")
               (ssa (inc '*Ssa) "add i64 %" (dec *Ssa) ", " @Tag)
               (ssa (inc '*Ssa) "inttoptr i64 %" (dec *Ssa) " to " V)
               (def (pack "%" *Ssa) V) )
            (T (quit "Bad type" V)) ) ) )
   (llvm~big 4)
   (llvm~dig -4)
   (llvm~sign 8)
   (llvm~sym 8)
   (llvm~tail -8) )

(asm (@Tag)
   ((X)
      (ssa (inc '*Ssa) "and i64 " X ", " @Tag)
      (def (pack "%" *Ssa) 'any) )
   (llvm~pos -9) )

# Type checks
(asm (@Tag @Pred)
   ((X)
      (ssa (inc '*Ssa) "and i64 " X ", " @Tag)
      (ssa (inc '*Ssa) "icmp " @Pred " i64 %" (dec *Ssa) ", 0")
      (def (pack "%" *Ssa) 'i1) )
   (llvm~cnt? 2 "ne")
   (llvm~big? 4 "ne")
   (llvm~num? 6 "ne")
   (llvm~sym? 8 "ne")
   (llvm~sign? 8 "ne")
   (llvm~atom 15 "ne")
   (llvm~pair 15 "eq") )

(asm ()
   ((X)
      (ssa (inc '*Ssa) "icmp eq i1 " X ", 0")
      (def (pack "%" *Ssa) 'i1) )
   (llvm~not) )

(asm ()
   ((X)
      (ssa (inc '*Ssa) "icmp eq i64 " X ", " $Nil)
      (def (pack "%" *Ssa) 'i1) )
   (llvm~nil?) )

# Comparisons
(asm (@Pred)
   ((X Y)
      (ssa (inc '*Ssa) "icmp " @Pred " "
         (type (val (if (sym? X) X Y)))
         " " X ", " Y )
      (def (pack "%" *Ssa) 'i1) )
   (llvm~== "eq")
   (llvm~<> "ne") )

(asm (@Pred1 @Pred2)
   ((X Y)
      (let V (type (val (if (sym? X) X Y)))
         (ssa (inc '*Ssa) "icmp "
            (if (== 'i32 V) @Pred1 @Pred2)
            " " V " " X ", " Y ) )
      (def (pack "%" *Ssa) 'i1) )
   (llvm~> "sgt" "ugt")
   (llvm~>= "sge" "uge")
   (llvm~< "slt" "ult")
   (llvm~<= "sle" "ule") )

(asm (@Pred)
   ((X)
      (ssa (inc '*Ssa) "icmp " @Pred " "
         (type (val X)) " " X ", "
         (if (sub? "*" (val X)) null 0) )
      (def (pack "%" *Ssa) 'i1) )
   (llvm~=0 "eq")
   (llvm~n0 "ne") )

(asm (@Pred1 @Pred2)
   ((X)
      (ssa (inc '*Ssa) "icmp "
         (if (== 'i32 (val X)) @Pred1 @Pred2)
         " " (type (val X)) " " X ", 0" )
      (def (pack "%" *Ssa) 'i1) )
   (llvm~gt0 "sgt" "ugt")
   (llvm~ge0 "sge" "uge")
   (llvm~le0 "sle" "sle")
   (llvm~lt0 "slt" "slt") )

# Arithmetics
(asm (@Op1 @Op2 @Sgn)
   ((X Y)
      (if (num? X)
         (if Y (@Op1 X Y) (@Op1 X))
         (let V (val X)
            (casq V
               ((any i64)
                  (ifn Y
                     (ssa (inc '*Ssa) @Op2 " " V " 0, " X)
                     (when (and (sym? Y) (== 'i1 (val Y)))
                        (ssa (inc '*Ssa) "zext i1 " Y " to i64")
                        (setq Y (pack "%" *Ssa)) )
                     (ssa (inc '*Ssa) "call {i64, i1} @llvm.u" @Op2 ".with.overflow.i64(i64 " X ", i64 " Y ")")
                     (ssa (inc '*Ssa) "extractvalue {i64, i1} %" (dec *Ssa) ", 1")
                     (setq @@ (def (pack "%" *Ssa) 'i1))
                     (ssa (inc '*Ssa) "extractvalue {i64, i1} %" (- *Ssa 2) ", 0") ) )
               ((i8 i32)
                  (ssa (inc '*Ssa) @Op2 " " V " " (if Y X 0) ", " (or Y X)) )
               ((i1* i1** i8* i8** i8*** i32* i32** i64* i64**)
                  (let Typ (pointee V)
                     (if (num? Y)
                        (ssa (inc '*Ssa) "getelementptr " Typ ", " V " " X ", i32 " @Sgn Y)
                        (ssa (inc '*Ssa) "ptrtoint " V " " X " to i64")
                        (ssa (inc '*Ssa) "ptrtoint " (val Y) " " Y " to i64")
                        (ssa (inc '*Ssa) @Op2 " i64 %" (- *Ssa 2) ", %" (dec *Ssa))
                        (setq V 'i64) ) ) )
               (T (quit "Bad type" V)) )
            (def (pack "%" *Ssa) V) ) ) )
   (llvm~+ + "add")
   (llvm~- - "sub" "-") )

(asm (@Op1 @Op2 @Sgn)
   ((X)
      (if (num? X)
         (@Op1 X)
         (let (Y (or (str? X) (val X))  V (val Y))
            (casq V
               ((i8 i32 i64 any)
                  (ssa (inc '*Ssa) @Op2 " " (type V) " " Y ", 1") )
               ((i1* i1** i8* i8** i8*** i32* i32** i64* i64**)
                  (ssa (inc '*Ssa) "getelementptr " (pointee V) ", " V " " Y ", i32 " @Sgn 1) )
               (T (quit "Bad type" V)) )
            (prog1
               (def (pack "%" *Ssa) V)
               (unless (str? X)
                  (set X @) ) ) ) ) )
   (llvm~inc inc "add")
   (llvm~dec dec "sub" "-") )

(asm (@Op1 @Op2)
   ((X Y)
      (if (and (num? X) (num? Y))
         (@Op1 X Y)
         (let V (type (val (if (sym? X) X Y)))
            (ssa (inc '*Ssa) @Op2 " " V " " X ", " Y)
            (def (pack "%" *Ssa) V) ) ) )
   (llvm~* * "mul")
   (llvm~/ / "udiv")
   (llvm~% % "urem")
   (llvm~& & "and")
   (llvm~| | "or")
   (llvm~x| x| "xor") )

(asm ()
   ((X Y)
      (unless (num? X)
         (ssa (inc '*Ssa) "zext i64 " X " to i128")
         (setq X (pack "%" *Ssa)) )
      (ssa (inc '*Ssa) "zext i64 " Y " to i128")
      (ssa (inc '*Ssa) "mul i128 " X ", %" (dec *Ssa))
      (ssa (inc '*Ssa) "lshr i128 %" (dec *Ssa) ", 64")
      (ssa (inc '*Ssa) "trunc i128 %" (dec *Ssa) " to i64")
      (setq @@ (def (pack "%" *Ssa) 'i64))
      (ssa (inc '*Ssa) "trunc i128 %" (- *Ssa 3) " to i64")
      (def (pack "%" *Ssa) 'i64) )
   (llvm~mul) )

(asm ()
   ((X Y Z)
      (ssa (inc '*Ssa) "zext i64 " X " to i128")
      (ssa (inc '*Ssa) "shl i128 " (dec *Ssa) ", 64")
      (ssa (inc '*Ssa) "zext i64 " Y " to i128")
      (ssa (setq Y (inc '*Ssa)) "or i128 %" (dec *Ssa) ", %" (- *Ssa 2))
      (unless (num? Z)
         (ssa (inc '*Ssa) "zext i64 " Z " to i128")
         (setq Z (pack "%" *Ssa)) )
      (ssa (inc '*Ssa) "urem i128 %" Y ", " Z)
      (setq @@ (def (pack "%" *Ssa) 'i64))
      (ssa (inc '*Ssa) "udiv i128 %" Y ", " Z)
      (def (pack "%" *Ssa) 'i64) )
   (llvm~div) )

(asm (@Op @Op2)
   ((X Y Z)
      (ifn Z
         (let V (type (val X))
            (ssa (inc '*Ssa) @Op " " V " " X ", " Y)
            (def (pack "%" *Ssa) V) )
         (ssa (inc '*Ssa) "call "
            "i64 @llvm." @Op2 ".i64("
            "i64 " X ", "
            "i64 " Y ", "
            "i64 " Z ")" )
         (def (pack "%" *Ssa) 'i64) ) )
   (llvm~shl "shl" "fshl")
   (llvm~shr "lshr" "fshr") )

# Memory access
(asm ()
   ((X Y)
      (if (=0 Y)
         X
         (casq (val X)
            (any
               (if (num? Y)
                  (ssa (inc '*Ssa) "add i64 " X ", " (* 8 Y))
                  (if (== 'i64 (val Y))
                     (ssa (inc '*Ssa) "shl i64 " Y ", 3")
                     (ssa (inc '*Ssa) "zext " (val Y) " " Y " to i64")
                     (ssa (inc '*Ssa) "shl i64 %" (dec *Ssa) ", 3") )
                  (ssa (inc '*Ssa) "add i64 " X ", %" (dec *Ssa)) ) )
            ((i8 i32 i64)
               (ssa (inc '*Ssa) "add " (type (val X)) " " X ", " Y) )
            ((i1* i1** i8* i8** i8*** i32* i32** i64* i64**)
               (ssa (inc '*Ssa) "getelementptr " (pointee (val X)) ", "
                  (val X) " " X ", "
                  (if (num? Y) 'i32 (val Y)) " " Y ) )
            (T (quit "Bad type" (val X))) )
         (def (pack "%" *Ssa) (val X)) ) )
   (llvm~ofs) )

(asm ()
   ((X)
      (ssa (inc '*Ssa) "inttoptr i64 " X " to i64*")
      (ssa (inc '*Ssa) "load i64, i64* %" (dec *Ssa))
      (def (pack "%" *Ssa) 'any) )
   (llvm~car) )

(asm ()
   ((X)
      (ssa (inc '*Ssa) "inttoptr i64 " X " to i64*")
      (ssa (inc '*Ssa) "getelementptr i64, i64* %" (dec *Ssa) ", i32 1")
      (ssa (inc '*Ssa) "load i64, i64* %" (dec *Ssa))
      (def (pack "%" *Ssa) 'any) )
   (llvm~cdr) )

(asm ()
   (Args
      (ssa (inc '*Ssa) "inttoptr i64 " (val (car Args)) " to i64*")
      (ssa (inc '*Ssa) "load i64, i64* %" (dec *Ssa))
      (let P *Ssa
         (ssa (inc '*Ssa) "getelementptr i64, i64* %" (- *Ssa 2) ", i32 1")
         (ssa (inc '*Ssa) "load i64, i64* %" (dec *Ssa))
         (set (car Args) (def (pack "%" *Ssa) 'any))
         (def (pack "%" P) 'any) ) )
   (llvm~++) )

(asm ()
   (Args
      (ssa (inc '*Ssa) "inttoptr i64 " (val (car Args)) " to i64*")
      (ssa (inc '*Ssa) "getelementptr i64, i64* %" (dec *Ssa) ", i32 1")
      (ssa (inc '*Ssa) "load i64, i64* %" (dec *Ssa))
      (set (car Args) (def (pack "%" *Ssa) 'any)) )
   (llvm~>>>) )

(asm ()
   ((X)
      (casq (val X)
         (any
            (if (pre? "@" X)
               (ssa (inc '*Ssa) "load " "i64, i64* " X)
               (ssa (inc '*Ssa) "inttoptr i64 " X " to i64*")
               (ssa (inc '*Ssa) "load " "i64, i64* %" (dec *Ssa)) )
            (def (pack "%" *Ssa) 'any) )
         ((i1* i1** i8* i8** i8*** i32* i32** i64* i64**)
            (let Typ (pointee (val X))
               (ssa (inc '*Ssa) "load " Typ ", " (val X) " " X)
               (def (pack "%" *Ssa) Typ) ) )
         (T (quit "Bad type" (val X))) ) )
   (llvm~val) )

(asm ()
   (@
      (while (next)
         (store (next) @) ) )
   (llvm~set) )

(asm ()
   (Lst
      (use *Bind
         (let X (++ Lst)
            (if (pair X)
               (recur ()
                  (let (Var (++ X)  Val (eval (++ X)))
                     (+bind Lst Var)
                     (bind Var
                        (set Var Val)
                        (if X (recurse) (run Lst)) ) ) )
               (let Val (eval (++ Lst))
                  (+bind Lst X)
                  (bind X
                     (set X Val)
                     (run Lst) ) ) ) ) ) )
   (llvm~let) )

# Stack operations
(asm ()
   ((P)
      (if P
         (link (pack "call void @llvm.stackrestore(i8* " P ")"))
         (ssa (inc '*Ssa) "call i8* @llvm.stacksave()")
         (def (pack "%" *Ssa) 'i8*) ) )
   (llvm~stack) )

(asm (@Typ @Ptr)
   ((N)
      (ssa (inc '*Ssa) "alloca " '@Typ ", i32 " N)
      (def (pack "%" *Ssa) '@Ptr) )
   (llvm~b8 i8 i8*)
   (llvm~b32 i32 i32*)
   (llvm~b64 i64 i64*) )

(asm ()
   (@
      (let
         (Lst (rest)
            Typ
            (or
               (pick
                  '((X)
                     (cond
                        ((num? X) 'i64)
                        ((=T X) 'any)
                        (X (val X)) ) )
                  Lst )
               (quit "No type") ) )
         (ssa (inc '*Ssa) "alloca "
            (type Typ) ", i32 " (length Lst)
            (and (cdr Lst) ", align 16") )
         (when (== 'any Typ)
            (ssa (inc '*Ssa) "ptrtoint i64* %" (dec *Ssa) " to i64") )
         (let P (def (pack "%" *Ssa) (ptr Typ))
            (for (I . Y) Lst
               (when Y
                  (and (=T Y) (setq Y 10))  # Placeholder (minus ZERO))
                  (if (=1 I)
                     (store Y P)
                     (if (== 'any Typ)
                        (ssa (inc '*Ssa) "add i64 " P ", " (* 8 (dec I)))
                        (ssa (inc '*Ssa) "getelementptr "
                           (type Typ) ", " (val P) " " P ", i32 " (dec I) ) )
                     (store Y (def (pack "%" *Ssa) (val P))) ) ) )
            P ) ) )
   (llvm~push) )

(asm ()
   ((P)
      (ssa (inc '*Ssa) "add i64 " P ", 16")
      (ssa (inc '*Ssa) "inttoptr i64 %" (dec *Ssa) " to i64*")
      (ssa (inc '*Ssa) "load i64, i64* @$Link")
      (link (pack "store i64 %" *Ssa ", i64* %" (dec *Ssa)))
      (link (pack "store i64 " P ", i64* @$Link"))
      P )
   (llvm~link) )

(asm ()
   ((P)
      (ssa (inc '*Ssa) "inttoptr i64 " P " to i64*")
      (ssa (inc '*Ssa) "load " "i64, i64* %" (dec *Ssa))
      (let Q *Ssa
         (ssa (inc '*Ssa) "getelementptr i64, i64* %" (- *Ssa 2) ", i32 2")
         (ssa (inc '*Ssa) "load i64, i64* %" (dec *Ssa))
         (link (pack "store i64 %" *Ssa ", i64* @$Link"))
         (def (pack "%" Q) 'any) ) )
   (llvm~pop) )

(asm ()
   ((P)
      (ssa (inc '*Ssa) "add i64 " P ", 16")
      (ssa (inc '*Ssa) "inttoptr i64 %" (dec *Ssa) " to i64*")
      (ssa (inc '*Ssa) "load i64, i64* %" (dec *Ssa))
      (link (pack "store i64 %" *Ssa ", i64* @$Link"))
      P )
   (llvm~drop) )

# Flow
(asm ()
   ((Fun X)
      (ssa (inc '*Ssa) "and i64 " Fun ", -3")
      (ssa (inc '*Ssa) "inttoptr i64 %" (dec *Ssa) " to i64(i64)*")
      (ssa (inc '*Ssa) "call i64 %" (dec *Ssa) "(i64 " X ")")
      (def (pack "%" *Ssa) 'any) )
   (llvm~subr) )

(asm (@Val1 @Val2 @Lbl1 @Lbl2)
   (Prg
      (let (End (+lbl)  Var (box))
         (for Exe Prg
            (if (== Exe (last Prg))
               (when (set Var (eval (++ Prg)))
                  (unless (== 'i1 (val @))
                     (set Var @Val2) )
                  (phi End Var)
                  (br End) )
               (let (Flg (eval (++ Prg))  Skip (+lbl))
                  (set Var @Val1)
                  (phi End Var)
                  (br Flg @Lbl1 @Lbl2)
                  (label Skip) ) ) )
         (label End) ) )
   (llvm~and NO YES Skip End)
   (llvm~or YES NO End Skip) )

(asm ()
   (Prg
      (prog1
         (eval (++ Prg))
         (run Prg) ) )
   (llvm~prog1) )

(asm ()
   (Prg
      (prog2
         (eval (++ Prg))
         (eval (++ Prg))
         (run Prg) ) )
   (llvm~prog2) )

(asm (@Lbl1 @Lbl2)
   (Prg
      (let (Flg (eval (++ Prg))  Var (box)  Body (+lbl)  Skip (+lbl)  End (+lbl))
         (br Flg @Lbl1 @Lbl2)
         (label Body)
         (when (set Var (eval (++ Prg)))
            (phi End Var)
            (br End) )
         (label Skip)
         (when (set Var (run Prg))
            (phi End Var)
            (br End) )
         (label End) ) )
   (llvm~if Body Skip)
   (llvm~ifn Skip Body) )

(asm (@Lbl1 @Lbl2)
   (Prg
      (let (Flg (eval (++ Prg))  Body (+lbl)  End (+lbl))
         (br Flg @Lbl1 @Lbl2)
         (label Body)
         (and (run Prg) (br End))
         (label End) )
      T )
   (llvm~when Body End)
   (llvm~unless End Body) )

(asm (@Flg @Lbl1 @Lbl2 @Lbl3 @Lbl4 @Lbl5 @Lbl6)
   (Lst
      (let (End (+lbl)  Flg)
         (if (and (=T (car Lst)) (asoq @Flg Lst))
            (let Var (box)
               (for Prg (cdr Lst)
                  (if (== @Flg (car Prg))
                     (when (set Var (run (cdr Prg)))
                        (phi End Var)
                        (br End) )
                     (setq Flg (eval (++ Prg)))
                     (let (Body (+lbl)  Skip (+lbl))
                        (br Flg @Lbl1 @Lbl2)
                        (label Body)
                        (when (set Var (run Prg))
                           (phi End Var)
                           (br End) )
                        (label Skip) ) ) )
               (label End) )
            (while (cdr Lst)
               (let Prg (++ Lst)
                  (setq Flg (eval (++ Prg)))
                  (let Skip (+lbl)
                     (if Prg
                        (let Body (+lbl)
                           (br Flg @Lbl1 @Lbl2)
                           (label Body)
                           (and (run Prg) (br End)) )
                        (br Flg @Lbl3 @Lbl4) )
                     (label Skip) ) ) )
            (if (== @Flg (caar Lst))
               (when (run (cdar Lst))
                  (br End) )
               (setq Flg (eval (caar Lst)))
               (let Body (+lbl)
                  (br Flg @Lbl5 @Lbl6)
                  (label Body)
                  (and (run (cdar Lst)) (br End)) ) )
            (label End)
            T ) ) )
   (llvm~cond T Body Skip End Skip Body End)
   (llvm~nond NIL Skip Body Skip End End Body) )

(asm ()
   (Lst
      (let (True (+lbl)  End (if (asoq T Lst) (+lbl) True)  X (eval (++ Lst)))
         (link
            (pack
               "switch " (type (val X)) " " X
               ", label %$" (+phi True) " [" ) )
         (let Lbl
            (extract
               '((Prg)
                  (unless (=T (car Prg))
                     (let Y (eval (car Prg))
                        (prog1
                           (+lbl)
                           (link
                              (pack
                                 "  " (type (val X)) " " Y
                                 ", label %$" (+phi @ ) ) ) ) ) ) )
               Lst )
            (link "]")
            (for Prg Lst
               (label (if (=T (++ Prg)) True (++ Lbl)))
               (and (run Prg) (br End)) ) )
         (label End)
         T ) )
   (llvm~case) )

(asm ()
   (Prg
      (let (Flg (eval (++ Prg))  False (+lbl))
         (default *Exit (cons (+lbl) (box)))
         (if Prg
            (let True (+lbl)
               (br Flg True False)
               (label True)
               (let? X (run Prg)
                  (when (and *? (cdr *Exit))
                     (set @ X)
                     (phi (car *Exit) @) )
                  (br (car *Exit)) ) )
            (br Flg (car *Exit) False) )
         (label False) )
      T )
   (llvm~?) )

(asm (@Lbl1 @Lbl2)
   (Prg
      (let Beg (+lbl)
         (br Beg)
         (label Beg)
         (let (Flg (eval (++ Prg))  Body (+lbl)  *Exit (cons (+lbl))  *?)
            (br Flg @Lbl1 @Lbl2)
            (label Body)
            (and (run Prg) (br Beg))
            (label (car *Exit)) ) )
      T )
   (llvm~while Body (car *Exit))
   (llvm~until (car *Exit) Body) )

(asm ()
   (Prg
      (let (Beg (+lbl)  *? (and (=T (car Prg)) (++ Prg))  *Exit)
         (br Beg)
         (label Beg)
         (and (run Prg) (br Beg))
         (and *Exit (label (car *Exit))) ) )
   (llvm~loop) )

(asm ()
   ((Fun . @)
      (let
         (L (val Fun)
            F (func L)
            A
            (mapcar
               '((Typ) (pack Typ " " (next)))
               (cdr L) ) )
         (ssa (inc '*Ssa) "load " F ", " F "* " Fun)
         (let S
            (pack "call "
               (car L) " " (pack "%" *Ssa)
               "(" (glue ", " A) ")" )
            (if (== void (car L))
               (link S)
               (ssa (inc '*Ssa) S)
               (def (pack "%" *Ssa) (car L)) ) ) ) )
   (llvm~call) )

(asm ()
   ((Lbl . Prg)
      (br (- Lbl))
      (label (- Lbl))
      (run Prg) )
   (llvm~:) )

(asm ()
   ((Lbl) (br (- Lbl)) NIL)
   (llvm~goto) )

(asm ()
   ((X)
      (if (== void *Ret)
         (link "ret void")
         (link (pack "ret " *Ret " " X)) )
      NIL )
   (llvm~ret) )

## Composite ##
(symbols '(llvm cc pico))

(local) (i ii iii iv v vi vii viii ix caar cadr cdar cddr eval run save evList)

(for (@I . S) '(i ii iii iv v vi vii viii ix)
   (def S
      (curry (@I) (X)
         (log (up))
         (ofs X @I) ) ) )

(pico~de caar (X)
   (log (up))
   (car (car X)) )

(pico~de cadr (X)
   (log (up))
   (car (cdr X)) )

(pico~de cdar (X)
   (log (up))
   (cdr (car X)) )

(pico~de cddr (X)
   (log (up))
   (cdr (cdr X)) )

(pico~de eval (X)
   (log (up))
   (cond T
      ((num? X) X)
      ((sym? X) (car X))
      (T (evList X)) ) )

(pico~de run (Bnd2)
   (log (up))
   (pico~let *Bind (cons 'Bnd2 *Bind)
      (loop T
         (? (atom (cdr Bnd2))
            (eval (car Bnd2)) )
         (when (pair (car Bnd2))
            (evList (car Bnd2)) )
         (setq Bnd2 (cdr Bnd2)) ) ) )

(pico~de save (X Y . Prg2)
   (log (up))
   (pico~let P (push X Y NIL)
      (link P)
      (setq @ X)
      (prog1
         (pico~run Prg2)
         (drop P) ) ) )