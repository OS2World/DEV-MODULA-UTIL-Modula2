MODULE CoroutineDemo;

(**************************************************************************
   OS/2 2.x  Modula-2 Coroutine demo: displaying with coroutines.

             Note: This program relies on coroutines to display
                   messages on the screen. Although this activity
                   could be easily expressed without coroutines,
                   the example demonstrates the features of setting
                   up coroutines and transfering control between them.
                   The program continually displays on the full screen
                   terminal the message
                     DispProc1
                     DispProc2
                     ...
                   For further details refer to the book:
                     'Modula-2 A Seafarer's Manula and Shipyard Guide'
                     by Edward J. Joyce, pages 184-186,
                     1985, Addison-Wesley

   Copyright (c) 1993-1994 by Juergen Neuhoff
**************************************************************************)

IMPORT SYSTEM;
IMPORT InOut;

VAR
  main          : SYSTEM.PROCESS;
  p1            : SYSTEM.PROCESS;
  p2            : SYSTEM.PROCESS;
  wsp1, wsp2    : ARRAY [0..4095] OF SYSTEM.BYTE;

PROCEDURE DispProc1;
BEGIN
  LOOP
    InOut.WriteLn();
    InOut.WriteString( "DispProc1" );
    SYSTEM.TRANSFER( p1, p2 );          (* invoke other procedure *)
  END;
END DispProc1;


PROCEDURE DispProc2;
BEGIN
  LOOP
    InOut.WriteLn();
    InOut.WriteString( "DispProc2" );
    SYSTEM.TRANSFER( p2, p1 );          (* invoke other procedure *)
  END;
END DispProc2;


BEGIN (* CoroutineDemo *)
  SYSTEM.NEWPROCESS( DispProc1, SYSTEM.ADR( wsp1 ), SIZE( wsp1 ), p1 );
  SYSTEM.NEWPROCESS( DispProc2, SYSTEM.ADR( wsp2 ), SIZE( wsp2 ), p2 );
  SYSTEM.TRANSFER( main, p1 );
END CoroutineDemo.
