# 17nov19 Software Lab. Alexander Burger

(compile) (GcData Env)

(var $Link 0)  # Link register

(var $AV0 i8* null)     # Command name
(var $AV i8** null)     # Command line argument vector
(var $Home i8* null)    # Home directory
(var $Heaps 0)          # Heap list
(var $Avail 0)          # Avail list

(var $TtyPid i32 0)              # Terminal process ID
(var $InFDs i32 0)               # Number of input files
(var $InFiles i8** null)         # Input files
(var $OutFDs i32 0)              # Number of ourput files
(var $OutFiles i8** null)        # Output files
(var $PutBin (void any) null)    # Binary output function
(var $GetBin (any) null)         # Binary input function
(var $SeedL i64 0)               # Random seed low
(var $SeedH i64 0)               # Random seed high
(var $TickU i64 0)               # Ticks in user time
(var $TickS i64 0)               # Ticks in system time
(var $Slot i32 0)                # Child index
(var $Spkr i32 0)                # RPC loadspeaker
(var $Mic i32 0)                 # RPC microphone
(var $SpMiPipe i64 0)            # Speaker/microphone pipe
(var $Hear i32 0)                # RPC listener
(var $Tell i32 0)                # RPC broadcaster
(var $TellBuf i8* null)          # RPC buffer
(var $Talking i32 0)             # Active child
(var $Children i32 0)            # Number of children
(var $Child i8* null)            # Child array

# Console line
(array $Line i64
   0    # cnt
   0 )  # name

# Signals
(array $Signal i32  # Sync src/lib.c 'xErrno'
   0    # Count
   0    # SIGHUP
   0    # SIGINT
   0    # SIGUSR1
   0    # SIGUSR2
   0    # SIGPIPE
   0    # SIGALRM
   0    # SIGTERM
   0    # SIGCHLD
   0    # SIGCONT
   0    # SIGSTOP
   0    # SIGTSTP
   0    # SIGTTIN
   0    # SIGTTOU
   0 )  # SIGIO

# Symbol Table
(symTab
   ($Nil "NIL" $Nil)    # NIL symbol
   (NIL $Nil 0)         # CDR of NIL as empty list
   ($Db1 0 $Nil)        # Database root symbol
   ($Pico $Nil $Nil 0)  # Initial namespace
   # Protected symbols
   ($pico "pico" $Pico)
   ($Pico1 $pico $Nil 0)
   ($DB "*DB" $Db1)
   ($Meth "meth" _meth)
   ($Quote "quote" _quote)
   ## Sync src/pico.h 'T' (9*2+1)
   ($T "T" $T)
   ($I "I" $Nil)
   ($N "N" $Nil)
   ($S "S" $Nil)
   ($C "C" $Nil)
   ($B "B" $Nil)
   ($Solo "*Solo" ZERO)
   ($PPid "*PPid" $Nil)
   ($Pid "*Pid" 0)
   ($At "@" $Nil)
   ($At2 "@@" $Nil)
   ($At3 "@@@" $Nil)
   ($This "This" $Nil)
   ($Prompt "*Prompt" $Nil)
   ($Zap "*Zap" $Nil)
   ($Ext "*Ext" $Nil)
   ($Scl "*Scl" ZERO)
   ($Class "*Class" $Nil)
   ($Run "*Run" $Nil)
   ($Hup "*Hup" $Nil)
   ($Sig1 "*Sig1" $Nil)
   ($Sig2 "*Sig2" $Nil)
   ($TStp1 "*TStp1" $Nil)
   ($TStp2 "*TStp2" $Nil)
   ($Up "\^" $Nil)
   ($Err "*Err" $Nil)
   ($Msg "*Msg" $Nil)
   ($Uni "*Uni" $Nil)
   ($Led "*Led" $Nil)
   ($Adr "*Adr" $Nil)
   ($Fork "*Fork" $Nil)
   ($Bye "*Bye" $Nil)
   ($Dbg "*Dbg" $Nil)
   # Garbage collection
   # Arithmetics
   (NIL "+" _add)
   (NIL "-" _sub)
   (NIL "inc" _inc)
   (NIL "dec" _dec)
   (NIL "=" _equal)
   (NIL ">=" _ge)
   # Symbol functions
   # Input/Output
   (NIL "read" _read)
   (NIL "in" _in)
   (NIL "out" _out)
   (NIL "prin" _prin)
   (NIL "prinl" _prinl)
   (NIL "space" _space)
   (NIL "print" _print)
   (NIL "printsp" _printsp)
   (NIL "println" _println)
   (NIL "flush" _flush)
   (NIL "load" _load)
   # Mapping
   # Control flow
   (NIL "de" _de)
   (NIL "and" _and)
   (NIL "if" _if)
   (NIL "bye" _bye)
   # List processing
   (NIL "car" _car)
   (NIL "cdr" _cdr)
   (NIL "cons" _cons)
   (NIL "list" _list)
   # Database
   # Networking
   ($LastSym "udp" _udp)
   # System functions
   (NIL "native" _native)
   (NIL "args" _args)
   (NIL "next" _next)
   (NIL "rest" _rest) )

# GC relevant data
(table GcData
   ($Transient $Nil)    # Short transient names
   (NIL $Nil)           # Long transient names
   ($Alarm $Nil)        # Alarm handler
   ($Sigio $Nil)        # Sigio handler
   ($Extern $Nil)       # External symbol tree
   )

# Structures
(table Env
   ($Chr i32 0)                  # Single-char look ahead
   ($Put (void i32) _putStdout)  # Character output function
   ($Get (i32) _getStdin)        # Character input function
   ($InFile i8* null)            # Input file
   ($OutFile i8* null)           # Output file
   ($Bind 0)                     # Bind frames
   ($Catch i8* null)             # Catch frames
   ($InFrames i8* null)          # Input frames
   ($OutFrames i8* null)         # Output frames
   ($ErrFrames i8* null)         # Error frames
   ($CtlFrames i8* null)         # Control frames
   ($Intern $Pico1)              # Current namespaces of internal symbols
   ($Next $Nil)                  # Next vararg
   ($Cls 0)                      # Method class
   ($Key 0)                      # Method key
   ($Apply 0)                    # Apply frames
   ($Make 0)                     # 'make' env
   ($Yoke 0)
   ($Task $Nil)                  # Task list
   ($Protect 0)                  # Signal protection
   ($Trace 0) )                  # Trace level

(var $FoundSym 0)

# Bytes

# Strings
(str $Delim " \t\n\r\"'(),[]`~{}")
