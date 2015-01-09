IMPLEMENTATION MODULE OS2ARG;

(*************************************************************************
    32-bit-OS/2 utility for accessing the command line and environment.

    Copyright (c) 1994 by Juergen Neuhoff

    Note: Special thanks to Dave Serls
          (InterNet: serls@dashs.denver.co.us)
          for improving this implementation on Aug 11, 1995

**************************************************************************)


IMPORT SYSTEM;
FROM   Storage IMPORT ALLOCATE;
IMPORT Strings;

VAR
  Environment : PSTRING;
  Arguments   : PSTRING;
  ParsedArgs  : PSTRING;
  Argcount    : LONGCARD;

(* Copy command path and arguments to another area
   marking each token with binary 0
*)
PROCEDURE InitArgs();
TYPE PCHAR = POINTER TO CHAR;
VAR
  Arg   : PCHAR;
  Ostr,
  Wstr  : PSTRING;
  Psize,
  Tsize,
  Size  : LONGCARD;
BEGIN
  Arg := PCHAR(Arguments);
  Psize := Strings.Size( Arguments^ ) + 1;   (* command path length *)
  Arg := SYSTEM.ADR(Arg^) + Psize;           (* point to command tail *)
  Wstr := PSTRING(Arg);
  Size := Strings.Size( Wstr^ ) + 1;         (* command tail length *)
  Tsize := Size;  DEC(Size);                 (* don't count ending 0 *)
  ALLOCATE( Ostr, (Tsize + Psize));          (* output area *)
  SYSTEM.MemCpy( Ostr, Arguments, Psize );   (* includes ending 0 *)
  ParsedArgs := Ostr;
  Ostr := SYSTEM.ADR(Ostr^) + Psize;
  Argcount := 1;
  (* leading blank(s) of command tail may be preserved *)
  WHILE ( Size > 0 ) AND ( Arg^ = 20X ) DO
    Arg := SYSTEM.ADR(Arg^) + 1; DEC(Size)
  END;
  Tsize := Size;
  IF ( Size > 0 ) THEN
    WHILE ( Size > 0 ) DO
      IF Arg^ = 20X THEN
        Ostr^ := "";  INC(Argcount);
        WHILE ( Size > 0 ) AND ( Arg^ = 20X ) DO
          Arg := SYSTEM.ADR(Arg^) + 1; DEC(Size)
        END;
      ELSE
        Ostr^ := Arg^;
        Arg := SYSTEM.ADR(Arg^) + 1; DEC(Size)
      END;
      Ostr := SYSTEM.ADR(Ostr^) + 1;
    END; (* while size > 0 *)
  END;  (* end if whole size > 0 *)
  Ostr^ := "";
  IF Tsize > 0 THEN
    INC(Argcount)
  END;
END InitArgs;

PROCEDURE ArgCount() : LONGCARD;
BEGIN
  IF ParsedArgs = NIL THEN
    InitArgs()
  END;
  RETURN Argcount;
END ArgCount;

PROCEDURE Arg( Index : LONGCARD ) : PSTRING;
VAR
  Arg   : PSTRING;
  i     : LONGCARD;
  Size  : LONGCARD;
BEGIN
  IF ParsedArgs = NIL THEN
    InitArgs()
  END;
  i := 0;
  Arg := ParsedArgs;
  LOOP
    Size := Strings.Size( Arg^ );
    IF Size = 0 THEN
      RETURN NIL;
    END;
    IF i >= Index THEN
      RETURN Arg;
    END;
    i := i + 1;
    Arg := SYSTEM.ADR( Arg^ ) + Size + 1;
  END;
END Arg;

PROCEDURE EnvCount() : LONGCARD;
VAR
  Env   : PSTRING;
  Size  : LONGCARD;
  Count : LONGCARD;
BEGIN
  Count := 0;
  Env := Environment;
  Size := Strings.Size( Env^ );
  WHILE Size > 0 DO
    Count := Count + 1;
    Env := SYSTEM.ADR( Env^ ) + Size + 1;
    Size := Strings.Size( Env^ );
  END;
  RETURN Count;
END EnvCount;

PROCEDURE Env( Index : LONGCARD ) : PSTRING;
VAR
  Env   : PSTRING;
  i     : LONGCARD;
  Size  : LONGCARD;
BEGIN
  i := 0;
  Env := Environment;
  LOOP
    Size := Strings.Size( Env^ );
    IF Size = 0 THEN
      RETURN NIL;
    END;
    IF i >= Index THEN
      RETURN Env;
    END;
    i := i + 1;
    Env := SYSTEM.ADR( Env^ ) + Size + 1;
  END;
END Env;

BEGIN
  (*
     The initial stack layout under OS/2 2.x looks like this:
     EBP:     old EBP = 0
     EBP+4:   Return address to the routine that calls DosExecPgm
     EBP+8:   Module handle for the program module
     EBP+12:  0
     EBP+16:  Address of the environment data object
     EBP+20:  Offset to the command line in the environment data object
     This program uses the addresses at [EBP+16] and [EBP+20]
     for accessing the OS/2 environment and the command arguments.
  *)
  SYSTEM.INLINE
  (
    LEAVE
    XOR EAX,EAX
    MOV ParsedArgs, EAX
    MOV EAX, DWORD PTR [EBP+16]
    MOV Environment, EAX
    MOV EAX, DWORD PTR [EBP+20]
    MOV Arguments, EAX
    ENTER 0,0
  );
END OS2ARG.
