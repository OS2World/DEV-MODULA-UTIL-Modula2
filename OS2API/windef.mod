IMPLEMENTATION MODULE WINDEF;

(*************************************************************************
  OS/2 2.x/3.0 General Window Management type transfer/extract functions.

  Note: This set of procedures has been implemented for the sake
        of closer compatibility with IBM C header file PMWIN.H.
        They are almost obsolete for this compiler because of Modula's
        type transfer facility.

  Copyright (c) 1992, 1995 by Juergen Neuhoff
**************************************************************************)

(*$XL+       Modula-2 language extensions: '_' allowed for symbol names *)
(*$CDECL+    C-style procedures                                         *)
(*$A         default alignment for record fields                        *)

FROM   SYSTEM  IMPORT ADDRESS, BYTE, WORD, LONGWORD;
FROM   OS2DEF  IMPORT HWND, PCHAR, PSZ;


(*** function procedures to make an MPARAM from standard types. *********)

PROCEDURE MPFROMP( p:ADDRESS ):MPARAM;
BEGIN
  RETURN MPARAM( LONGCARD( p ) );
END MPFROMP;

PROCEDURE MPFROMHWND( WinHandle:HWND ):MPARAM;
BEGIN
  RETURN MPARAM( WinHandle );
END MPFROMHWND;

PROCEDURE MPFROMCHAR( ch:BYTE ):MPARAM;
BEGIN
  RETURN MPARAM( LONGCARD( SHORTCARD( ch ) ) );
END MPFROMCHAR;

PROCEDURE MPFROMSHORT( s:WORD ):MPARAM;
BEGIN
  RETURN MPARAM( LONGCARD( CARDINAL( s ) ) );
END MPFROMSHORT;

PROCEDURE MPFROM2SHORT( l,h:WORD ):MPARAM;
BEGIN
  RETURN MPARAM
  ( LONGCARD( CARDINAL( l ) ) + LONGCARD( CARDINAL( h ) ) SHL 16 );
END MPFROM2SHORT;

PROCEDURE MPFROMSH2CH( l:WORD; hl,hh:BYTE ):MPARAM;
BEGIN
  RETURN MPFROM2SHORT
  ( l, CARDINAL( SHORTCARD( hl ) ) + CARDINAL( SHORTCARD( hh ) ) SHL 8 );
END MPFROMSH2CH;

PROCEDURE MPFROMLONG( l:LONGWORD ):MPARAM;
BEGIN
  RETURN MPARAM( l );
END MPFROMLONG;


(*** function procedures to extract standard types from an MPARAM *******)

PROCEDURE PVOIDFROMMP( mp:MPARAM ):ADDRESS;
BEGIN
  RETURN ADDRESS( mp );
END PVOIDFROMMP;

PROCEDURE HWNDFROMMP( mp:MPARAM ):HWND;
BEGIN
  RETURN HWND( mp );
END HWNDFROMMP;

PROCEDURE CHAR1FROMMP( mp:MPARAM ):CHAR;
BEGIN
  RETURN CHAR( SHORTCARD( LONGCARD( mp ) ) );
END CHAR1FROMMP;

PROCEDURE CHAR2FROMMP( mp:MPARAM ):CHAR;
BEGIN
  RETURN CHAR( SHORTCARD( LONGCARD( mp ) SHR 8 ) );
END CHAR2FROMMP;

PROCEDURE CHAR3FROMMP( mp:MPARAM ):CHAR;
BEGIN
  RETURN CHAR( SHORTCARD( LONGCARD( mp ) SHR 16 ) );
END CHAR3FROMMP;

PROCEDURE CHAR4FROMMP( mp:MPARAM ):CHAR;
BEGIN
  RETURN CHAR( SHORTCARD( LONGCARD( mp ) SHR 24 ) );
END CHAR4FROMMP;

PROCEDURE SHORT1FROMMP( mp:MPARAM ):CARDINAL;
BEGIN
  RETURN CARDINAL( LONGCARD( mp ) );
END SHORT1FROMMP;

PROCEDURE SHORT2FROMMP( mp:MPARAM ):CARDINAL;
BEGIN
  RETURN CARDINAL( LONGCARD( mp ) SHR 16 );
END SHORT2FROMMP;

PROCEDURE LONGFROMMP( mp:MPARAM ):LONGCARD;
BEGIN
  RETURN LONGCARD( mp );
END LONGFROMMP;


(*** function procedures to make an MRESULT from standard types. ********)

PROCEDURE MRFROMP( p:ADDRESS ):MRESULT;
BEGIN
  RETURN MRESULT( p );
END MRFROMP;

PROCEDURE MRFROMSHORT( s:WORD ):MRESULT;
BEGIN
  RETURN MRESULT( LONGCARD( CARDINAL( s ) ) );
END MRFROMSHORT;

PROCEDURE MRFROM2SHORT( l,h:WORD ):MRESULT;
BEGIN
  RETURN MRESULT
  ( LONGCARD( CARDINAL( l ) ) + LONGCARD( CARDINAL( h ) ) SHL 16 );
END MRFROM2SHORT;

PROCEDURE MRFROMLONG( l:LONGWORD ):MRESULT;
BEGIN
  RETURN MRESULT( l );
END MRFROMLONG;


(*** function procedures to extract standard types from an MRESULT ******)

PROCEDURE PVOIDFROMMR( mr:MRESULT ):PVOID;
BEGIN
  RETURN PVOID( mr );
END PVOIDFROMMR;

PROCEDURE SHORT1FROMMR( mr:MRESULT  ):CARDINAL;
BEGIN
  RETURN SHORT( LONGCARD( mr ) );
END SHORT1FROMMR;

PROCEDURE SHORT2FROMMR( mr:MRESULT ):CARDINAL;
BEGIN
  RETURN SHORT( LONGCARD( mr ) SHR 16 );
END SHORT2FROMMR;

PROCEDURE LONGFROMMR( mr:MRESULT ):LONGCARD;
BEGIN
  RETURN LONGCARD( mr );
END LONGFROMMR;

PROCEDURE MAKEINTATOM( a:SYSTEM.LONGWORD ):PCHAR;
BEGIN
  RETURN PCHAR( LONGCARD( a ) OR 0FFFF0000H );
END MAKEINTATOM;

BEGIN
  MPVOID := MPARAM( 0 );
END WINDEF.
