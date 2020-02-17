# 17feb20 Software Lab. Alexander Burger

(compile) (objFile objId dbTouch)

# Get file number from external symbol name
(de i64 objFile (X)
   (|
      (& (setq X (shr X 24)) (hex "FF"))  # Low 8 bits
      (& (shr X 4) (hex "FF0000")) ) )  # High 8 bits

# Get object ID from external symbol name
(de i64 objId (X)
   (|
      (|
         (& (setq X (shr X 4)) (hex "FFFFF"))  # Lowest 20 bits
         (& (setq X (shr X 8)) (hex "FFF00000")) )  # Middle 12 bits
      (& (shr X 8) (hex "3FF00000000")) ) )  # Highest 10 bits

(de dbTouch (Sym)
   Sym )
