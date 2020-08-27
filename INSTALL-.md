# macOS 10.15

```
$ brew install llvm libffi ncurses readline
$ cd pil21/src
$ llvm-as -o base.bc base.ll
$ clang -c -O3 -D_OS='"Macos"' -D_CPU='"x86-64"' -I/usr/local/opt/libffi/include -emit-llvm lib.c -I/usr/local/opt/readline/include
$ llvm-link -o picolisp.bc base.bc lib.bc
$ mkdir -p ../bin ../lib
$ llc picolisp.bc -o picolisp.s
$ clang picolisp.s -o ../bin/picolisp -lm -ldl -lffi -lreadline -lncurses -L/usr/local/opt/readline/lib
$ gcc sysdefs.c && ./a.out > ../lib/sysdefs
$ ../pil
: (version)
21.0.0
-> (21 0 0)
: (bye)
$
```

