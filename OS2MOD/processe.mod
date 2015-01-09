IMPLEMENTATION MODULE Processes;

(**************************************************************************
   OS/2 2.x  Modula-2 coroutines using OS/2 threads.

   Copyright (c) 1993,1995 by Juergen Neuhoff
**************************************************************************)

(*$XL+       Modula-2 language extensions: '_' allowed for symbol names *)
(*$A         default alignment for record fields                        *)
(*$XF+       relaxed function designator usage                          *)

FROM   OS2DEF        IMPORT PID, TID, APIRET;
FROM   DOSMISC       IMPORT DosQuerySysInfo, QSV_PAGE_SIZE;
FROM   DOSPROCESS    IMPORT DosCreateThread, PFNTHREAD;
FROM   DOSPROCESS    IMPORT PTIB, PPIB;
FROM   DOSPROCESS    IMPORT DosSleep, DosSetPriority;
FROM   DOSPROCESS    IMPORT PRTYS_THREAD, PRTYC_NOCHANGE;
FROM   DOSSEMAPHORES IMPORT HMTX, HEV, SEM_INDEFINITE_WAIT;
FROM   DOSSEMAPHORES IMPORT DosCreateEventSem, DosWaitEventSem;
FROM   DOSSEMAPHORES IMPORT DosResetEventSem, DosPostEventSem;
FROM   DOSSEMAPHORES IMPORT DosRequestMutexSem, DosReleaseMutexSem;
FROM   DOSSEMAPHORES IMPORT DosCreateMutexSem, DosQueryMutexSem;
FROM   DOSPROCESS    IMPORT DosBeep, DosGetInfoBlocks;
FROM   DOSMEMMGR     IMPORT DosGetNamedSharedMem, fPERM;
IMPORT SYSTEM;

TYPE
  SIGNAL      = POINTER TO EVENT;
  EVENT       = RECORD
    ThreadId    : LONGCARD;
    Access      : HMTX;
    Event       : BOOLEAN;
                END;


CONST
  MaxEventSignal = 127;
  MaxPriority    = 31;

VAR
  PageSize       : LONGCARD;
  EventSignal    : ARRAY [0..MaxEventSignal] OF EVENT;
  ExclusiveInit  : HMTX;


TYPE
  STRING29       = ARRAY [0..29] OF CHAR;
  PCOUNTMEM      = POINTER TO ARRAY [0..MaxPriority] OF LONGCARD;
  PMUTEXMEM      = POINTER TO ARRAY [0..MaxPriority] OF HMTX;



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



PROCEDURE StartProcess( P : PROC; n : CARDINAL );
VAR
  ThreadId : TID;
BEGIN
  IF n < PageSize THEN
    n := SHORT( PageSize );
  END;
  DosCreateThread( ThreadId, PFNTHREAD( P ), 0, 0, n );
END StartProcess;



PROCEDURE SEND( VAR s : SIGNAL );
BEGIN
  IF s <> NIL THEN
    DosRequestMutexSem( s^.Access, SEM_INDEFINITE_WAIT );
    s^.Event := TRUE;
    (*****
    IF s^.ThreadId <> 0 THEN
      DosSetPriority( PRTYS_THREAD, PRTYC_NOCHANGE, 1, s^.ThreadId );
    END;
    *****)
    DosReleaseMutexSem( s^.Access );
  ELSE
    DosBeep( 1000, 500 );
  END;
END SEND;



PROCEDURE WAIT( VAR s : SIGNAL );
VAR
  Thread        : PTIB;
  Process       : PPIB;
  PriorityMemId : STRING29;
  PriorityMem   : PMUTEXMEM;
  CountMemId    : STRING29;
  CountMem      : PCOUNTMEM;
  i             : LONGCARD;
  SavedThreadId : TID;
  Delta         : LONGCARD;
BEGIN

  IF s = NIL THEN
    DosBeep( 1000, 500 );
    RETURN;
  END;
  IF DosGetInfoBlocks( Thread, Process ) <> 0 THEN
    DosBeep( 1000, 500 );
    RETURN;
  END;
  GetMemId( PriorityMemId, Process^.ProcessId, FALSE );
  GetMemId( CountMemId, Thread^.Ordinal, TRUE );
  IF DosGetNamedSharedMem( PriorityMem, PriorityMemId, fPERM ) <> 0 THEN
    PriorityMem := NIL;
    CountMem := NIL;
  ELSIF DosGetNamedSharedMem( CountMem, CountMemId, fPERM ) <> 0 THEN
    PriorityMem := NIL;
    CountMem := NIL;
  END;

  SavedThreadId := s^.ThreadId;
  s^.ThreadId := Thread^.Tib2^.Tid;
  Delta := Thread^.Tib2^.Pri;

  (* release exclusive resource ownership *)
  IF (PriorityMem <> NIL) AND (CountMem <> NIL) THEN
    (* release current thread's priority level(s) before waiting *)
    FOR i := 0 TO MaxPriority DO
      IF CountMem^[i] > 0 THEN
        DosReleaseMutexSem( PriorityMem^[i] );
      END;
    END;
  END;

  LOOP

    (* give up remaining time slice if no event; improves performance *)
    DosRequestMutexSem( s^.Access, SEM_INDEFINITE_WAIT );
    IF NOT s^.Event THEN
      DosReleaseMutexSem( s^.Access );
      DosSleep( 0 );
    ELSE
      DosReleaseMutexSem( s^.Access );
    END;

    (* periodically regain exclusive resource ownership ... *)
    IF (PriorityMem <> NIL) AND (CountMem <> NIL) THEN
      FOR i := 0 TO MaxPriority DO
        IF CountMem^[i] > 0 THEN
          DosRequestMutexSem( PriorityMem^[i], SEM_INDEFINITE_WAIT );
        END;
      END;
    END;

    (* .... and check the event signal exclusively *)

    DosRequestMutexSem( s^.Access, SEM_INDEFINITE_WAIT );
    IF s^.Event THEN
      IF Thread^.Tib2^.Tid = s^.ThreadId THEN
        s^.Event := FALSE;
        s^.ThreadId := SavedThreadId;
        (****
        Delta := Delta - Thread^.Tib2^.Pri;
        DosSetPriority( PRTYS_THREAD, PRTYC_NOCHANGE, Delta, 0 );
        ****)
        DosReleaseMutexSem( s^.Access );
        EXIT;
      END;
    END;
    DosReleaseMutexSem( s^.Access );

    (* No event yet, release exclusive resource ownership and wait on *)
    IF (PriorityMem <> NIL) AND (CountMem <> NIL) THEN
      FOR i := 0 TO MaxPriority DO
        IF CountMem^[i] > 0 THEN
          DosReleaseMutexSem( PriorityMem^[i] );
        END;
      END;
    END;

  END;
END WAIT;


PROCEDURE CLEAR( VAR s : SIGNAL );
BEGIN
  IF s <> NIL THEN
    DosRequestMutexSem( s^.Access, SEM_INDEFINITE_WAIT );
    s^.Event := FALSE;
    DosReleaseMutexSem( s^.Access );
  END
END CLEAR;



PROCEDURE Awaited( s : SIGNAL ) : BOOLEAN;
VAR
  ok : BOOLEAN;
BEGIN
  IF s <> NIL THEN
    DosRequestMutexSem( s^.Access, SEM_INDEFINITE_WAIT );
    ok := (s^.ThreadId <> 0);
    DosReleaseMutexSem( s^.Access );
  ELSE
    ok := FALSE;
  END;
  RETURN ok;
END Awaited;



PROCEDURE Init( VAR s : SIGNAL );
VAR
  i  : LONGCARD;
BEGIN
  IF DosRequestMutexSem( ExclusiveInit, SEM_INDEFINITE_WAIT ) = 0 THEN
    i := 0;
    WHILE (i <= MaxEventSignal) AND (EventSignal[i].Access <> 0) DO
      INC(i);
    END;
    IF i <= MaxEventSignal THEN
      IF DosCreateMutexSem( NIL, EventSignal[i].Access, 0, FALSE ) = 0 THEN
        s := SYSTEM.ADR( EventSignal[i] );
        s^.Event := FALSE;
        s^.ThreadId := 0;
        DosReleaseMutexSem( ExclusiveInit );
        RETURN;
      END;
    END;
  END;
  DosBeep( 500, 500 );
  s := NIL;
  DosReleaseMutexSem( ExclusiveInit );
END Init;



BEGIN (* Processes *)
  DosQuerySysInfo( QSV_PAGE_SIZE, QSV_PAGE_SIZE, PageSize, SIZE( PageSize ) );
  SYSTEM.MemSet( SYSTEM.ADR( EventSignal ), 0, SIZE( EventSignal ) );
  IF DosCreateMutexSem( NIL, ExclusiveInit, 0, FALSE ) <> 0 THEN
    DosBeep( 1000, 500 );
  END;
END Processes.
