IMPLEMENTATION MODULE SYSTEM;

(*************************************************************************
   Modula-2 SYSTEM runtime kernel for compiler version 2.01H

   Copyright (c) 1992-1995 by Juergen Neuhoff
**************************************************************************)

(*$XL+      Language extensions for this module *)

(*$IF OS2 *)
(*$IF Flat32Model *)
  FROM OS2DEF        IMPORT APIRET;
  FROM DOSPROCESS    IMPORT DosGetInfoBlocks,
                            DosExitList,
                            EXLST_ADD,
                            EXLST_EXIT,
                            DosExit,
                            EXIT_PROCESS,
                            DosEnterCritSec,
                            DosExitCritSec,
                            DosBeep;
  FROM DOSMODULEMGR  IMPORT DosLoadModule,
                            DosQueryProcAddr,
                            HMODULE;
  FROM DOSNLS        IMPORT DosMapCase,
                            COUNTRYCODE;
  FROM DOSMEMMGR     IMPORT DosAllocMem,
                            DosFreeMem,
                            DosSubSetMem,
                            DosSubUnsetMem,
                            DosSubFreeMem,
                            DosSubAllocMem,
                            OBJ_TILE,
                            fPERM,
                            PAG_COMMIT,
                            DOSSUB_INIT,
                            DOSSUB_SPARSE_OBJ,
                            DosGetNamedSharedMem,
                            DosAllocSharedMem;
  FROM DOSSEMAPHORES IMPORT HMTX,
                            DosCreateMutexSem,
                            DosRequestMutexSem,
                            DosReleaseMutexSem,
                            SEM_INDEFINITE_WAIT;
(*$ELSE *)
  FROM DOS16EXIT    IMPORT DosExit;
(*$ENDIF *)
(*$ENDIF *)

CONST
  SmallCode = TinyModel OR SmallModel OR CompactModel OR Flat32Model;
  SmallData = TinyModel OR SmallModel OR MediumModel OR Flat32Model;
  LargeCode = NOT SmallCode;
  LargeData = NOT SmallData;
  Data32    = (TSIZE( SHORTADDRESS ) = TSIZE( DWORD ));
  Data16    = (TSIZE( SHORTADDRESS ) = TSIZE( WORD ));
  FlatModel = TinyModel OR Flat32Model;
  Flat32OS2 = Flat32Model AND OS2;
  FPU       = NumericProcessor OR OS2;      (* FPU = original FPU flag *)

VAR
  ExitProc                  : PROC;         (* put it into SYSTEM.DEF *)
(*NumericProcessorInstalled : BOOLEAN;
*)NilProc                   : PROC;

(*$F-  No FPU needed inside SYSTEM, SYSTEM.NumericProcessor = FALSE *)


PROCEDURE OrBytes( Dest,Source1,Source2:ADDRESS; Size:LONGCARD );
BEGIN
  (* Dest := Source1 OR Source2  for non-overlapping operands *)
  WHILE Size > 0 DO
    Dest^ := SHORTCARD( Source1^ ) OR SHORTCARD( Source2^ );
    INC( Dest );
    INC( Source1 );
    INC( Source2 );
    DEC( Size );
  END;
END OrBytes;


PROCEDURE XorBytes( Dest,Source1,Source2:ADDRESS; Size:LONGCARD );
BEGIN
  (* Dest := Source1 XOR Source2  for non-overlapping operands *)
  WHILE Size > 0 DO
    Dest^ := SHORTCARD( Source1^ ) XOR SHORTCARD( Source2^ );
    INC( Dest );
    INC( Source1 );
    INC( Source2 );
    DEC( Size );
  END;
END XorBytes;


PROCEDURE AndBytes( Dest,Source1,Source2:ADDRESS; Size:LONGCARD );
BEGIN
  (* Dest := Source1 AND Source2  for non-overlapping operands *)
  WHILE Size > 0 DO
    Dest^ := SHORTCARD( Source1^ ) AND SHORTCARD( Source2^ );
    INC( Dest );
    INC( Source1 );
    INC( Source2 );
    DEC( Size );
  END;
END AndBytes;


PROCEDURE MemSet( Dest:ADDRESS; Val:WORD; Size:LONGCARD );
BEGIN
  (* Set multiple memory bytes to a given value *)
  INLINE
  (
    IF Data32
      PUSH ES
      PUSH EDI
      PUSH EAX
      PUSH ECX
      PUSHFD
      IF SmallData
        PUSH DS
        POP  ES
        MOV  EDI, Dest[ EBP ]
      ELSE
        LES  EDI, Dest[ EBP ]
      ENDIF
      MOV  AL, BYTE PTR Val[ EBP ]
      MOV  ECX, Size[ EBP ]
      CLD
      REP STOSB
      POPFD
      POP  ECX
      POP  EAX
      POP  EDI
      POP  ES
    ELSE
      PUSH ES
      PUSH DI
      PUSH AX
      PUSH CX
      PUSHF
      IF SmallData
        PUSH DS
        POP  ES
        MOV  DI, Dest[ BP ]
      ELSE
        LES  DI, Dest[ BP ]
      ENDIF
      MOV  AL, BYTE PTR Val[ BP ]
      MOV  CX, WORD PTR Size[ BP ]
      CLD
      REP STOSB
      POPF
      POP CX
      POP AX
      POP DI
      POP ES
    ENDIF
  );
END MemSet;


PROCEDURE MemCmp( Dest,Source: ADDRESS; Size:LONGCARD );
BEGIN
  (* compare two memory regions and set 80x86 flags register *)
  INLINE
  (
    PUSH ES
    IF LargeData
      PUSH DS
    ENDIF
    IF Data32
      PUSH ECX
      PUSH ESI
      PUSH EDI
      PUSH EAX
    ELSE
      PUSH CX
      PUSH SI
      PUSH DI
      PUSH AX
    ENDIF
    IF Data32
      MOV  ECX, DWORD PTR [EBP+Size]
    ELSE
      MOV  CX, WORD PTR [BP+Size]
    ENDIF
    IF LargeData AND Data32
      LDS  ESI, [EBP+Source]
      LES  EDI, [EBP+Dest]
    ENDIF
    IF LargeData AND Data16
      LDS  SI, [BP+Source]
      LES  DI, [BP+Dest]
    ENDIF
    IF SmallData AND Data32
      MOV  ESI, [EBP+Source]
      MOV  EDI, [EBP+Dest]
      PUSH DS
      POP  ES
    ENDIF
    IF SmallData AND Data16
      MOV  SI, [BP+Source]
      MOV  DI, [BP+Dest]
      PUSH DS
      POP  ES
    ENDIF
    CLD
    IF Data32
      CMP  ECX, ECX ; set default zero flag
    ELSE
      CMP  CX, CX   ; set default zero flag
    ENDIF
    REPE CMPSB
    IF Data32
      POP   EAX
      POP   EDI
      POP   ESI
      POP   ECX
    ELSE
      POP   AX
      POP   DI
      POP   SI
      POP   CX
    ENDIF
    IF LargeData
      POP  DS
    ENDIF
    POP  ES
  );
END MemCmp;


PROCEDURE MemCpy( Dest,Source: ADDRESS; Size:LONGCARD );
BEGIN
  (* copy muliple bytes from one memory region to another. *)
  INLINE
  (
    PUSH ES
    IF LargeData
      PUSH DS
    ENDIF
    IF Data32
      PUSH ECX
      PUSH ESI
      PUSH EDI
      IF LargeData
        PUSH EAX
        PUSH EBX
      ENDIF
      PUSHFD
    ELSE
      PUSH CX
      PUSH SI
      PUSH DI
      IF LargeData
        PUSH AX
        PUSH BX
      ENDIF
      PUSHF
    ENDIF
    CLD
    IF Data32
      MOV  ECX, DWORD PTR [EBP+Size]
    ELSE
      MOV  CX, WORD PTR [BP+Size]
    ENDIF
    IF LargeData AND Data32
      LDS  ESI, [EBP+Source]
      LES  EDI, [EBP+Dest]
    ENDIF
    IF LargeData AND Data16
      LDS  SI, [BP+Source]
      LES  DI, [BP+Dest]
    ENDIF
    IF SmallData AND Data32
      MOV  ESI, [EBP+Source]
      MOV  EDI, [EBP+Dest]
      PUSH DS
      POP  ES
    ENDIF
    IF SmallData AND Data16
      MOV  SI, [BP+Source]
      MOV  DI, [BP+Dest]
      PUSH DS
      POP  ES
    ENDIF
    IF LargeData
      MOV  AX, DS
      MOV  BX, ES
      CMP  AX, BX
      JNE  next               ; Jump on if non overlapping segments
    ENDIF
    IF Data32
      CMP  ESI, EDI
    ELSE
      CMP  SI, DI
    ENDIF
    JAE  next                 ; Jump on if source offset > dest offset
    IF Data32
      STD                     ; Prefer backward move, memory might overlap
      ADD  ESI, ECX
      ADD  EDI, ECX
      DEC  ESI
      DEC  EDI
    ELSE
      STD                     ; Prefer backward move, memory might overlap
      ADD  SI, CX
      ADD  DI, CX
      DEC  SI
      DEC  DI
    ENDIF
    next: REP MOVSB           ; now perform memory move
    IF Data32
      POPFD
      IF LargeData
        POP   EBX
        POP   EAX
      ENDIF
      POP   EDI
      POP   ESI
      POP   ECX
    ELSE
      POPF
      IF LargeData
        POP   BX
        POP   AX
      ENDIF
      POP   DI
      POP   SI
      POP   CX
    ENDIF
    IF LargeData
      POP  DS
    ENDIF
    POP  ES
  );
END MemCpy;


PROCEDURE SetBitRange( Dest:ADDRESS; FromBit,ToBit,MaxBit:LONGCARD );
CONST
  MaxSetSize =  32;
VAR
  FromByte : CARDINAL;
  ToByte   : CARDINAL;
  StartVal : SHORTCARD;
  EndVal   : SHORTCARD;
  SetDest  : POINTER TO ARRAY [0..MaxSetSize-1] OF SHORTCARD;
BEGIN
  INLINE
  (
    IF Data32
      PUSH EAX
      PUSHFD
    ELSE
      PUSH AX
      PUSHF
    ENDIF
  );
  IF ((FromBit <= ToBit) AND (FromBit <= MaxBit)) THEN
    IF ToBit > MaxBit THEN
      ToBit := MaxBit;
    END;
    FromByte := SHORTCARD( FromBit ) DIV 8;
    ToByte := SHORTCARD( ToBit ) DIV 8;
    StartVal := 0FFH SHL (SHORTCARD( FromBit ) MOD 8);
    EndVal := 0FFH SHR (7 - (SHORTCARD( ToBit ) MOD 8));
    SetDest := Dest;
    IF FromByte = ToByte THEN
      SetDest^[ FromByte ] := SetDest^[ FromByte ] OR (StartVal AND EndVal);
    ELSE
      SetDest^[ FromByte ] := SetDest^[ FromByte ] OR StartVal;
      SetDest^[ ToByte ] := SetDest^[ ToByte ] OR EndVal;
      MemSet( ADR( SetDest^[ FromByte+1 ] ), 255, ToByte-FromByte-1 );
    END;
  END;
  INLINE
  (
    IF Data32
      POPFD
      POP EAX
    ELSE
      POPF
      POP AX
    ENDIF
  );
END SetBitRange;


PROCEDURE DelBitRange( Dest:ADDRESS; FromBit,ToBit,MaxBit:LONGCARD );
CONST
  MaxSetSize =  32;
VAR
  FromByte : CARDINAL;
  ToByte   : CARDINAL;
  StartVal : SHORTCARD;
  EndVal   : SHORTCARD;
  SetDest  : POINTER TO ARRAY [0..MaxSetSize-1] OF SHORTCARD;
BEGIN
  INLINE
  (
    IF Data32
      PUSH EAX
      PUSHFD
    ELSE
      PUSH AX
      PUSHF
    ENDIF
  );
  IF ((FromBit <= ToBit) AND (FromBit <= MaxBit)) THEN
    IF ToBit > MaxBit THEN
      ToBit := MaxBit;
    END;
    FromByte := SHORTCARD( FromBit ) DIV 8;
    ToByte := SHORTCARD( ToBit ) DIV 8;
    StartVal := 0FFH SHR (8 - (SHORTCARD( FromBit ) MOD 8));
    EndVal := 0FFH SHL (1 + (SHORTCARD( ToBit ) MOD 8));
    SetDest := Dest;
    IF FromByte = ToByte THEN
      SetDest^[ FromByte ] := SetDest^[ FromByte ] AND (StartVal OR EndVal);
    ELSE
      SetDest^[ FromByte ] := SetDest^[ FromByte ] AND StartVal;
      SetDest^[ ToByte ] := SetDest^[ ToByte ] AND EndVal;
      MemSet( ADR( SetDest^[ FromByte+1 ] ), 0, ToByte-FromByte-1 );
    END;
  END;
  INLINE
  (
    IF Data32
      POPFD
      POP EAX
    ELSE
      POPF
      POP AX
    ENDIF
  );
END DelBitRange;


PROCEDURE TestBit( Set:ADDRESS; BitPos:LONGCARD; BitMax:LONGCARD ):BOOLEAN;
BEGIN
  (* Test a bit of a bitset; Return TRUE if set else return FALSE *)
  IF BitPos > BitMax THEN
    RETURN FALSE;
  END;
  (*$IF Data16*)
    INC( Set, SHORT( BitPos ) SHR 3 );
  (*$ELSE*)
    INC( Set, BitPos SHR 3 );
  (*$ENDIF*)
  RETURN (SHORTCARD( Set^ ) AND (1 SHL (SHORTCARD( BitPos ) AND 7))) > 0;
END TestBit;


PROCEDURE Push( Param:ADDRESS; Size:LONGCARD );
BEGIN
  (* Runtime function for copying a large parameter to the stack *)
  INLINE
  (
    IF Flat32Model
      MOV  ESP, EBP
      SUB  ESP, [EBP+Size]           ;reserve stack space for parameter
      AND  ESP, 0FFFFFFFCH           ;down align to DWORD boundary
      PUSH EAX
      MOV  EAX, DWORD PTR [EBP]
      MOV  DWORD PTR [ESP+4], EAX
      MOV  EAX, DWORD PTR [EBP+4]
      MOV  DWORD PTR [ESP+4+4], EAX
      MOV  EAX, DWORD PTR [EBP+Size]
      MOV  DWORD PTR [ESP+4+Size], EAX
      MOV  EAX, DWORD PTR [EBP+Param]
      MOV  DWORD PTR [ESP+4+Param], EAX
      LEA  EAX, DWORD PTR [ESP+4+Param+4]
      PUSH EAX                             ; push Dest = allocated stack space
      PUSH DWORD PTR [ESP+14H]             ; push Source = Param
      PUSH DWORD PTR [ESP+14H]             ; push Size
      CALL MemCpy
      POP  EAX
      MOV  EBP, ESP
    ELSE
      MOV  SP, BP
      SUB  SP, WORD PTR [BP+Size]    ;reserve stack space for parameter
      AND  SP, 0FFFEH                ;down align to WORD boundary
      PUSH AX
      PUSH BX
      MOV  BX, SP
      MOV  AX, WORD PTR [BP]
      MOV  WORD PTR SS:[BX+4], AX
      MOV  AX, WORD PTR [BP+2]
      MOV  WORD PTR SS:[BX+4+2], AX
      IF LargeCode
        MOV  AX, WORD PTR [BP+4]
        MOV  WORD PTR SS:[BX+4+4], AX
      ENDIF
      MOV  AX, WORD PTR [BP+Size]
      MOV  WORD PTR SS:[BX+4+Size], AX
      MOV  AX, WORD PTR [BP+Size+2]
      MOV  WORD PTR SS:[BX+4+Size+2], AX
      MOV  AX, WORD PTR [BP+Param]
      MOV  WORD PTR SS:[BX+4+Param], AX
      IF LargeData
        MOV  AX, WORD PTR [BP+Param+2]
        MOV  WORD PTR SS:[BX+4+Param+2], AX
      ENDIF
      IF LargeData
        PUSH SS
        LEA  AX, SS:[BX+4+Param+4]
      ELSE
        LEA  AX, SS:[BX+4+Param+2]
      ENDIF
      PUSH AX
      IF LargeData
        PUSH WORD PTR SS:[BX+4+Param+2]
      ENDIF
      PUSH WORD PTR SS:[BX+4+Param]
      PUSH WORD PTR SS:[BX+4+Size+2]
      PUSH WORD PTR SS:[BX+4+Size]
      CALL MemCpy
      POP  BX
      POP  AX
      MOV  BP, SP
    ENDIF
  );
END Push;


PROCEDURE PushString( Str:ADDRESS; StrSize:LONGCARD; Size:LONGCARD );
BEGIN
  (* Runtime function for copying a string parameter to the stack *)
  (*   'StrSize' is the size of the formal parameter              *)
  (*   'Size' (which is <= 'StrSize') is the actual string size   *)
  INLINE
  (
    IF Flat32Model
      MOV  ESP, EBP
      SUB  ESP, [EBP+StrSize]        ;reserve stack space for parameter
      AND  ESP, 0FFFFFFFCH           ;down align to DWORD boundary
      PUSH EAX
      MOV  EAX, DWORD PTR [EBP]
      MOV  DWORD PTR [ESP+4], EAX
      MOV  EAX, DWORD PTR [EBP+4]
      MOV  DWORD PTR [ESP+4+4], EAX
      MOV  EAX, DWORD PTR [EBP+Size]
      MOV  DWORD PTR [ESP+4+Size], EAX
      MOV  EAX, DWORD PTR [EBP+StrSize]
      MOV  DWORD PTR [ESP+4+StrSize], EAX
      MOV  EAX, DWORD PTR [EBP+Str]
      MOV  DWORD PTR [ESP+4+Str], EAX
      LEA  EAX, DWORD PTR [ESP+4+Str+4]
      PUSH EAX
      PUSH DWORD PTR [ESP+8+Str]
      PUSH DWORD PTR [ESP+12+Size]
      CALL MemCpy
      MOV  EAX, DWORD PTR [ESP+4+Size]
      CMP  EAX, DWORD PTR [ESP+4+StrSize]
      JAE  next
      MOV  BYTE PTR [ESP+4+Str+4+EAX], 0   ;mov zero after stack string
      next:
      POP  EAX
      MOV  EBP, ESP
    ELSE
      MOV  SP, BP
      SUB  SP, WORD PTR [BP+StrSize] ;reserve stack space for parameter
      AND  SP, 0FFFEH                ;down align to WORD boundary
      PUSH AX
      PUSH BX
      MOV  BX, SP
      MOV  AX, WORD PTR [BP]
      MOV  WORD PTR SS:[BX+4], AX
      MOV  AX, WORD PTR [BP+2]
      MOV  WORD PTR SS:[BX+4+2], AX
      IF LargeCode
        MOV  AX, WORD PTR [BP+4]
        MOV  WORD PTR SS:[BX+4+4], AX
      ENDIF
      MOV  AX, WORD PTR [BP+Size]
      MOV  WORD PTR SS:[BX+4+Size], AX
      MOV  AX, WORD PTR [BP+Size+2]
      MOV  WORD PTR SS:[BX+4+Size+2], AX
      MOV  AX, WORD PTR [BP+StrSize]
      MOV  WORD PTR SS:[BX+4+StrSize], AX
      MOV  AX, WORD PTR [BP+StrSize+2]
      MOV  WORD PTR SS:[BX+4+StrSize+2], AX
      MOV  AX, WORD PTR [BP+Str]
      MOV  WORD PTR SS:[BX+4+Str], AX
      IF LargeData
        MOV  AX, WORD PTR [BP+Str+2]
        MOV  WORD PTR SS:[BX+4+Str+2], AX
      ENDIF
      IF LargeData
        PUSH SS
        LEA  AX, SS:[BX+4+Str+4]
      ELSE
        LEA  AX, SS:[BX+4+Str+2]
      ENDIF
      PUSH AX
      IF LargeData
        PUSH WORD PTR SS:[BX+4+Str+2]
      ENDIF
      PUSH WORD PTR SS:[BX+4+Str]
      PUSH WORD PTR SS:[BX+4+Size+2]
      PUSH WORD PTR SS:[BX+4+Size]
      CALL MemCpy
      MOV  AX, WORD PTR SS:[BX+4+Size]
      CMP  AX, WORD PTR SS:[BX+4+StrSize]
      JAE  next
      ADD  BX, AX
      IF LargeData
        MOV  BYTE PTR SS:[BX+4+Str+4], 0 ;mov zero after stack string
      ELSE
        MOV  BYTE PTR SS:[BX+4+Str+2], 0 ;mov zero after stack string
      ENDIF
      next:
      POP  BX
      POP  AX
      MOV  BP, SP
    ENDIF
  );
END PushString;


PROCEDURE LocalCopy( VAR Source:ADDRESS; Size:LONGCARD );
BEGIN
  (* Get stack space for a local copy of an open array *)
  INLINE
  (
    IF Flat32Model
      MOV  ESP, EBP
      SUB  ESP, [EBP+Size]        ;reserve stack space for parameter
      AND  ESP, 0FFFFFFFCH        ;down align to DWORD boundary
      PUSH EAX
      MOV  EAX, DWORD PTR [EBP]
      MOV  DWORD PTR [ESP+4], EAX
      MOV  EAX, DWORD PTR [EBP+4]
      MOV  DWORD PTR [ESP+4+4], EAX
      MOV  EAX, DWORD PTR [EBP+Size]
      MOV  DWORD PTR [ESP+4+Size], EAX
      MOV  EAX, DWORD PTR [EBP+Source]
      MOV  DWORD PTR [ESP+4+Source], EAX
      LEA  EAX, DWORD PTR [ESP+4+Source+4]
      PUSH EAX
      MOV  EAX, DWORD PTR [ESP+8+Source]
      PUSH DWORD PTR SS:[EAX]
      PUSH DWORD PTR [ESP+12+Size]
      CALL MemCpy
      PUSH EBX
      LEA  EAX, DWORD PTR [ESP+8+Source+4]
      MOV  EBX, DWORD PTR [ESP+8+Source]
      MOV  DWORD PTR [EBX], EAX
      POP  EBX
      POP  EAX
      MOV  EBP, ESP
    ELSE
      MOV  SP, BP
      SUB  SP, WORD PTR [BP+Size] ;reserve stack space for parameter
      AND  SP, 0FFFEH             ;down align to WORD boundary
      PUSH AX
      PUSH BX
      PUSH DI
      MOV  BX, SP
      MOV  AX, WORD PTR [BP]
      MOV  WORD PTR SS:[BX+6], AX
      MOV  AX, WORD PTR [BP+2]
      MOV  WORD PTR SS:[BX+6+2], AX
      IF LargeCode
        MOV  AX, WORD PTR [BP+4]
        MOV  WORD PTR SS:[BX+6+4], AX
      ENDIF
      MOV  AX, WORD PTR [BP+Size]
      MOV  WORD PTR SS:[BX+6+Size], AX
      MOV  AX, WORD PTR [BP+Size+2]
      MOV  WORD PTR SS:[BX+6+Size+2], AX
      MOV  AX, WORD PTR [BP+Source]
      MOV  WORD PTR SS:[BX+6+Source], AX
      IF LargeData
        MOV  AX, WORD PTR [BP+Source+2]
        MOV  WORD PTR SS:[BX+6+Source+2], AX
      ENDIF
      IF LargeData
        LEA  AX, SS:[BX+6+Source+4]
        PUSH ES  ; save it
        PUSH SS
        PUSH AX
      ELSE
        LEA  AX, SS:[BX+6+Source+2]
        PUSH AX
      ENDIF
      IF LargeData
        LES  DI, DWORD PTR SS:[BX+6+Source]
        PUSH WORD PTR ES:[DI+2]
        PUSH WORD PTR ES:[DI]
      ELSE
        MOV  DI, WORD PTR SS:[BX+6+Source]
        PUSH WORD PTR [DI]
      ENDIF
      PUSH WORD PTR SS:[BX+6+Size+2]
      PUSH WORD PTR SS:[BX+6+Size]
      CALL MemCpy
      IF LargeData
        MOV WORD PTR ES:[DI+2], SS
        LEA AX, WORD PTR SS:[BX+6+Source+4]
        MOV WORD PTR ES:[DI], AX
        POP ES
      ELSE
        LEA AX, WORD PTR SS:[BX+6+Source+2]
        MOV WORD PTR [DI], AX
      ENDIF
      POP DI
      POP BX
      POP AX
      MOV BP, SP
    ENDIF
  );
END LocalCopy;


PROCEDURE LocalFree( VAR Source:ADDRESS );
BEGIN
  (* Free up stack space from a local copy of an open array *)
  (* not needed for this compiler version *)
END LocalFree;


PROCEDURE GetExitProc() : PROC;
BEGIN
  RETURN ExitProc;
END GetExitProc;


PROCEDURE SetExitProc( UserProc : PROC );
BEGIN
  ExitProc := UserProc;
END SetExitProc;


PROCEDURE ExitProgram( ExitCode:SHORTCARD );
VAR
  SavedExitProc : PROC;
BEGIN
  (* ExitCode=3 means a type guard failure *)
  SavedExitProc := NilProc;
  LOOP
    IF ExitProc = SavedExitProc THEN
      EXIT;
    END;
    IF ExitProc = NilProc THEN
      EXIT;
    END;
    SavedExitProc := ExitProc;
    ExitProc();
  END;
  INLINE
  (
    IF OS2
      IF Flat32Model
        (* EAX = return code *)
        XOR EAX, EAX
        MOV AL, [ExitCode+EBP]
        PUSH EAX
        PUSH EXIT_PROCESS
        CALL DosExit
      ELSE
        (* AX = return code *)
        XOR  AX, AX
        MOV  AL, [ExitCode+BP]
        PUSH 1
        PUSH AX
        CALL DosExit
      ENDIF
    ELSE
      MOV AH, 4CH
      IF Data32
        MOV AL, [ExitCode+EBP]
      ELSE
        MOV AL, [ExitCode+BP]
      ENDIF
      INT 21H
    ENDIF
  );
END ExitProgram;


PROCEDURE HALT();
BEGIN
  ExitProgram( 0 );
END HALT;


PROCEDURE CAP( ch:CHAR ):CHAR;
CONST
  UseCountryCode = OS2 AND Flat32Model;
VAR
  (*$IF UseCountryCode *)
    CountryCode : COUNTRYCODE;
    rc          : APIRET;
  (*$ENDIF *)
BEGIN
  (*$IF UseCountryCode *)
    CountryCode.Country := 0;
    CountryCode.CodePage := 0;
    rc := DosMapCase( 1, CountryCode, ch );
  (*$ELSE*)
    CASE ch OF
    | '„':      ch := 'Ž';
    | '”':      ch := '™';
    | '':      ch := 'š';
    | 'a'..'z': ch := CHR( ORD(ch) - (ORD('a') - ORD('A')) );
    END;
  (*$ENDIF*)
  RETURN ch;
END CAP;


PROCEDURE IOTRANSFER( VAR p1,p2:ADDRESS; va:CARDINAL );
BEGIN
END IOTRANSFER;


PROCEDURE LISTEN();
BEGIN
END LISTEN;


PROCEDURE NEWPROCESS( p:PROC; a:ADDRESS; n:CARDINAL; VAR p1:ADDRESS );
TYPE
  ProcessTyp      = RECORD
    StackFrame      : SHORTADDRESS;
    Instr           : PROC;
    reserved        : ARRAY [0..1] OF ADDRESS;
                    END;
VAR
  CoRoutine  : POINTER TO ProcessTyp;
  StackFrame : SHORTADDRESS;
BEGIN
  (* store a PROCESS descriptor at the high end of work space 'a'
     and assign its address to process variable 'p1'
  *)
  INLINE
  (
    IF Flat32Model
      MOV EAX, DWORD PTR [EBP]
      MOV [EBP+StackFrame], EAX
    ELSE
      MOV AX, WORD PTR [BP]
      MOV [BP+StackFrame], AX
    ENDIF
  );
  CoRoutine := a + n - TSIZE( ProcessTyp );
  CoRoutine^.StackFrame := StackFrame;
  CoRoutine^.Instr := p;
  p1 := CoRoutine;
END NEWPROCESS;


PROCEDURE TRANSFER( VAR p1,p2:ADDRESS );
CONST
  AddressSize = TSIZE( ADDRESS );
BEGIN
  INLINE
  (
    IF Flat32Model
      ;p1 := this top-of-stack with caller's EBP and EIP
      MOV  ESP, EBP
      MOV  EAX, DWORD [EBP+p1]
      MOV  DWORD [EAX], EBP
      ;transfer to new process
      MOV  EAX, DWORD [EBP+p2]
      MOV  ESP, DWORD [EAX]
      POP  EBP
      RETN AddressSize*2
    ENDIF

    IF SmallModel OR TinyModel OR MediumModel
      ;p1 := this top-of-stack with caller's BP and instr pointer
      MOV  SP, BP
      PUSH BX
      MOV  BX, WORD [BP+p1]
      MOV  WORD [BX], BP
      POP  BX
      ;transfer to new process
      MOV  BP, WORD [BP+p2]
      MOV  SP, WORD [BP]
      POP  BP
      IF MediumModel
        RETF AddressSize*2
      ELSE
        RETN AddressSize*2
      ENDIF
    ENDIF

    IF CompactModel OR LargeModel
      ;p1 := this top-of-stack with caller's BP and instr pointer
      MOV  SP, BP
      PUSH ES
      PUSH BX
      LES  BX, DWORD [BP+p1]
      MOV  WORD ES:[BX], BP
      MOV  WORD ES:[BX+2], SS
      POP  BX
      POP  AX
      ;transfer to new process
      LES  BP, DWORD [BP+p2]  ; ES:BP = &p2
      IF Processor GE 80386
        LSS  SP, DWORD ES:[BP]  ; SS:SP = p2
      ELSE
        MOV  SS, WORD ES:[BP+2]
        MOV  SP, WORD ES:[BP]   ; SS:SP = p2
      ENDIF
      MOV  ES, AX
      POP  BP
      IF CompactModel
        RETN AddressSize*2
      ELSE
        RETF AddressSize*2
      ENDIF
    ENDIF
  );
END TRANSFER;


PROCEDURE LongMul( i,j:LONGCARD ):LONGCARD;
BEGIN
  (* Runtime function for long multiply:       *)
  (*   for 16-bit-code: DX:AX = DX:AX * CX:AX  *)
  (*   for 32-bit-code: ... not needed ...     *)
  INLINE
  (
    IF Flat32Model
      PUSH EDX
      MOV  EAX, [EBP+i]
      MUL  [EBP+j]
      POP  EDX
    ELSE
      PUSH CX
      PUSH BX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j+2]
      MOV  BX, WORD PTR [BP+j]
      PUSH SI
      MOV  SI,DX     ;SI = d
      XCHG AX,CX     ;AX = c, CX = a
      OR   AX, AX
      JZ   M1
      MUL  CX        ;AX = acl
      M1:
      XCHG AX,SI     ;SI = acl, AX = d
      OR   AX, AX
      JZ   M2
      MUL  BX        ;AX = bdl
      ADD  SI,AX     ;SI = acl + bdl
      M2:
      MOV  AX,CX     ;AX = a
      MUL  BX        ;AX = abl, DX = abh
      ADD  DX,SI     ;AX = abl, DX = abh + acl + bdl
      POP  SI
      POP  BX
      POP  CX
    ENDIF
  );
END LongMul;


PROCEDURE LongIMul( i,j:LONGINT ):LONGINT;
BEGIN
  (* Runtime function for long signed multiply *)
  (*   for 16-bit-code: DX:AX = DX:AX * CX:AX  *)
  (*   for 32-bit-code: ... not needed ...     *)
  INLINE
  (
    IF Flat32Model
      PUSH EDX
      MOV  EAX, [EBP+i]
      MUL  [EBP+j]
      POP  EDX
    ELSE
      MOV SP, BP
      JMP LongMul
    ENDIF
  );
END LongIMul;


PROCEDURE Div16();
BEGIN
  (* Auxiliary runtime function for 16-bit-code unsigned divide:  *)
  (*   DX:AX / CX:BX  -->  DX:AX (result)   CX:BX (remainder)     *)
  INLINE
  (
    IF NOT Flat32Model
      PUSH DI
      PUSH SI
      JCXZ uldiv

      ;left justify [CX,BX] and leave count of shifts + 1 in BP
      PUSH BP
      MOV  BP,1     ;at least 1 shift
      OR   CH, CH   ;left justified?
      JS   L1       ;yes
      JNZ  L2
      ADD  BP,8
      MOV  CH,CL
      MOV  CL,BH
      MOV  BH,BL
      XOR  BL,BL    ;[CX,BX] <<= 8
      OR   CH, CH
      JS   L1

      L2:
      INC  BP       ;another shift
      SHL  BX,1
      RCL  CX,1     ;[CX,BX] <<= 1
      JNO  L2       ;not left justified yet

      L1:
      MOV  SI,CX
      MOV  DI,BX    ;[SI,DI] = divisor
      MOV  CX,DX
      MOV  BX,AX    ;[CX,BX] = [DX,AX]
      XOR  AX,AX
      CWD           ;[DX,AX] = 0

      L4:
      CMP  SI, CX
      JA   L3       ;if [CX,BX] > [SI,DI] goto L3
      JB   L5       ;definitely less than
      CMP  DI, BX   ;check low order word
      JA   L3

      L5:
      SUB  BX,DI
      SBB  CX,SI    ;[CX,BX] -= [SI,DI]
      STC           ;rotate in a 1

      L3:
      RCL  AX,1
      RCL  DX,1     ;[DX,AX] = ([DX,AX] << 1) + C
      SHR  SI,1
      RCR  DI,1     ;[SI,DI] >>= 1
      DEC  BP       ;control count
      JNE  L4

      uldiv:
      OR   DX, DX
      JNZ  D3
      DIV  BX       ;High words are 0, we can use the DIV instruction
      MOV  BX,DX
      MOV  DX,CX    ;DX = CX = 0
      JMP  Exit

      D3:           ;Divide [DX,AX] by BX
      MOV  CX,AX
      MOV  AX,DX
      XOR  DX,DX
      DIV  BX
      XCHG CX,AX
      DIV  BX       ;CX,AX = result  DX = remainder
      MOV  BX,DX
      MOV  DX,CX
      XOR  CX,CX
      JMP  Exit

      Exit:
      POP  SI
      POP  DI
    ENDIF
  );
END Div16;


PROCEDURE LongDiv( i,j:LONGCARD ):LONGCARD;
BEGIN
  (* Runtime function for long unsigned divide:  *)
  (*   for 16-bit-code: DX:AX = DX:AX / CX:BX    *)
  (*   for 32-bit-code: ... not needed ...       *)
  INLINE
  (
    IF Flat32Model
      PUSH EDX
      XOR  EDX, EDX
      MOV  EAX, [EBP+i]
      DIV  [EBP+j]
      POP  EDX
    ELSE
      PUSH CX
      PUSH BX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j+2]
      MOV  BX, WORD PTR [BP+j]
      CALL Div16
      POP  BX
      POP  CX
    ENDIF
  );
END LongDiv;


PROCEDURE LongMod( i,j:LONGCARD ):LONGCARD;
BEGIN
  (* Runtime function for long unsigned modulus: *)
  (*   for 16-bit-code: DX:AX = DX:AX / CX:BX    *)
  (*   for 32-bit-code: ... not needed ...       *)
  INLINE
  (
    IF Flat32Model
      PUSH EDX
      XOR  EDX, EDX
      MOV  EAX, [EBP+i]
      DIV  [EBP+j]
      MOV  EAX, EDX
      POP  EDX
    ELSE
      PUSH CX
      PUSH BX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j+2]
      MOV  BX, WORD PTR [BP+j]
      CALL Div16
      MOV  DX, CX
      MOV  AX, BX
      POP  BX
      POP  CX
    ENDIF
  );
END LongMod;


PROCEDURE IDiv16();
BEGIN
  (* Auxiliary runtime function for 16-bit-code signed divide:    *)
  (*   DX:AX / CX:BX  -->  DX:AX (result)   CX:BX (remainder)     *)
  INLINE
  (
    IF NOT Flat32Model
      OR   DX,DX      ;divident negative?
      JNS  L10        ;no
      NEG  DX
      NEG  AX
      SBB  DX,0       ;divident = -divident
      OR   CX,CX      ;divisor negative?
      JNS  L11        ;no
      NEG  CX
      NEG  BX
      SBB  CX,0       ;divisor = -divisor
      CALL Div16      ;divident and divisor were negative
      NEG  CX
      NEG  BX
      SBB  CX,0       ;[CX,BX] = -[CX,BX], remainder same sign as dividend
      JMP  Exit

      L10:
      OR   CX,CX      ;divisor negative?
      JNS  L12        ;no (all is positive)
      NEG  CX
      NEG  BX
      SBB  CX,0       ;divisor = -divisor
      CALL Div16
      NEG  DX
      NEG  AX
      SBB  DX,0       ;quotient [DX,AX] is negative
      JMP  Exit

      L11:
      CALL Div16
      NEG  CX
      NEG  BX
      SBB  CX,0       ;remainder [CX,BX] same sign as divident
      NEG  DX
      NEG  AX
      SBB  DX,0       ;quotient [DX,AX] is neagtive
      JMP  Exit

      L12:            ;divident and divisor were positive
      CALL Div16
      JMP  Exit

      Exit:
    ENDIF
  );
END IDiv16;


PROCEDURE LongIDiv( i,j:LONGINT ):LONGINT;
BEGIN
  (* Runtime function for long signed divide:    *)
  (*   for 16-bit-code: DX:AX = DX:AX / CX:BX    *)
  (*   for 32-bit-code: ... not needed ...       *)
  INLINE
  (
    IF Flat32Model
      PUSH EDX
      MOV  EAX, [EBP+i]
      CDQ
      IDIV [EBP+j]
      POP  EDX
    ELSE
      PUSH CX
      PUSH BX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j+2]
      MOV  BX, WORD PTR [BP+j]
      CALL IDiv16
      POP  BX
      POP  CX
    ENDIF
  );
END LongIDiv;


PROCEDURE LongIMod( i,j:LONGINT ):LONGINT;
BEGIN
  (* Runtime function for long signed divide:    *)
  (*   for 16-bit-code: DX:AX = DX:AX / CX:BX    *)
  (*   for 32-bit-code: ... not needed ...       *)
  INLINE
  (
    IF Flat32Model
      PUSH EDX
      MOV  EAX, [EBP+i]
      CDQ
      IDIV [EBP+j]
      MOV  EAX, EDX
      POP  EDX
    ELSE
      PUSH CX
      PUSH BX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j+2]
      MOV  BX, WORD PTR [BP+j]
      CALL IDiv16
      MOV  DX, CX
      MOV  AX, BX
      POP  BX
      POP  CX
    ENDIF
  );
END LongIMod;


PROCEDURE LongShl( i,j:LONGCARD ):LONGCARD;
BEGIN
  (* Runtime function for long shift left (only needed for 16-bit-code) *)
  INLINE
  (
    IF Flat32Model
      PUSH ECX
      MOV  EAX, [EBP+i]
      MOV  CL, BYTE PTR [EBP+j]
      SHL  EAX, CL
      POP  ECX
    ELSE
      PUSH CX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j]
      XOR  CH, CH
      JCXZ Exit
      next:
      SHL  AX,1
      RCL  DX,1
      LOOP next
      Exit:
      POP  CX
    ENDIF
  );
END LongShl;


PROCEDURE LongShr( i,j:LONGCARD ):LONGCARD;
BEGIN
  (* Runtime function for long shift right (only needed for 16-bit-code) *)
  INLINE
  (
    IF Flat32Model
      PUSH ECX
      MOV  EAX, [EBP+i]
      MOV  CL, BYTE PTR [EBP+j]
      SHL  EAX, CL
      POP  ECX
    ELSE
      PUSH CX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j]
      XOR  CH, CH
      JCXZ Exit
      next:
      SHR  AX,1
      RCR  DX,1
      LOOP next
      Exit:
      POP  CX
    ENDIF
  );
END LongShr;


PROCEDURE LongSar( i,j:LONGINT ):LONGINT;
BEGIN
  (* Runtime function for signed long shift right (needed for 16-bit-code) *)
  INLINE
  (
    IF Flat32Model
      PUSH ECX
      MOV  EAX, [EBP+i]
      MOV  CL, BYTE PTR [EBP+j]
      SHL  EAX, CL
      POP  ECX
    ELSE
      PUSH CX
      MOV  DX, WORD PTR [BP+i+2]
      MOV  AX, WORD PTR [BP+i]
      MOV  CX, WORD PTR [BP+j]
      XOR  CH, CH
      JCXZ Exit
      next:
      SAR  AX,1
      RCR  DX,1
      LOOP next
      Exit:
      POP  CX
    ENDIF
  );
END LongSar;



TYPE
(*$IF FlatModel*)
  DescriptorADDRESS = SHORTADDRESS;
  PTYPEINFO         = NEAR POINTER TO TYPEINFO;
(*$ELSE*)
  DescriptorADDRESS = LONGADDRESS;
  PTYPEINFO         = FAR POINTER TO TYPEINFO;
(*$ENDIF*)
  TYPEINFO          = RECORD (* dynamic record type runtime descriptor *)
    Parent            : DescriptorADDRESS;
    VMT               : DescriptorADDRESS;
                      END;



PROCEDURE TypeGuard( Wanted : DescriptorADDRESS; Actual : DescriptorADDRESS );
CONST
  RetSize = TSIZE( DescriptorADDRESS )*2;
BEGIN
  (* This function gets 2 pointers to the actual and wanted type descriptors,
     representing the actual and wanted dynamic record types.
     If the pointer to the wanted type descriptor is equal to the
     pointer of the actual type descriptor or to one of its parents,
     return with set zero flag indicating matched record types.
     Note: This is a runtime function for Modula's type guard check.
  *)
  INLINE
  (
    IF Flat32Model
        PUSH EDI
        PUSH ESI
        MOV  EDI, Actual[EBP]          ; EDI = pointer to actual VM
        MOV  ESI, Wanted[EBP]          ; ESI = pointer to wanted VM
      repeat:
        CMP  EDI, ESI                  ; if pointer to actual VM = wanted VM
        JE   done                      ;   then it's done
        CMP  EDI, 0                    ; if pointer to actual VM is NIL
        LAHF                           ;   then set zero flag to off
        AND  AH, 40H                   ;
        JNE  done                      ;
        MOV  EDI, DWORD PTR [EDI]      ; EDI = pointer to parent of actual VM
        JMP  repeat
      done:
        ; zero flag on:  record type matched
        ; zero flag off: record type not matched
        POP  ESI
        POP  EDI
    ENDIF
    IF TinyModel
        PUSH DI
        PUSH SI
        MOV  DI, Actual[BP]         ; DI = pointer to actual VM
        MOV  SI, Wanted[BP]         ; SI = pointer to wanted VM
      repeat:
        CMP  DI, SI                 ; if pointer to actual VM = wanted VM
        JE   done                   ;   then it's done
        CMP  DI, 0                  ; if pointer to actual VM is NIL
        LAHF                        ;   then set zero flag to off
        AND  AH, 40H                ;
        JNE  done                   ;
        MOV  DI, WORD PTR [DI]      ; DI = pointer to parent of actual VM
        JMP  repeat
      done:
        ; zero flag on:  record type matched
        ; zero flag off: record type not matched
        POP  SI
        POP  DI
    ENDIF
    IF CompactModel OR LargeModel OR SmallModel OR MediumModel
        PUSH DI
        PUSH SI
        PUSH AX
        PUSH BX
        PUSH DS
        PUSH ES
        LES  DI, Actual[BP]          ; ES:DI = pointer to actual VM
        LDS  SI, Wanted[BP]          ; DS:SI = pointer to wanted VM
        MOV  AX, ES                  ; AX = SEG actual VM
        MOV  BX, DS                  ; BX = SEG wanted VM
      repeat:
        CMP  DI, SI                  ; OFFSET actual VM = OFFSET wanted VM ?
        JNE  next
        CMP  AX, BX                  ; SEG actual VM = SEG wanted VM ?
        JE   done
      next:
        CMP  DI, 0                   ; if OFFSET actual VM <> NIL
        JNE  next2                   ; then continue
        CMP  AX, 0                   ; else if SEG actual VM = NIL
        LAHF                         ; then reverse zero flag
        AND  AH, 40H                 ;      it's done
        JNE  done                    ;
      next2:
        LES  DI, DWORD PTR ES:[DI]   ; ES:DI = parent pointer to actual VM
        MOV  AX, ES                  ; AX = SEG parent of actual VM
        JMP  repeat
      done:
        ; zero flag on:  record type matched
        ; zero flag off: record type not matched
        POP  ES
        POP  DS
        POP  BX
        POP  AX
        POP  SI
        POP  DI
    ENDIF
  );
END TypeGuard;


(*$IF OS2*)
(*$IF Flat32Model*)

CONST
  MaxPriority = 31;
TYPE
  STRING29    = ARRAY [0..29] OF CHAR;
  PCOUNTMEM   = POINTER TO ARRAY [0..MaxPriority] OF LONGCARD;
  PMUTEXMEM   = POINTER TO ARRAY [0..MaxPriority] OF HMTX;


PROCEDURE HexChar( i : LONGCARD ) : CHAR;
BEGIN
  IF i <= 9 THEN
    RETURN CHR( ORD( '0' ) + i );
  ELSE
    RETURN CHR( ORD( 'A' ) + i - 10 );
  END;
END HexChar;

PROCEDURE GetMemId
(
  VAR Id     : STRING29;
  IdVal      : LONGCARD;
  PerThread  : BOOLEAN
);
VAR
  i          : LONGCARD;
BEGIN
  IF PerThread THEN
    Id := "\SHAREMEM\THREAD\xxxxxxxx.MOD";
  ELSE
    Id := "\SHAREMEM\PROCES\xxxxxxxx.MOD";
  END;
  FOR i := 0 TO 7 DO
    Id[17+i] := HexChar( (IdVal SHR (i*4)) AND 0000000FH );
  END;
END GetMemId;


(*$ENDIF *)
(*$ENDIF *)


PROCEDURE EnterPriority( Level : CARDINAL );
(*$IF OS2*)
(*$IF Flat32Model*)
CONST
  NotFound      = 2;
  AlreadyExists = 183;
VAR
  Thread        : DOSPROCESS.PTIB;
  Process       : DOSPROCESS.PPIB;
  MutexMemId    : STRING29;
  MutexMem      : PMUTEXMEM;
  CountMemId    : STRING29;
  CountMem      : PCOUNTMEM;
  rc            : APIRET;
  i             : LONGCARD;
(*$ENDIF*)
(*$ENDIF*)
BEGIN
  (* This runtime function processes a priority-module entry.
     A priority module is to be protected against other coroutines,
     Under OS/2 this is managed by using a per-process
     array of mutex semaphores for the priority levels.
  *)
  (*$IF OS2 *)
  (*$IF Flat32Model*)
  IF DosGetInfoBlocks( Thread, Process ) <> 0 THEN
    rc := DosBeep( 1000, 500 );
    RETURN;
  END;
  GetMemId( MutexMemId, Process^.ProcessId, FALSE );
  rc := DosGetNamedSharedMem( MutexMem, MutexMemId, fPERM );
  IF rc = NotFound THEN
    rc := DosEnterCritSec();
    rc := DosAllocSharedMem
    ( MutexMem, MutexMemId, SIZE(MutexMem^), fPERM+PAG_COMMIT );
    IF rc = AlreadyExists THEN
      (* another thread got it created in the meantime *)
      rc := DosExitCritSec();
    ELSIF rc <> 0 THEN
      rc := DosBeep( 1000, 500 );
      rc := DosExitCritSec();
      RETURN;
    ELSE
      FOR i := 0 TO MaxPriority DO
        rc := DosCreateMutexSem( NIL, MutexMem^[i], 0, FALSE );
      END;
      rc := DosExitCritSec();
    END;
  ELSIF rc <> 0 THEN
    rc := DosBeep( 1000, 500 );
    RETURN;
  END;
  GetMemId( CountMemId, Thread^.Ordinal, TRUE );
  rc := DosGetNamedSharedMem( CountMem, CountMemId, fPERM );
  IF rc = NotFound THEN
    rc := DosAllocSharedMem
    ( CountMem, CountMemId, SIZE(CountMem^), fPERM+PAG_COMMIT );
    IF rc <> 0 THEN
      rc := DosBeep( 1000, 500 );
      RETURN;
    ELSE
      FOR i := 0 TO MaxPriority DO
        CountMem^[i] := 0;
      END;
    END;
  ELSIF rc <> 0 THEN
    rc := DosBeep( 1000, 500 );
    RETURN;
  END;
  IF CountMem^[Level] = 0 THEN
    rc := DosRequestMutexSem( MutexMem^[Level], SEM_INDEFINITE_WAIT );
    IF rc <> 0 THEN
      rc := DosBeep( 1000, 500 );
      RETURN;
    END;
  END;
  INC( CountMem^[Level] );
  (*$ENDIF *)
  (*$ENDIF *)
  (*16-bit DOS and 16-bit MS-Windows 3.1 are only cooperative multitaskers *)
END EnterPriority;


PROCEDURE ExitPriority( Level : CARDINAL );
(*$IF OS2*)
(*$IF Flat32Model*)
VAR
  Thread        : DOSPROCESS.PTIB;
  Process       : DOSPROCESS.PPIB;
  MutexMemId    : STRING29;
  MutexMem      : PMUTEXMEM;
  CountMemId    : STRING29;
  CountMem      : PCOUNTMEM;
  rc            : APIRET;
(*$ENDIF*)
(*$ENDIF*)
BEGIN
  (* This runtime function sets the current thread to default priority *)
  (*$IF OS2 *)
  (*$IF Flat32Model*)
  IF DosGetInfoBlocks( Thread, Process ) <> 0 THEN
    rc := DosBeep( 1000, 500 );
    RETURN;
  END;
  GetMemId( MutexMemId, Process^.ProcessId, FALSE );
  rc := DosGetNamedSharedMem( MutexMem, MutexMemId, fPERM );
  IF rc <> 0 THEN
    rc := DosBeep( 1000, 500 );
    RETURN;
  END;
  GetMemId( CountMemId, Thread^.Ordinal, TRUE );
  rc := DosGetNamedSharedMem( CountMem, CountMemId, fPERM );
  IF rc <> 0 THEN
    rc := DosBeep( 1000, 500 );
    RETURN;
  END;
  IF CountMem^[Level] = 0 THEN
    rc := DosBeep( 1000, 500 );
    RETURN;
  END;
  DEC( CountMem^[Level] );
  IF CountMem^[Level] = 0 THEN
    rc := DosReleaseMutexSem( MutexMem^[Level] );
    IF rc <> 0 THEN
      rc := DosBeep( 1000, 500 );
    END;
  END;
  (*$ENDIF *)
  (*$ENDIF *)
  (*16-bit DOS and MS-Windows 3.1 are only cooperative multitaskers *)
END ExitPriority;


PROCEDURE LinkVMT( TypeInfo : DescriptorADDRESS; VMT : DescriptorADDRESS );
VAR
  RecInfo  : PTYPEINFO;
BEGIN
  (* This is a run time procedure, which links a record type
     descriptor with a virtual method table. This Procedure is
     automatically called at the beginning of any globally declared
     block for every newly introduced or extended record type with
     type bound procedures.
  *)
  RecInfo := TypeInfo;
  RecInfo^.VMT := VMT;
END LinkVMT;


PROCEDURE InheritVMT( Dest, Origin : DescriptorADDRESS; Size : LONGCARD );
VAR
  TypeInfo : PTYPEINFO;
BEGIN
  (* This runtime procedure is called during the creation of a new
     virtual method table for a newly declared (and possibly extended)
     record type with type bound procedures. The first step is to
     copy the contents of virtual method table of the parent record type
     to this one.
  *)
  TypeInfo := Origin;
  Origin := TypeInfo^.VMT;
  WHILE Size > 0 DO
    Dest^ := Origin^;
    INC( Dest );
    INC( Origin );
    DEC( Size );
  END;
END InheritVMT;


PROCEDURE InitVMT( Dest : DescriptorADDRESS; Size : LONGCARD );
BEGIN
  (* This runtime procedure is called during the creation of a new
     virtual method table for a newly declared record type. It is
     first initialized with zeroes.
  *)
  WHILE Size > 0 DO
    Dest^ := 0;
    INC( Dest );
    DEC( Size );
  END;
END InitVMT;


(*$IF OS2 *)
(*$IF Flat32Model *)

TYPE
  (*$CDECL+ C-style procedures *)

  SOMResolvePROC = PROCEDURE
  (   LONGWORD,                            (* any SOM Object *)
      LONGWORD                             (* method token *)
  ) : LONGWORD;                            (* method pointer *)

  SOMFindSMethodOkPROC = PROCEDURE
  (   LONGWORD,                            (* any SOM class object *)
      LONGWORD                             (* method identifier *)
  ) : LONGWORD;                            (* method pointer *)

  (*$CDECL-  Pascal-style  procedures *)

VAR
  SOMHandle            : HMODULE;
  SOMResolve           : SOMResolvePROC;
  SOMFindSMethodOk     : SOMFindSMethodOkPROC;

PROCEDURE InitSOM;
CONST
  INDEXsomFindSMethodOk = 26;
  INDEXclassObject      = 0;
VAR
  rc                 : APIRET;
  r                  : APIRET;
  NoObjNameBuf       : POINTER TO ARRAY [0..0] OF CHAR;
  SOMClassClassData  : POINTER TO ARRAY [0..36] OF LONGWORD;
BEGIN
  (* Get the module handle for (hopefully loaded) SOM.DLL.
     Then get associated procedures addresses for
     'somResolve', and 'somFindMethod'.
  *)
  NoObjNameBuf := NIL;
  rc := DosLoadModule( NoObjNameBuf^, 0, "SOM", SOMHandle );
  IF rc = 0 THEN
    rc := DosQueryProcAddr( SOMHandle, 0, "somResolve", SOMResolve );
    IF rc = 0 THEN
      rc := DosQueryProcAddr( SOMHandle, 0, "SOMClassClassData", SOMClassClassData );
      IF rc = 0 THEN
        SOMFindSMethodOk := SOMResolve
        ( SOMClassClassData^[INDEXclassObject],
          SOMClassClassData^[INDEXsomFindSMethodOk]
        );
        IF SOMFindSMethodOk <> SOMFindSMethodOkPROC( 0 ) THEN
          RETURN;
        ELSE
          r := DOSPROCESS.DosBeep( 1000, 500 );
          r := DOSPROCESS.DosBeep( 1200, 500 );
          r := DOSPROCESS.DosBeep( 1400, 500 );
          r := DOSPROCESS.DosBeep( 1600, 500 );
        END;
      ELSE
        r := DOSPROCESS.DosBeep( 1000, 500 );
        r := DOSPROCESS.DosBeep( 1200, 500 );
        r := DOSPROCESS.DosBeep( 1400, 500 );
      END;
    ELSE
      r := DOSPROCESS.DosBeep( 1000, 500 );
      r := DOSPROCESS.DosBeep( 1200, 500 );
    END;
  ELSE
    r := DOSPROCESS.DosBeep( 1000, 500 );
  END;
  SOMHandle := 0;
END InitSOM;

(*$ENDIF *)
(*$ENDIF *)


(*$CDECL+ C-style procedures *)

PROCEDURE somResolve( Object : LONGWORD; MethodToken : LONGWORD ) : LONGWORD;
BEGIN
  (* This runtime function is called whenever a type bound procedure
     is called with a OS/2 2.x SOM receiver. It performs a virtual
     SOM method resolution.
  *)
  INLINE
  (
    IF OS2
      IF Flat32Model
          CMP SOMHandle, 0
          JNE Resolve
          CALL InitSOM
          CMP SOMHandle, 0
          JE Exit
        Resolve:
          LEAVE
          JMP SOMResolve
        Exit:
      ENDIF
    ENDIF
  );
  RETURN 0;
END somResolve;


PROCEDURE somFindSMethodOk
(
  classObject : LONGWORD;
  idMethod    : LONGWORD
)             : LONGWORD;
BEGIN
  (* This runtime function finds for a given SOM class the pointer to
     a wanted method. The method refers to instances of the
     class. The class is specified by an 'classObject'.

     Useful for static SOM method resolution, e.g. after type guards.
  *)
  INLINE
  (
    IF OS2
      IF Flat32Model
          CMP SOMHandle, 0
          JNE Find
          CALL InitSOM
          CMP SOMHandle, 0
          JE Exit
        Find:
          LEAVE
          JMP  SOMFindSMethodOk
        Exit:
      ENDIF
    ENDIF
  );
  RETURN 0;
END somFindSMethodOk;


PROCEDURE somGetClass( Object : LONGWORD ) : LONGWORD;
BEGIN
  (* This runtime function is used as part of a SOM method
     resolution by name, in a sequence like this:
       classObject := SYSTEM.somGetClass( Object );
       methodId = somId of wanted method;
       method := SYSTEM.somFindSMethodOk( classObject, methodId );
  *)
  INLINE
  (
    IF OS2
      IF Flat32Model
          CMP SOMHandle, 0
          JNE Get
          CALL InitSOM
          CMP SOMHandle, 0
          JE Exit
        Get:
          MOV EAX, Object[ EBP ]      ;EAX = Object
          MOV EAX, DWORD PTR [EAX]    ;EAX = Object^.mtab
          MOV EAX, DWORD PTR [EAX]    ;EAX = Object^.mtab^.classObject
          LEAVE
          RETN
        Exit:
      ENDIF
    ENDIF
  );
  RETURN 0;
END somGetClass;

(*$CDECL-  Pascal-style  procedures *)



PROCEDURE SetTypeInfo( p : ADDRESS; TypeInfo : DescriptorADDRESS );
VAR
  TypeInfoLoc : POINTER TO DescriptorADDRESS;
BEGIN
  (* This function may be called for setting
     the bytes just before the location pointed at by 'p'
     with a dynamic type information, usually the address
     of a type descriptor.
  *)
  TypeInfoLoc := p - TSIZE( DescriptorADDRESS );
  TypeInfoLoc^ := TypeInfo;
END SetTypeInfo;



PROCEDURE StartUp();
VAR
  p : PROC;
  (*$IF FPU*)
  Control : CARDINAL;
  (*$ENDIF*)
BEGIN
  (* Do whatever needed for runtime startup *)
  MemSet( ADR( NilProc ), 0, SIZE( NilProc ) );
  ExitProc := NilProc;
  IF Flat32Model THEN
    (* dummy instructions: avoid compiler warning of not using Div16 IDiv16 *)
    p := Div16;
    p := IDiv16;
  END;
  (*$IF Flat32OS2 *)
  SOMHandle := 0;
  (*$ENDIF *)
  (*$IF FPU *)
  (*$F+*)
  INLINE
  (
    FINIT
    FSTCW Control[ EBP ]
    AND   Control[ EBP ], 0FCFFH
    OR    Control[ EBP ],  0300H    ; Extended pecision
    FLDCW Control[ EBP ]
  );
  (*$F-*)
  (*$ENDIF *)
END StartUp;


(*$IF Flat32OS2 *)

  PROCEDURE StackTop() : ADDRESS;
  BEGIN
    INLINE
    (
      LEAVE
      MOV   EAX, ESP
      ADD   EAX, 4
      RETN
    );
  END StackTop;

  PROCEDURE StackAlign2048();
  BEGIN
    INLINE
    (
      LEAVE
      MOV   EAX, ESP
      ADD   EAX, 4
      AND   EAX, 0000FFFFH
      CMP   EAX, 2048
      POP   EAX
      JAE   exit
      AND   ESP, 0FFFFF800H
      exit:
      JMP   EAX
    );
  END StackAlign2048;

  PROCEDURE Flat32ToFar16( Flat32 : ADDRESS ) : LONGWORD;
  BEGIN
    (* Transform a flat 0:32 pointer into a far 16:16 pointer
       using the OS/2 LDT tiling mechanism
    *)
    INLINE
    (
      MOV  EAX, Flat32[ EBP ]
      ROL  EAX, 16
      SHL  AX, 3
      ADD  AX, 7
      ROL  EAX, 16
      LEAVE
      RETN 4
    );
  END Flat32ToFar16;

  PROCEDURE Far16ToFlat32( Far16 : DWORD ) : ADDRESS;
  BEGIN
    (* Transform a far 16:16 pointer into a flat 0:32 pointer
       using the OS/2 LDT tiling mechanism
    *)
    INLINE
    (
      MOV EAX, Far16[ EBP ]
      ROL EAX, 16
      SHR AX, 3
      ROL EAX, 16
      LEAVE
      RETN 4
    );
  END Far16ToFlat32;

  PROCEDURE PushWORD( StackItem : WORD );
  BEGIN
    INLINE
    (
      LEAVE
      MOV   AX, WORD PTR [ESP+4]
      MOV   WORD PTR [ESP+6], AX
      POP   EAX
      ADD   ESP, 2
      JMP   EAX
    );
  END PushWORD;

  PROCEDURE PushDWORD( StackItem : DWORD );
  BEGIN
    INLINE
    (
      LEAVE
      RETN
    );
  END PushDWORD;

  PROCEDURE StackGrow( Count : LONGCARD );
  BEGIN
    INLINE
    (
      LEAVE
      POP    EAX
      SUB    ESP, DWORD PTR [ ESP ]
      ADD    ESP, 4
      JMP    EAX
    );
  END StackGrow;

  PROCEDURE PopDWORD( ) : DWORD;
  BEGIN
    INLINE
    (
      LEAVE
      MOV    EAX, DWORD PTR [ESP+4]
      RETN   4
    );
  END PopDWORD;

  PROCEDURE StackSet( pESP : ADDRESS );
  BEGIN
    INLINE
    (
      LEAVE
      POP   EAX
      POP   ESP
      JMP   EAX
    );
  END StackSet;

  PROCEDURE Stack32To16();
  BEGIN
    INLINE
    (
      LEAVE
      PUSH  ESP
      CALL  Flat32ToFar16
      PUSH  EBX
      SUB   EAX, 4
      PUSH  EAX
      POP   BX
      POP   AX
      MOV   SS, AX
      MOVZX ESP, BX
      POP   EBX
      AND   EBP, 0000FFFFH
      RETN
    );
  END Stack32To16;

  PROCEDURE Stack16To32();
  BEGIN
    INLINE
    (
      LEAVE
      PUSH   EAX
      PUSH   EBX
      ROL    EBP, 16
      MOV    BP, SS
      SHR    BP, 3
      ROL    EBP, 16
      MOV    AX, SP
      SHL    EAX, 16
      MOV    AX, SS
      SHR    AX, 3
      ROL    EAX, 16
      MOV    BX, DS
      MOV    SS, BX
      MOV    ESP, EAX
      POP    EBX
      POP    EAX
      RETN
    );
  END Stack16To32;

  PROCEDURE CallFar16
  (
    Target   : DWORD;    (* 16:16 API *)
    ParmSize : LONGCARD  (* size of API parameters *)
  )          : DWORD;    (* up to 4 bytes may be returned *)
  BEGIN
    INLINE
    (
      ; First transform stack and registers as follows:
      ;
      ; < lo EBP caller  > <--EBP
      ; < hi EBP caller  >
      ; < lo EIP caller  >
      ; < hi EIP caller  >
      ; < lo ParmSize    >   ==============>  < IP Target       >
      ; < hi ParmSize    >                    < CS Target       >
      ; < IP Target      >                    < IP resume16     >
      ; < CS Target      >                    < CS resume16     >
      ; < Target param n >                    < Target param n  >
      ;         :                                     :
      ; < Target param 0 >                    < Target param 0  >
      ; <      _         >                    < lo EIP resume32 >
      ; <      _         >                    < hi EIP resume32 >
      ; <      _         >                    < CS     resume32 >
      ; <      _         >                    < 0000H           >
      ; <      _         >                    < lo EBX caller   >
      ; <      _         >                    < hi EBX caller   >
      ; <      _         >                    < lo ECX caller   >
      ; <      _         >                    < hi ECX caller   >
      ; <      _         >                    < lo EDX caller   >
      ; <      _         >                    < hi EDX caller   >
      ; <      _         >                    < lo EDI caller   >
      ; <      _         >                    < hi EDI caller   >
      ; <      _         >                    < lo ESI caller   >
      ; <      _         >                    < hi ESI caller   >
      ; <      _         >                    < lo EBP caller   >
      ; <      _         >                    < hi EBP caller   >
      ; <      _         >                    < lo EIP caller   >
      ; <      _         >                    < hi EIP caller   >
      ;
      ; Then make the transfer to the 16-bit target API using a RETF.
      ; Upon return (still in 16-bit mode) revert to 32-bit mode.
      ; Restore registers for caller and return to caller.
      ;

      ; set RPL selector bits for Target segment selector from current SS
      MOV AX, SS
      AND AX, 3
      OR  WORD PTR Target[ EBP+2 ], AX

      ; switch to a 16-bit stack
      CALL  Stack32To16

      ; Save registers of caller, because target API might destroy them.
      MOV   ESP, EBP
      ADD   EBP, ParmSize[ EBP ]
      ADD   EBP, 16
      PUSH  ESI
      PUSH  EDI
      PUSH  EDX
      PUSH  ECX
      PUSH  EBX
      POP   DWORD PTR [ EBP+08 ]
      POP   DWORD PTR [ EBP+12 ]
      POP   DWORD PTR [ EBP+16 ]
      POP   DWORD PTR [ EBP+20 ]
      POP   DWORD PTR [ EBP+24 ]
      POP   DWORD PTR [ EBP+28 ]
      POP   DWORD PTR [ EBP+32 ]
      MOV   WORD PTR  [ EBP+06 ], 0000H
      MOV   WORD PTR  [ EBP+04 ], CS
      CALL  loadresume
      MOV   DWORD PTR [ EBP ], EAX
      ADD   ESP, 4

      ; transfer to 16:16 target API
      transfer:
      CALL  next
      next:
      POP   EAX                  ;1
      ADD   EAX, 31              ;5
      TEST  AL, 1                ;2    find a 16:16 resume-address with
      JZ    transfer2            ;6    at least 2 contiguous bytes not
      ADD   EAX, 3               ;5    crossing a 64 KB boundary
      transfer2:                 ;0
      PUSH  EAX                  ;1
      CALL  Flat32ToFar16        ;5
      XCHG  EAX, DWORD PTR [ESP] ;3
      PUSH  EAX                  ;1
      DB    66H                  ;1
      RETF                       ;1

      ; After 16:16 API call resume at one of the following 2 RETF instructions
      resume16:
      DB    66H                  ;1
      RETF                       ;1    transfer to resume32
      NOP                        ;1
      DB    66H                  ;1    transfer to resume32
      RETF                       ;1

      loadresume:
      CALL next2
      next2:
      POP  EAX                   ;1
      ADD  EAX,7                 ;5
      RETN                       ;1

      ;now back in flat 32-bit mode after 16:16 API call, restore regs, return
      resume32:
      CALL Stack16To32
      PUSH DX
      PUSH AX
      POP  EAX                   ; EAX = DX:AX of 16-bit API return code
      POP  EBX
      POP  ECX
      POP  EDX
      POP  EDI
      POP  ESI
      POP  EBP
      RETN
    );
  END CallFar16;

  PROCEDURE AlignWORD( i : LONGCARD ) : LONGCARD;
  BEGIN
    RETURN (i+3) AND 0FFFFFFFEH;
  END AlignWORD;

  TYPE
    REGSAVE       = ARRAY [0..8] OF DWORD;

  VAR
    ThunkHeap     : ADDRESS;

  CONST
    ThunkHeapSize = 10000H;

  PROCEDURE ThunkAlloc( VAR a : ADDRESS; size : LONGCARD ) : APIRET;
  BEGIN
    IF ThunkHeap = NIL THEN
      a := NIL;
      RETURN 0FFFFFFFFH;
    END;
    a := NIL;
    RETURN DosSubAllocMem( ThunkHeap, a, size );
  END ThunkAlloc;

  PROCEDURE ThunkFree( a : ADDRESS; size : LONGCARD ) : APIRET;
  BEGIN
    IF ThunkHeap <> NIL THEN
      RETURN DosSubFreeMem( ThunkHeap, a, size );
    END;
    RETURN 0FFFFFFFFH;
  END ThunkFree;

  PROCEDURE ExitThunkHeap();
  VAR
    rc : APIRET;
  BEGIN
    IF ThunkHeap <> NIL THEN
      rc := DosSubUnsetMem( ThunkHeap );
      rc := DosFreeMem( ThunkHeap );
      ThunkHeap := NIL;
    END;
    rc := DosExitList( EXLST_EXIT, ExitThunkHeap );
  END ExitThunkHeap;

  PROCEDURE InitThunkHeap() : APIRET;
  CONST
    ExitOrder = (80H-1)*256; (* 1 level before OS/2 components *)
  VAR
    rc  : APIRET;
    rc2 : APIRET;
  BEGIN
    rc := DosAllocMem( ThunkHeap, ThunkHeapSize, OBJ_TILE+fPERM );
    IF rc = 0 THEN
      rc := DosSubSetMem( ThunkHeap, DOSSUB_INIT+DOSSUB_SPARSE_OBJ, ThunkHeapSize );
      IF rc = 0 THEN
        rc := DosExitList( EXLST_ADD + ExitOrder, ExitThunkHeap );
        IF rc = 0 THEN
          RETURN 0;
        END;
      END;
      rc2 := DosFreeMem( ThunkHeap );
      RETURN rc;
    END;
    RETURN rc;
  END InitThunkHeap;

  PROCEDURE Thunk
  (
    Target        : DWORD;
    VAR Param     : ARRAY OF DWORD;
    VAR PosSize   : ARRAY OF LONGCARD
  )               : DWORD;

  VAR
    i             : LONGINT;
    j             : LONGCARD;
    k             : LONGINT;
    l             : LONGCARD;
    rc            : APIRET;
    rc2           : APIRET;
    p             : ADDRESS;
    OldStackTop   : ADDRESS;

  BEGIN

    (* initialize thunk heap if not yet done *)
    IF ThunkHeap = NIL THEN
      rc := InitThunkHeap();
      IF rc <> 0 THEN
        rc2 := DOSPROCESS.DosBeep( 1000, 500 );
        RETURN rc;
      END;
    END;

    (* at least 2 KB stack space needed without 64KB boundaries *)
    OldStackTop := StackTop();
    StackAlign2048();

    (* Produce local thunk copies for variables passed by reference *)
    k := HIGH( PosSize );
    FOR i := 0 TO k-1 DO
      IF PosSize[i] >= 80000000H THEN
        j := (PosSize[i] - 80000000H) SHR 16;
        IF ADDRESS( Param[j] ) = NIL THEN
          (* NIL parameter should point to zero-size area *)
          PosSize[i] := PosSize[i] AND 0FFFF0000H;
        END;
        rc := ThunkAlloc( p, SHORT( PosSize[i] ) );
        IF rc <> 0 THEN
          (* free already allocated heap memory and return error *)
          FOR i := i-1 TO 0 BY -1 DO
            IF PosSize[i] >= 80000000H THEN
              p := PopDWORD();
              rc2 := ThunkFree( p, SHORT( PosSize[i] ) );
            END;
          END;
          StackSet( OldStackTop );
          RETURN rc;
        END;
        (* Copy pointed memory to thunk heap and save old pointer *)
        MemCpy( p, Param[j], SHORT( PosSize[i] ) );
        PushDWORD( Param[j] );
        Param[j] := Flat32ToFar16( p );
      END;
    END;

    (* reserve space for 32-bit registers to be saved *)
    StackGrow( TSIZE( REGSAVE ) );

    (* Push target parameters as 16-bit stack words *)
    p := StackTop();
    k := HIGH( PosSize );
    FOR i := k-1 TO 0 BY -1 DO
      IF PosSize[i] >= 80000000H THEN
        j := (PosSize[i] - 80000000H) SHR 16;
        PushDWORD( Param[j] );
      ELSE
        j := PosSize[i] SHR 16;
        l := SHORT( PosSize[i] );
        IF l <= TSIZE( CARDINAL ) THEN
          PushWORD( SHORT( Param[j] ) );
        ELSIF l <= TSIZE( LONGCARD ) THEN
          PushDWORD( Param[j] );
        ELSE
          l := AlignWORD( SHORT( PosSize[i] ) );
          StackGrow( l );
          MemCpy( StackTop(), ADR( Param[j] ), l );
        END;
      END;
    END;

    (* call 16-bit target API *)
    j := p - StackTop();
    rc := CallFar16( Target, j );
  (*rc := CallFar16( Flat32ToFar16( Target ), j );*)

    (* move local copies of variables passed by reference back to origins *)
    k := HIGH( PosSize );
    FOR i := k-1 TO 0 BY -1 DO
      IF PosSize[i] >= 80000000H THEN
        p := PopDWORD();
        j := (PosSize[i] - 80000000H) SHR 16;
        Param[j] := Far16ToFlat32( Param[j] );
        MemCpy( p, Param[j], SHORT( PosSize[i] ) );
        rc2 := ThunkFree( Param[j], SHORT( PosSize[i] ) );
        Param[j] := p;
      END;
    END;

    (* restore stack pointer and return *)
    StackSet( OldStackTop );
    RETURN rc;

  END Thunk;


(*$ELSE *)

  VAR
    ThunkHeap     : ADDRESS;

  PROCEDURE Thunk
  (
    Target        : DWORD;
    (*$IF Data32*)
    VAR Param     : ARRAY OF DWORD;
    (*$ELSE*)
    VAR Param     : ARRAY OF WORD;
    (*$ENDIF*)
    VAR PosSize   : ARRAY OF LONGCARD
  )               : DWORD;
  BEGIN
    (* No thunking implemented if not 32-bit flat OS/2 *)
    RETURN 0;
  END Thunk;

(*$ENDIF *)


BEGIN (* SYSTEM *)
  StartUp();
  ThunkHeap := NIL;
END SYSTEM.
