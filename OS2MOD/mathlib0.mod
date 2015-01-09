IMPLEMENTATION MODULE MathLib0;

(**************************************************************************
   OS/2 2.x or 3.0 Modula-2 floating point library for elemetary functions.

   Copyright (c) 1993, 1995 by Juergen Neuhoff
**************************************************************************)

(*$F+  allow coprocessor instructions for INLINE assembler               *)

FROM SYSTEM IMPORT INLINE;


PROCEDURE sqrt( x : REAL ) : REAL;
BEGIN
  INLINE
  (
    FLD   x[ EBP ]
    FSQRT
  );
END sqrt;


PROCEDURE exp( x : REAL ) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  (*
     Compute e**x using the following formulas for the 80x87 FPU:

     2**x = (2**x - 1) + 1 = F2XM1(x) + 1

     e**x = 1 + (2**(x*log2(e)) - 1)

     z    = x*log2(e)
     i    = round(z)
     f    = z - i             where |f| < 1/2
     2**z = 2**i * 2**f
     e**x = 1 + ((2**z) - 1)
  *)
  INLINE
  (
    FSAVE   Buffer[ EBP ]
    FLDL2E                ; ST = log2( e )
    FMUL    x[ EBP ]      ; ST = z = log2( e ) * x
    FLD     ST(0)
    FRNDINT               ; ST = i = round(z)       ST(1) = z
    FXCH    ST(1)         ; ST = z                  ST(1) = i
    FSUB    ST,ST(1)      ; ST = f = z - i
    F2XM1                 ; ST = 2**f - 1           ST(1) = i
    FLD1
    FADDP   ST(1),ST      ; ST = 2**f
    FSCALE                ; ST = 2**f * 2**i = 2**z
    FSTP    x[ EBP ]
    FSTP    ST
    FRSTOR  Buffer[ EBP ]
  );
  RETURN x;
END exp;


PROCEDURE ln( x : REAL ) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  (*
     Compute loge(x) using the following formulas for the 80x87 FPU:

     log2(x) = FYL2X(x)

     loge(x) = loge(2) * log2(x) = FYL2X( loge(2), x )
             = FYL2X( FLDLN2, x )
  *)
  INLINE
  (
    FSAVE  Buffer[ EBP ]
    FLDLN2
    FLD    x[ EBP ]
    FYL2X
    FSTP   x[ EBP ]
    FRSTOR Buffer[ EBP ]
  );
  RETURN x;
END ln;



PROCEDURE sin( x : REAL ) : REAL;
BEGIN
  INLINE
  (
    FLD   x[ EBP ]
    FSIN
  );
END sin;



PROCEDURE cos( x : REAL ) : REAL;
BEGIN
  INLINE
  (
    FLD      x[ EBP ]
    FCOS
  );
END cos;


PROCEDURE arctan( x : REAL ) : REAL;
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
    FSAVE    Buffer[ EBP ]
    FLD      x[ EBP ]
    FLD1
    FPATAN
    FSTP     x[ EBP ]
    FRSTOR   Buffer[ EBP ]
  );
  RETURN x;
END arctan;


PROCEDURE real( x : LONGINT ) : REAL;
BEGIN
  RETURN FLOAT( x );
END real;


PROCEDURE entier( x : REAL ) : LONGINT;
VAR
  Control  : CARDINAL;
  Val      : LONGINT;
BEGIN
  INLINE
  (
    FSTCW   Control[ EBP ]         ; save old rounding control
    MOV     AX, Control[ EBP ]
    AND     AX, 0F3FFH
    OR      AX,  0400H
    XCHG    AX, Control[ EBP ]
    FLDCW   Control[ EBP ]         ; set rounding toward negative infinity
    FLD     x[ EBP ]
    FRNDINT                        ; get rounded x
    FISTP   Val[ EBP ]             ; store as integer value
    FWAIT
    XCHG    AX, Control[ EBP ]
    FLDCW   Control[ EBP ]         ; reset to old rounding control
  );
  RETURN Val;
END entier;


END MathLib0.
