MODULE TestC;

(**************************************************************************

  Test program for CmplxLib.

            Aug 16, 1995 -- Created by Anthony Busigin.

**************************************************************************)

IMPORT
  InOut, RealInOut, CmplxLib;

VAR
  x, y, z : CmplxLib.LONGCOMPLEX;
  a       : LONGREAL;
BEGIN
  x := CmplxLib.lcmplx(  1.0,  2.0 );
  y := CmplxLib.lcmplx( 10.0, 12.0 );
  z := CmplxLib.lcmplx( 15.0, 20.0 );
  a := 99.0;
  InOut.WriteString("x              = "); CmplxLib.WriteLongComplex(x,12); InOut.WriteLn;
  InOut.WriteString("y              = "); CmplxLib.WriteLongComplex(y,12); InOut.WriteLn;
  InOut.WriteString("z              = "); CmplxLib.WriteLongComplex(z,12); InOut.WriteLn;
  InOut.WriteString("a              = "); RealInOut.WriteLongReal(a,12); InOut.WriteLn;
  InOut.WriteString("x+y            = "); CmplxLib.WriteLongComplex(CmplxLib.cadd(x,y),12); InOut.WriteLn;
  InOut.WriteString("x-y            = "); CmplxLib.WriteLongComplex(CmplxLib.csub(x,y),12); InOut.WriteLn;
  InOut.WriteString("x*y            = "); CmplxLib.WriteLongComplex(CmplxLib.cmul(x,y),12); InOut.WriteLn;
  InOut.WriteString("x/y            = "); CmplxLib.WriteLongComplex(CmplxLib.cdiv(x,y),12); InOut.WriteLn;
  InOut.WriteString("a*x            = "); CmplxLib.WriteLongComplex(CmplxLib.rcmul(a,x),12); InOut.WriteLn;
  InOut.WriteString("x/a            = "); CmplxLib.WriteLongComplex(CmplxLib.cdivr(x,a),12); InOut.WriteLn;
  InOut.WriteString("conjg(x)       = "); CmplxLib.WriteLongComplex(CmplxLib.conjg(x),12); InOut.WriteLn;
  InOut.WriteString("csqr(x)        = "); CmplxLib.WriteLongComplex(CmplxLib.csqr(x),12); InOut.WriteLn;
  InOut.WriteString("csqrt(x)       = "); CmplxLib.WriteLongComplex(CmplxLib.csqrt(x),12); InOut.WriteLn;
  InOut.WriteString("csqr(csqrt(x)) = "); CmplxLib.WriteLongComplex(CmplxLib.csqr(CmplxLib.csqrt(x)),12); InOut.WriteLn;
  InOut.WriteString("cexp(x)        = "); CmplxLib.WriteLongComplex(CmplxLib.cexp(x),12); InOut.WriteLn;
  InOut.WriteString("cln(x)         = "); CmplxLib.WriteLongComplex(CmplxLib.cln(x),12); InOut.WriteLn;
  InOut.WriteString("cexp(cln(x))   = "); CmplxLib.WriteLongComplex(CmplxLib.cexp(CmplxLib.cln(x)),12); InOut.WriteLn;
  InOut.WriteString("csin(x)        = "); CmplxLib.WriteLongComplex(CmplxLib.csin(x),12); InOut.WriteLn;
  InOut.WriteString("ccos(x)        = "); CmplxLib.WriteLongComplex(CmplxLib.ccos(x),12); InOut.WriteLn;
  InOut.WriteString("cmag(x)        = "); RealInOut.WriteLongReal(CmplxLib.cmag(x),12); InOut.WriteLn;
END TestC.
