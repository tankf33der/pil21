# 31oct19 Software Lab. Alexander Burger

.SILENT:

SRC = main.l \
   vers.l defs.l glob.l \
   gc.l big.l sym.l db.l \
   io.l apply.l flow.l subr.l net.l

BIN = ../bin
LIB = ../lib
CC = gcc

all: $(BIN)/picolisp

$(BIN)/picolisp: picolisp.bc
	mkdir -p $(BIN) $(LIB)
	llc picolisp.bc -relocation-model=pic -o picolisp.s
	$(CC) picolisp.s -o $(BIN)/picolisp -lc -lm -ldl -lffi

picolisp.bc: main.bc lib.bc
	llvm-link -o picolisp.bc main.bc lib.bc

lib.bc: pico.h lib.c
	clang -c -O3 `pkg-config --cflags libffi` -emit-llvm lib.c

main.bc: lib/llvm.l $(SRC)
	pil lib/llvm.l main.l -bye |llvm-as -o main.bc -

clean:
	rm -f *.bc *.s
