IMPLEMENTATION MODULE MathLib1;

(**************************************************************************
   OS/2 2.x  Modula-2 floating point library for supplementary
             elemetary functions.

             Created May 29, 1995.

             July 31 1995 19.15 : sinh() tanh() now saving register DX
                                  Modified Juergen Neuhoff

   Copyright (c) 1995 by Anthony Busigin. Permission is granted for
   use of this software with the Modula-2 OS/2-compiler by Juergen Neuhoff.
**************************************************************************)

(*$F+  allow coprocessor instructions for INLINE assembler               *)

FROM SYSTEM IMPORT INLINE;


PROCEDURE log10 (x: REAL) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    FSAVE    Buffer[ EBP ]
    FLD      x[EBP]
    FLDLG2
    FXCH     ST(1)
    FYL2X
    FSTP     x[EBP]
    FRSTOR   Buffer[ EBP ]
  );
  RETURN x;
END log10;


PROCEDURE alog10 (x: REAL) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    FSAVE    Buffer[ EBP ]
    FLD      x[EBP]
    FLDL2T
    FMULP    ST(1),ST
    FLD      ST                 ; x x
    FRNDINT                     ; i x
    FSUB     ST(1),ST           ; i f
    FXCH     ST(1)              ; f i
    FTST                        ; x > 0?
    FSTSW    AX
    SAHF
    JB       L0
    F2XM1                       ; 2^x - 1
    JMP      L1
  L0:
    FCHS                        ; -x
    F2XM1                       ; 2^-x - 1
    FLD1                        ; 1 (2^-x - 1)
    FADD     ST,ST(1)           ; 2^-x (2^-x - 1)
    FDIVP    ST(1),ST           ; 1 - 2^x
    FCHS                        ; 2^x - 1
  L1:
    FLD1                        ; 1 (2^f - 1) i
    FADDP    ST(1),ST           ; 2^f i
    FSCALE                      ; 2^x i
    FSTP     ST(1)              ; 2^x
    FSTP     x[EBP]
    FRSTOR   Buffer[ EBP ]
  );
  RETURN x;
END alog10;


PROCEDURE sinh (x: REAL) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    PUSH     DX
    FSAVE    Buffer[ EBP ]
    FLD      x[EBP]
    FTST
    FSTSW    AX
    MOV      DX,AX
    FLDL2E                      ; Log2(e) xs
    FMULP    ST(1),ST           ; x
    FABS
    FLD      ST                 ; x x
    FRNDINT                     ; i x
    FSUB     ST(1),ST           ; i f
    FCHS                        ; -i f
    FLD1                        ; 1 -i f
    FSCALE                      ; 2^-i -i f
    FXCH     ST(1)              ; -i 2^-i f
    FCHS                        ; i 2^-i f
    FXCH     ST(2)              ; f 2^-i i
    FTST                        ; x > 0?
    FSTSW    AX
    SAHF
    JB       L0
    F2XM1                       ; 2^x - 1
    JMP      L1
  L0:
    FCHS                        ; -x
    F2XM1                       ; 2^-x - 1
    FLD1                        ; 1 (2^-x - 1)
    FADD     ST,ST(1)           ; 2^-x (2^-x - 1)
    FDIVP    ST(1),ST           ; 1 - 2^x
    FCHS                        ; 2^x - 1
  L1:
    FLD1                        ; 1 (2^f - 1) 2^-i i
    FADD     ST,ST(1)           ; 2^f (2^f - 1) 2^-i i
    FXCH     ST(2)              ; 2^-i (2^f - 1) 2^f i
    FLD1                        ; 1 2^-i (2^f - 1) 2^f i
    FSUBP    ST(1),ST           ; (2^-i - 1) (2^f - 1) 2^f i }
    FSUBP    ST(1),ST           ; y 2^f i
    FDIVR    ST(1),ST           ; y y/2^f i
    FXCH     ST(1)              ; y/2^f y i
    FXCH     ST(2)              ; i y y/2^f
    FXCH     ST(1)              ; y i y/2^f
    FSCALE                      ; y*2^i i y/2^f
    FSTP     ST(1)              ; y*2^i y/2^f
    FADDP    ST(1),ST           ; 2*sinh(x)
    FLD1                        ; 1 2*sinh(x)
    FCHS                        ; -1 2*sinh(x)
    FXCH     ST(1)              ; 2*sinh(x) -1
    FSCALE                      ; sinh(x) -1
    FSTP     ST(1)              ; sinh(x)
    MOV      AX,DX
    SAHF
    JAE      L2
    FCHS
  L2:
    FSTP     x[EBP]
    FRSTOR   Buffer[ EBP ]
    POP      DX
  );
  RETURN x;
END sinh;


PROCEDURE cosh (x: REAL) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    FSAVE    Buffer[ EBP ]
    FLD      x[EBP]
    FLDL2E                      ; Log2(e) xs
    FMULP    ST(1),ST           ; x
    FABS
    FLD      ST                 ; x x
    FRNDINT                     ; i x
    FSUB     ST(1),ST           ; i f
    FXCH     ST(1)              ; i f
    FTST                        ; x > 0?
    FSTSW    AX
    SAHF
    JB       L0
    F2XM1                       ; 2^x - 1
    JMP      L1
  L0:
    FCHS                        ; -x
    F2XM1                       ; 2^-x - 1
    FLD1                        ; 1 (2^-x - 1)
    FADD     ST,ST(1)           ; 2^-x (2^-x - 1)
    FDIVP    ST(1),ST           ; 1 - 2^x
    FCHS                        ; 2^x - 1
  L1:
    FLD1                        ; 1 (2^f - 1) i
    FADDP    ST(1),ST           ; 2^f i
    FSCALE                      ; e^x i
    FSTP     ST(1)              ; e^x
    FLD1                        ; 1 e^x
    FDIV     ST,ST(1)           ; 1/e^x e^x
    FADDP    ST(1),ST           ; (e^x + 1/e^x)
    FLD1                        ; 1 (e^x + 1/e^x)
    FCHS                        ; -1 (e^x + 1/e^x)
    FXCH     ST(1)              ; (e^x + 1/e^x) -1
    FSCALE                      ; cosh(x) -1
    FSTP     ST(1)              ; cosh(x)
    FSTP     x[EBP]
    FRSTOR   Buffer[ EBP ]
  );
  RETURN x;
END cosh;


PROCEDURE tanh (x: REAL) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    PUSH     DX
    FSAVE    Buffer[ EBP ]
    FLD      x[EBP]
    FTST
    FSTSW    AX
    MOV      DX,AX
    FLDL2E                      ; Log2(e) xs
    FMULP    ST(1),ST           ; x
    FADD     ST,ST              ; 2*x
    FABS
    FLD      ST                 ; x x
    FRNDINT                     ; i x
    FSUB     ST(1),ST           ; i f
    FCHS                        ; -i f
    FLD1                        ; 1 -i f
    FSCALE                      ; 2^-i -i f
    FSTP     ST(1)              ; 2^-i f
    FLD1                        ; 1 2^-i f
    FSUBP    ST(1),ST           ; (2^-i - 1) f
    FXCH     ST(1)              ; f (2^-2*i - 1)
    FTST                        ; x > 0?
    FSTSW    AX
    SAHF
    JB       L0
    F2XM1                       ; 2^x - 1
    JMP      L1
  L0:
    FCHS                        ; -x
    F2XM1                       ; 2^-x - 1
    FLD1                        ; 1 (2^-x - 1)
    FADD     ST,ST(1)           ; 2^-x (2^-x - 1)
    FDIVP    ST(1),ST           ; 1 - 2^x
    FCHS                        ; 2^x - 1
  L1:
    FLD      ST                 ; (2^f - 1) (2^f - 1)
                                ; (2^-i - 1) }
    FSUB     ST,ST(2)           ; y (2^f - 1) (2^-i - 1)
    FXCH     ST(1)              ; (2^f - 1) y (2^-i - 1)
    FADDP    ST(2),ST           ; y z
    FLD1                        ; 1 y z
    FADD     ST(2),ST
    FADDP    ST(2),ST           ; y (z+2)
    FDIVRP   ST(1),ST           ; y/(z+2)
    MOV      AX,DX
    SAHF
    JAE      L2
    FCHS
  L2:
    FSTP     x[EBP]
    FRSTOR   Buffer[ EBP ]
    POP      DX
  );
  RETURN x;
END tanh;


PROCEDURE XtoY(x,y: REAL) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    FSAVE    Buffer[ EBP ]
    FLD      y[EBP]
    FLD      x[EBP]
    FABS
    FYL2X
    FLD      ST                 ; x x
    FRNDINT                     ; i x
    FSUB     ST(1),ST           ; i f
    FXCH     ST(1)              ; f i
    FTST                        ; x > 0?
    FSTSW    AX
    SAHF
    JB       L0
    F2XM1                       ; 2^x - 1
    JMP      L1
  L0:
    FCHS                        ; -x
    F2XM1                       ; 2^-x - 1
    FLD1                        ; 1 (2^-x - 1)
    FADD     ST,ST(1)           ; 2^-x (2^-x - 1)
    FDIVP    ST(1),ST           ; 1 - 2^x
    FCHS                        ; 2^x - 1
  L1:
    FLD1                        ; 1 (2^f - 1) i
    FADDP    ST(1),ST           ; 2^f i
    FSCALE                      ; 2^x i
    FSTP     ST(1)              ; 2^x
    FWAIT
    FSTP     x[EBP]
    FRSTOR   Buffer[ EBP ]
  );
  RETURN x;
END XtoY;


PROCEDURE tan (x: REAL) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    FSAVE    Buffer[ EBP ]
    FLD      x[ EBP ]
    FSINCOS
    FDIVP    ST(1),ST
    FSTP     x[ EBP ]
    FRSTOR   Buffer[ EBP ]
  );
  RETURN x;
END tan;

END MathLib1.
