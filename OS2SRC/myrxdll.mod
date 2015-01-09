IMPLEMENTATION MODULE MyRxDLL;

(**************************************************************************
  OS/2 2.x/Warp  Modula-2 sample REXX-DLL.

  Copyright (c) 1995 by Anthony Busigin. 
**************************************************************************)


(*$XL+*)

IMPORT Conversions, RealConversions, Strings, DOS;

FROM OS2DEF IMPORT APIRET;

FROM SYSTEM IMPORT ADDRESS, INLINE, ADR;

CONST
  RXERROR = 40;
  RXOK    = 0;
  CR        = CHAR(0DH);

TYPE
  SZCMD = ARRAY[0..30] OF CHAR;


PROCEDURE IncAddr ( p : ADDRESS; n : LONGCARD ) : ADDRESS;
BEGIN
  INLINE
  (
  MOV     EAX, p[ EBP ]
  ADD     EAX, n[ EBP ]
  );
END IncAddr;


PROCEDURE ClipRange(x,xmin,xmax: LONGREAL): LONGREAL;
BEGIN
  IF x < xmin THEN
    RETURN xmin;
  ELSIF x > xmax THEN
    RETURN xmax;
  ELSE
    RETURN x;
  END;
END ClipRange;


PROCEDURE Caps( VAR sz : ARRAY OF CHAR );
VAR
  i, N : LONGCARD;
BEGIN
  N := Strings.Size( sz );
  IF N > 0 THEN
    FOR i := 0 TO N-1 DO
      sz[i] := CAP( sz[i] );
    END;
  END;
END Caps;


(*$CDECL+*)

(*-------------------------------------------------------------------*)
(* REXX procedure to call DosSleep function for a specfied duration  *)
(* in milliseconds.                                                  *)
(* Usage: CALL RxDelay 100                                           *)
(*-------------------------------------------------------------------*)
PROCEDURE RXDELAY  ( VAR func : ARRAY OF CHAR;
                         argc : LONGCARD;
                        pargv : PRXSTRING;
                     VAR  que : ARRAY OF CHAR;
                     VAR  ret : RXSTRING) : LONGCARD;
VAR
  ms : LONGCARD;
  OK : BOOLEAN;
  rc : APIRET;
BEGIN
  OK := Conversions.StrToLongCard(pargv^.strptr^,ms);
  IF OK THEN
    ret.strptr^ := "";
    ret.strlen  := 0;
    rc := DOS.DosSleep(ms);
    RETURN RXOK;
  END;
  ret.strptr^ := "ERROR";
  ret.strlen  := Strings.Size(ret.strptr^);
  RETURN RXERROR;
END RXDELAY;

(*-------------------------------------------------------------------*)
(* REXX procedure to constrain a number within a specified range.    *)
(* Usage: xclipped = RxClipRange( x, xmin, xmax )                    *)
(*-------------------------------------------------------------------*)
PROCEDURE RXCLIPRANGE ( VAR func : ARRAY OF CHAR;
                            argc : LONGCARD;
                           pargv : PRXSTRING;
                        VAR que  : ARRAY OF CHAR;
                        VAR ret  : RXSTRING) : LONGCARD;
VAR
  px, pmin, pmax     : PRXSTRING;
  x,  xmin, xmax, z  : LONGREAL;
  OK : BOOLEAN;
BEGIN
  IF argc # 3 THEN
    ret.strptr^ := "ERROR: 3 arguments required for function RxClipRange().";
    ret.strlen  := Strings.Size(ret.strptr^);
    RETURN RXERROR;
  ELSE
    (* extract the function parameters *)
    px   := pargv;
    pmin := IncAddr(pargv,SIZE(pargv^));
    pmax := IncAddr(pargv,2*SIZE(pargv^));
    OK := RealConversions.StrToReal(px^.strptr^,x);
    IF OK <> TRUE THEN
      ret.strptr^ := "ERROR: function RxClipRange() 1st argument is not a valid number.";
      ret.strlen  := Strings.Size(ret.strptr^);
      RETURN RXERROR;
    END;
    OK := RealConversions.StrToReal(pmin^.strptr^,xmin);
    IF OK <> TRUE THEN
      ret.strptr^ := "ERROR: function RxClipRange() 2nd argument is not a valid number.";
      ret.strlen  := Strings.Size(ret.strptr^);
      RETURN RXERROR;
    END;
    OK := RealConversions.StrToReal(pmax^.strptr^,xmax);
    IF OK <> TRUE THEN
      ret.strptr^ := "ERROR: function RxClipRange() 3rd argument is not a valid number.";
      ret.strlen  := Strings.Size(ret.strptr^);
      RETURN RXERROR;
    END;
    z := ClipRange(x,xmin,xmax);
    OK := RealConversions.RealToStr(z,-9,ret.strptr^);
    ret.strlen  := Strings.Size(ret.strptr^);
    RETURN RXOK;
  END;
END RXCLIPRANGE;


(*-------------------------------------------------------------------*)
(* REXX procedure to convert a string to upper case.                 *)
(* Usage: s = RxUpperCase( "abHmL7" )                                *)
(*        result is s = "ABHML7"                                     *)
(*-------------------------------------------------------------------*)
PROCEDURE RXUPPERCASE( VAR func : ARRAY OF CHAR;
                           argc : LONGCARD;
                          pargv : PRXSTRING;
                       VAR que  : ARRAY OF CHAR;
                       VAR ret  : RXSTRING) : LONGCARD;
VAR
  rc    : LONGCARD;
BEGIN
  rc := RXERROR;
  ret.strlen := 0;
  ret.strptr^ := 0C;

  IF argc = 1 THEN
    ret.strptr^ := pargv^.strptr^;
    Caps(ret.strptr^);
    ret.strlen := pargv^.strlen;
    rc := RXOK;
  END;

  RETURN rc;
END RXUPPERCASE;

(*$CDECL-*)

BEGIN
END MyRxDLL.
