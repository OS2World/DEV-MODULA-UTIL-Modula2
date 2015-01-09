IMPLEMENTATION MODULE ComplexLib;

(**************************************************************************
  OS/2 2.x  Modula-2 complex number library

            Aug 16, 1995 -- Created.

  Copyright (c) 1995 by Anthony Busigin. Permission is granted for
  use of this software with the Modula-2 OS/2-compiler by Juergen Neuhoff.

  Note: This library is a work in progress. SHORTCOMPLEX functions will
        be added in a future version of the library.
**************************************************************************)

(*$XL+*)
(*$F+  allow coprocessor instructions for INLINE assembler *)

IMPORT
  InOut,
  MathLib0,
  RealInOut,
  SYSTEM;

FROM SYSTEM IMPORT INLINE, ADR;


PROCEDURE cadd( x, y : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns x+y *)
BEGIN
  INLINE
  (
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* load address of result *)
  FLD     x.r[ EBP ]                    (* x.r *)
  FADD    y.r[ EBP ]                    (* y.r+x.r *)
  FSTP    QWORD PTR [ EDI ]             (* cadd.r := ST *)
  FLD     x.i[ EBP ]                    (* x.i *)
  FADD    y.i[ EBP ]                    (* y.i+xi *)
  FSTP    QWORD PTR [ EDI + 8 ]         (* cadd.i := ST *)
  FWAIT
  POP     EDI
  );
END cadd;


PROCEDURE csub( x, y : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns x-y *)
BEGIN
  INLINE
  (
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* load address of result *)
  FLD     x.r[ EBP ]                    (* x.r *)
  FSUB    y.r[ EBP ]                    (* y.r+x.r *)
  FSTP    QWORD PTR [ EDI ]             (* cadd.r := ST *)
  FLD     x.i[ EBP ]                    (* x.i *)
  FSUB    y.i[ EBP ]                    (* y.i+xi *)
  FSTP    QWORD PTR [ EDI + 8 ]         (* cadd.i := ST *)
  FWAIT
  POP     EDI
  );
END csub;


PROCEDURE cmul( x, y : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns x*y *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* load address of result *)
  FLD     x.r[ EBP ]                    (* r *)
  FLD     x.i[ EBP ]                    (* i r *)
  FLD     y.r[ EBP ]                    (* rr i r *)
  FLD     y.i[ EBP ]                    (* ii rr i r *)
  FLD     ST                            (* ii ii rr i r *)
  FMUL    ST, ST(3)                     (* i*ii ii rr i r *)
  FXCH    ST(1)                         (* ii i*ii rr i r *)
  FMUL    ST, ST(4)                     (* r*ii i*ii rr i r *)
  FXCH    ST(2)                         (* rr i*ii r*ii i r *)
  FMUL    ST(3), ST                     (* rr i*ii r*ii i*rr r *)
  FMULP   ST(4), ST                     (* i*ii r*ii i*rr r*rr *)
  FSUBP   ST(3), ST                     (* r*ii i*rr (r*rr-i*ii) *)
  FADDP   ST(1), ST                     (* (r*ii+i*rr) (r*rr-i*ii) *)
  FSTP    QWORD PTR [ EDI + 8 ]         (* cmul.i := ST *)
  FSTP    QWORD PTR [ EDI ]             (* cmul.r := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END cmul;


PROCEDURE rcmul ( a : LONGREAL;  x: LONGCOMPLEX ) : LONGCOMPLEX;
(* returns a*x *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR a[ EBP + 8 ]   (* load address of result *)
  FLD     x.r[ EBP ]                    (* r *)
  FLD     x.i[ EBP ]                    (* i r *)
  FLD       a[ EBP ]                    (* a i r *)
  FMUL    ST(2), ST                     (* a i a*r *)
  FMULP   ST(1), ST                     (* a*i a*r *)
  FSTP    QWORD PTR [ EDI + 8 ]         (* rcmul.i := ST *)
  FSTP    QWORD PTR [ EDI ]             (* rcmul.r := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END rcmul;


PROCEDURE cdiv( x, y : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns x/y *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* load address of result *)
  FLD     x.r[ EBP ]                    (* r *)
  FLD     x.i[ EBP ]                    (* i r *)
  FLD     y.r[ EBP ]                    (* rr i r *)
  FLD     y.i[ EBP ]                    (* ii rr i r *)
  FCHS                                  (* -ii rr i r *)
  FLD     ST                            (* -ii -ii rr i r *)
  FMUL    ST, ST(3)                     (* -i*ii -ii rr i r *)
  FXCH    ST(1)                         (* -ii -i*ii rr i r *)
  FMUL    ST, ST(4)                     (* -r*ii -i*ii rr i r *)
  FXCH    ST(2)                         (* rr -i*ii -r*ii i r *)
  FMUL    ST(3), ST                     (* rr -i*ii -r*ii i*rr r *)
  FMULP   ST(4), ST                     (* -i*ii -r*ii i*rr r*rr *)
  FSUBP   ST(3), ST                     (* -r*ii i*rr (r*rr+i*ii) *)
  FADDP   ST(1), ST                     (* (-r*ii+i*rr) (r*rr+i*ii) *)
  FLD     x.r[ EBP ]                    (* x.r y.i y.r *)
  FMUL    ST, ST                        (* x.r*x.r y.i y.r *)
  FLD     x.i[ EBP ]                    (* x.i x.r*x.r y.i y.r *)
  FMUL    ST, ST                        (* x.i*x.i x.r*x.r y.i y.r *)
  FADDP   ST(1), ST                     (* r y.i y.r *)
  FDIV    ST(1), ST                     (* r y.i/r y.r *)
  FDIVP   ST(2), ST                     (* y.i/r y.r/r *)
  FSTP    QWORD PTR [ EDI + 8 ]         (* cmul.i := ST *)
  FSTP    QWORD PTR [ EDI ]             (* cmul.r := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END cdiv;


PROCEDURE cdivr ( x: LONGCOMPLEX; a : LONGREAL ) : LONGCOMPLEX;
(* returns x/a *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* load address of result *)
  FLD     x.r[ EBP ]                    (* r *)
  FLD     x.i[ EBP ]                    (* i r *)
  FLD       a[ EBP ]                    (* a i r *)
  FDIV    ST(2), ST                     (* a i r/a *)
  FDIVP   ST(1), ST                     (* i/a r/a *)
  FSTP    QWORD PTR [ EDI + 8 ]         (* cdivr.i := ST *)
  FSTP    QWORD PTR [ EDI ]             (* cdivr.r := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END cdivr;


PROCEDURE csqr( x : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns x*x *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* load address of result *)
  FLD     x.r[ EBP ]
  FLD     x.i[ EBP ]                    (* i r *)
  FLD     ST                            (* i i r *)
  FMUL    ST(1), ST                     (* i i*i r *)
  FMUL    ST, ST(2)                     (* r*i i*i r *)
  FADD    ST, ST                        (* 2*r*i i*i r *)
  FXCH    ST(2)                         (* r i*i 2*r*i *)
  FMUL    ST, ST                        (* r*r i*i 2*r*i *)
  FSUBRP  ST(1), ST                     (* (r*r - i*i) 2*r*i *)
  FSTP    QWORD PTR [ EDI ]             (* csqr.r := ST *)
  FSTP    QWORD PTR [ EDI + 8 ]         (* csqr.i := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END csqr;


PROCEDURE csqrt( x : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns complex square root of x *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* load address of result *)
  FLD     x.r[ EBP ]
  FLD     x.i[ EBP ]                    (* i r *)
  FTST
  FSTSW   AX
  SAHF
  JNE     L1
  (* fall through here if imaginary part is 0 *)
  FXCH    ST(1)                         (* r i *)
  FTST
  FSTSW   AX
  SAHF
  JB      L0
  (* fall through if real part is > 0 *)
  FSQRT                                 (* sqrt(r) i *)
  FXCH    ST(1)                         (* i sqrt(r) *)
  JMP     Done
L0:
  FABS
  FSQRT                                 (* sqrt(abs(r))  i *)
  JMP     Done
L1:   (* come here if imaginary part not zero *)
  FXCH    ST(1)                         (* r i *)
  FTST
  FSTSW   AX
  SAHF
  JNE     L2
  (* fall through here if real part is 0 *)
  FSTP    ST                            (* i *)
  FLD1                                  (* 1 i *)
  FCHS                                  (* -1 i *)
  FXCH    ST(1)                         (* i -1 *)
  FSCALE                                (* i/2 -1 *)
  FSQRT                                 (* sqrt(i/2) -1 *)
  FST     ST(1)                         (* sqrt(i/2) sqrt(i/2) *)
  JMP     Done
L2:   (* come here if both real and imaginary parts not zero *)
  (* 80x87 stack : r i *)
  FLD     ST                            (* r r i *)
  FMUL    ST, ST                        (* r*r r i *)
  FLD     ST(2)                         (* i r*r r i *)
  FMUL    ST, ST                        (* i*i r*r r i *)
  FADDP   ST(1), ST                     (* (r*r+i*i) r i *)
  FSQRT                                 (* sqrt(r*r+i*i) r i *)
  JB      L3
  (* come here if real part > 0 *)
  FADD    ST, ST(1)                     (* r+sqrt(r*r+i*i) r i *)
  FLD1                                  (* 1 r+sqrt(r*r+i*i) r i *)
  FCHS                                  (* -1 r+sqrt(r*r+i*i) r i *)
  FXCH    ST(1)                         (* r+sqrt(r*r+i*i) -1 r i *)
  FSCALE                                (* (r+sqrt(r*r+i*i))/2 -1 r i *)
  FSQRT                                 (* rr -1 r i *)
  FXCH    ST(3)                         (* i -1 r rr *)
  FDIV    ST, ST(3)                     (* i/rr -1 r rr *)
  FSCALE                                (* ii -1 r rr *)
  FSTP    ST(1)                         (* ii r rr *)
  FSTP    ST(1)                         (* ii rr *)
  JMP     Done
L3:   (* come here if real part < 0 *)
  FSUB    ST, ST(1)                     (* -r+sqrt(r*r+i*i) r i *)
  FLD1                                  (* 1 -r+sqrt(r*r+i*i) r i *)
  FCHS                                  (* -1 -r+sqr t(r*r+i*i) r i *)
  FXCH    ST(1)                         (* -r+sqrt(r*r+i*i) -1 r i *)
  FSCALE                                (* (-r+sqrt(r*r+i*i))/2 -1 r i *)
  FSQRT                                 (* ii -1 r i *)
  FXCH    ST(3)                         (* i -1 r ii *)
  FDIV    ST, ST(3)                     (* i/ii -1 r ii *)
  FSCALE                                (* rr -1 r ii *)
  FSTP    ST(1)                         (* rr r ii *)
  FSTP    ST(1)                         (* rr ii *)
  FXCH    ST(1)                         (* ii rr *)
Done:
  FSTP    QWORD PTR [ EDI + 8 ]         (* csqrt.i := ST *)
  FSTP    QWORD PTR [ EDI ]             (* csqrt.r := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END csqrt;


PROCEDURE lcmplx( r, i : LONGREAL ) : LONGCOMPLEX;
(* returns complex number *)
BEGIN
  INLINE
  (
  PUSH    EDI
  MOV     EDI, DWORD PTR r[ EBP + 8 ]  (* hidden address of result *)
  FLD     r[ EBP ]                     (* real part *)
  FSTP    QWORD PTR [ EDI ]            (* lcmplx.r := ST *)
  FLD     i[ EBP ]                     (* imaginary part *)
  FSTP    QWORD PTR [ EDI + 8 ]        (* lcmplx.i := ST *)
  FWAIT
  POP     EDI
  );
END lcmplx;


PROCEDURE cmag( x : LONGCOMPLEX ) : LONGREAL;
(* returns magnitude of x = sqrt(x.r*x.r+x.i*x.i) *)
BEGIN
  INLINE
  (
  FLD     x.r[ EBP ]
  FMUL    ST, ST
  FSTP    x.r[ EBP ]
  FLD     x.i[ EBP ]
  FMUL    ST, ST
  FADD    x.r[ EBP ]
  FSQRT
  );
END cmag;


PROCEDURE conjg ( x : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns complex conjugate of x *)
BEGIN
  INLINE
  (
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ]  (* hidden address of result *)
  FLD     x.r[ EBP ]                    (* real part *)
  FSTP    QWORD PTR [ EDI ]             (* conjg.r := ST *)
  FLD     x.i[ EBP ]                    (* imaginary part *)
  FCHS
  FSTP    QWORD PTR [ EDI + 8 ]         (* conjg.i := ST *)
  FWAIT
  POP     EDI
  );
END conjg;


PROCEDURE cexp ( x : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns complex exp(x) *)
VAR
  ex     : LONGREAL;
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  ex := MathLib0.exp( x.r );
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ] (* hidden address of result *)
  FLD     x.i[ EBP ]                   (* x.i *)
  FSINCOS                              (* cos(x.i) sin(x.i) *)
  FMUL    ex[ EBP ]                    (* ex*cos(x.i) sin(x.i) *)
  FSTP    QWORD PTR [ EDI ]            (* cexp.r := ST *)
  FMUL    ex[ EBP ]                    (* ex*sin(x.i) *)
  FSTP    QWORD PTR [ EDI + 8 ]        (* cexp.i := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END cexp;


PROCEDURE cln ( x : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns complex ln(x) *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
BEGIN
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ] (* hidden address of result *)
  FLD     x.r[ EBP ]                   (* r *)
  FLD     x.i[ EBP ]                   (* i r *)
  FLD1                                 (* 1 i r *)
  FCHS                                 (* -1 i r *)
  FLD     ST(1)                        (* i -1 i r *)
  FMUL    ST, ST                       (* i*i -1 i r *)
  FLD     ST(3)                        (* r i*i -1 i r *)
  FMUL    ST, ST                       (* r*r i*i -1 i r *)
  FADDP   ST(1), ST                    (* (r*r+i*i) -1 i r *)
  FLDLN2                               (* log2e (r*r+i*i) -1 i r *)
  FXCH    ST(1)                        (* (r*r+i*i)/2 log2e -1 i r *)
  FYL2X                                (* ln(r*r+i*i) -1 i r *)
  FSCALE
  FSTP    ST(1)                        (* 0.5*ln(r*r+i*i) i r *)
  FSTP    QWORD PTR [ EDI ]            (* cln.r := ST *)
  FXCH    ST(1)                        (* r i *)
  FPATAN                               (* atan(ST(1)/ST) *)
  FSTP    QWORD PTR [ EDI + 8 ]        (* cln.i := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END cln;


PROCEDURE csin ( x : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns complex sin(x) *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
  ex     : LONGREAL;
BEGIN
  ex := MathLib0.exp( x.i );
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ] (* hidden address of result *)
  FLD     x.r[ EBP ]                   (* x.r *)
  FSINCOS                              (* cos(x.r) sin(x.r) *)
  FLD1                                 (* 1 c s *)
  FLD     ex[ EBP ]                    (* ex 1 c s *)
  FDIV    ST(1), ST                    (* ex 1/ex c s *)
  FLD     ST                           (* ex ex 1/ex c s *)
  FADD    ST, ST(2)                    (* (ex+1/ex) ex 1/ex c s *)
  FMULP   ST(4), ST                    (* ex 1/ex c (ex+1/ex)*s *)
  FSUBRP  ST(1), ST                    (* (ex-1/ex) c (ex+1/ex)*s *)
  FMULP   ST(1), ST                    (* (ex-1/ex)*c (ex+1/ex)*s *)
  FLD1
  FCHS                                 (* -1 (ex-1/ex)*c (ex+1/ex)*s *)
  FXCH    ST(1)                        (* (ex-1/ex)*c -1 (ex+1/ex)*s *)
  FSCALE
  FSTP    QWORD PTR [ EDI + 8 ]        (* csin.i := ST *)
  FXCH    ST(1)                        (* (ex+1/ex)*s -1 *)
  FSCALE
  FSTP    ST(1)
  FSTP    QWORD PTR [ EDI ]
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END csin;


PROCEDURE ccos ( x : LONGCOMPLEX ) : LONGCOMPLEX;
(* returns complex cos(x) *)
VAR
  Buffer : ARRAY [0..107] OF CHAR;
  ex     : LONGREAL;
BEGIN
  ex := MathLib0.exp( x.i );
  INLINE
  (
  FSAVE   Buffer[ EBP ]
  PUSH    EDI
  MOV     EDI, DWORD PTR x[ EBP + 16 ] (* hidden address of result *)
  FLD     x.r[ EBP ]                   (* x.r *)
  FSINCOS                              (* cos(x.r) sin(x.r) *)
  FLD1                                 (* 1 c s *)
  FLD     ex[ EBP ]                    (* ex 1 c s *)
  FDIV    ST(1), ST                    (* ex 1/ex c s *)
  FLD     ST                           (* ex ex 1/ex c s *)
  FADD    ST, ST(2)                    (* (ex+1/ex) ex 1/ex c s *)
  FMULP   ST(3), ST                    (* ex 1/ex (ex+1/ex)*c s *)
  FSUBP   ST(1), ST                    (* (1/ex-ex) (ex+1/ex)*c s *)
  FMULP   ST(2), ST                    (* (ex+1/ex)*c (1/ex-ex)*s *)
  FLD1
  FCHS
  FXCH    ST(1)                        (* (ex+1/ex)*c -1 (1/ex-ex)*s *)
  FSCALE
  FSTP    QWORD PTR [ EDI ]            (* ccos.r := ST *)
  FXCH    ST(1)                        (* (1/ex-ex)*s -1 *)
  FSCALE
  FSTP    QWORD PTR [ EDI + 8 ]        (* ccos.i := ST *)
  FWAIT
  POP     EDI
  FRSTOR  Buffer[ EBP ]
  );
END ccos;


PROCEDURE WriteLongComplex( x : LONGCOMPLEX; n : INTEGER );
(* write complex number x *)
BEGIN
  InOut.Write('(');
  RealInOut.WriteLongReal( x.r, n );
  InOut.Write(',');
  RealInOut.WriteLongReal( x.i, n );
  InOut.Write(')');
END WriteLongComplex;


BEGIN
END ComplexLib.

