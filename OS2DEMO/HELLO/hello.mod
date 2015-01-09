MODULE HELLO;

(************************************************************************
    This is the Modula-2 version of the HELLO.C sample program
    from the IBM Developer's Toolkit for OS/2.

    Needed tools:
      MOD.EXE         This Modula-2 Compiler
      LINK386.EXE     OS/2 linker
                      (part of OS/2 2.x or OS/2 3.0)
      RC.EXE          Resource Script Compiler
                      (from OS/2 Developer's Toolkit)
      ICONEDIT.EXE    Icon Editor with which to create a HELLO.ICO
                      (part of OS/2 2.x or OS/2 3.0)

    Needed files:
      HELLO.MOD       Source file of the HELLO sample program.
      HELLO.RC        Resource Script File for the HELLO sample program.
      HELLO.ICO       Program Icon

    OS/2 commands for compilation and linkage:
      MOD HELLO.MOD -o -m -pm:pm -ss=8
      LINK386 @HELLO.RSP
      RC HELLO.RC HELLO.EXE
*************************************************************************)

(*$XL+       Modula-2 language extensions: '_' allowed for symbol names *)
(*$A         default alignment for record fields                        *)
(*$CDECL-    Pascal-style procedures                                    *)

FROM SYSTEM        IMPORT ADR, BYTE, LONGWORD;

FROM OS2DEF        IMPORT NULLHANDLE, HWND, HMQ, HMODULE, HPS, HAB;
FROM OS2DEF        IMPORT RECTL, POINTL, PSZ;

FROM WINDEF        IMPORT CS_SIZEREDRAW, HWND_DESKTOP, HWND_TOP;
FROM WINDEF        IMPORT MPARAM, MRESULT;

FROM DOSPROCESS    IMPORT DosBeep;
FROM DOSPROCESS    IMPORT DosExit;
FROM DOSPROCESS    IMPORT EXIT_PROCESS;

FROM WINFRAMEMGR   IMPORT WM_ERASEBACKGROUND;
FROM WINFRAMEMGR   IMPORT WinCreateStdWindow;
FROM WINFRAMEMGR   IMPORT FCF_STANDARD, FCF_SHELLPOSITION;

FROM WINWINDOWMGR  IMPORT WinInitialize;
FROM WINWINDOWMGR  IMPORT WinRegisterClass;
FROM WINWINDOWMGR  IMPORT WinSetWindowText;
FROM WINWINDOWMGR  IMPORT WinSetWindowPos;
FROM WINWINDOWMGR  IMPORT WinDestroyWindow;
FROM WINWINDOWMGR  IMPORT WinTerminate;
FROM WINWINDOWMGR  IMPORT WinLoadString;
FROM WINWINDOWMGR  IMPORT WinInvalidateRegion;
FROM WINWINDOWMGR  IMPORT WinDefWindowProc;
FROM WINWINDOWMGR  IMPORT WinBeginPaint;
FROM WINWINDOWMGR  IMPORT WinEndPaint;
FROM WINWINDOWMGR  IMPORT SWP_SIZE, SWP_MOVE, SWP_ACTIVATE, SWP_SHOW;

FROM WINMESSAGEMGR IMPORT WinPostMsg;
FROM WINMESSAGEMGR IMPORT WinCreateMsgQueue;
FROM WINMESSAGEMGR IMPORT WinGetMsg;
FROM WINMESSAGEMGR IMPORT WinDispatchMsg;
FROM WINMESSAGEMGR IMPORT WinDestroyMsgQueue;
FROM WINMESSAGEMGR IMPORT QMSG, PCMDMSG;
FROM WINMESSAGEMGR IMPORT WM_CREATE, WM_COMMAND, WM_PAINT, WM_CLOSE, WM_QUIT;

FROM WINERRORS     IMPORT WinGetErrorInfo;
FROM WINERRORS     IMPORT WinFreeErrorInfo;
FROM WINERRORS     IMPORT PERRINFO;

FROM WINDIALOGS    IMPORT MB_MOVEABLE, MB_CUACRITICAL, MB_CANCEL;

FROM GPIPRIMITIVES IMPORT GpiSetColor;
FROM GPIPRIMITIVES IMPORT GpiSetBackColor;
FROM GPIPRIMITIVES IMPORT GpiSetBackMix;
FROM GPIPRIMITIVES IMPORT GpiCharStringAt;
FROM GPIPRIMITIVES IMPORT CLR_NEUTRAL, CLR_DARKGRAY, BM_OVERPAINT;


CONST
  MSGBOXID     = 1001;
  ID_WINDOW    = 256;
  ID_OPTIONS   = 257;
  ID_OPTION1   = 258;
  ID_OPTION2   = 259;
  ID_OPTION3   = 260;
  ID_EXITPROG  = 261;
  IDS_HELLO    = 262;
  IDS_1        = 263;
  IDS_2        = 264;
  IDS_3        = 265;

CONST
  STRINGLENGTH = 20;           (* Length of string             *)

TYPE
  STRING       = ARRAY [0..STRINGLENGTH-1] OF CHAR;

VAR                            (* Define parameters by type     *)
  hab          : HAB;          (* PM anchor block handle        *)
  szHello      : STRING;       (* String parameters, set in     *)
  sz1          : STRING;       (* the processing of WM_CREATE,  *)
  sz2          : STRING;       (* and used in the processing    *)
  sz3          : STRING;       (* of WM_COMMAND, in window      *)
  szString     : STRING;       (* procedure.                    *)
  pszErrMsg    : PSZ;
  hmq          : HMQ;          (* Message queue handle          *)
  hwndClient   : HWND;         (* Client area window handle     *)
  hwndFrame    : HWND;         (* Frame window handle           *)
  qmsg         : QMSG;         (* Message from message queue    *)
  flCreate     : LONGCARD;     (* Window creation control flags *)
  ok           : BOOLEAN;
  b1           : SYSTEM.BYTE;
  b4           : SYSTEM.LONGWORD;


PROCEDURE StrLen
( VAR Str : ARRAY OF CHAR
)         : LONGCARD;
VAR
  i       : LONGCARD;
  j       : LONGCARD;
BEGIN
  j := HIGH( Str );
  i := 0;
  WHILE (Str[ i ] <> CHR( 0 )) AND (i < j) DO
    INC( i );
  END;
  RETURN i;
END StrLen;



(**************************************************************************
  Name:
    MyWindowProc
  Description:
    The window procedure associated with the client area in
    the standard frame window. It processes all messages
    either sent or posted to the client area, depending on
    the message command and parameters.
  Concepts:
  Parameters:
    hwnd = window handle
    msg = message code
    mp1 = first message parameter
    mp2 = second message parameter
  Return:
    depends on message sent
***************************************************************************)

(*$CDECL+    C-style procedures                                         *)

PROCEDURE MyWindowProc
( hwnd         : HWND;
  msg          : LONGCARD;
  mp1          : MPARAM;
  mp2          : MPARAM
)              : MRESULT;
VAR
  hps          : HPS;                   (* Presentation Space handle    *)
  rc           : RECTL;                 (* Rectangle coordinates        *)
  pt           : POINTL;                (* String screen coordinates    *)
  CommandMsg   : PCMDMSG;               (* WM_COMMAND message parameter *)
BEGIN
  CASE msg OF
  | WM_CREATE:
    (* Window initialization is performed here            *)
    (* WinLoadString loads strings from the resource file.*)
    b4 := WinLoadString( hab, 0, IDS_HELLO, STRINGLENGTH, szHello );
    b4 := WinLoadString( hab, 0, IDS_1,     STRINGLENGTH, sz1     );
    b4 := WinLoadString( hab, 0, IDS_2,     STRINGLENGTH, sz2     );
    b4 := WinLoadString( hab, 0, IDS_3,     STRINGLENGTH, sz3     );
    szString := szHello;
  | WM_COMMAND:
    (* When the user chooses option 1, 2, or 3 from the Options pull-  *)
    (* down, the text string is set to 1, 2, or 3, and                 *)
    (* WinInvalidateRegion sends a WM_PAINT message.                   *)
    (* When Exit is chosen, the application posts itself a WM_CLOSE    *)
    (* message.                                                        *)
    CommandMsg := ADR( mp1 );
    CASE CommandMsg^.cmd OF
    | ID_OPTION1:
      szString := sz1;
      b1 :=  WinInvalidateRegion( hwnd, 0, FALSE );
    | ID_OPTION2:
      szString := sz2;
      b1 := WinInvalidateRegion( hwnd, 0, FALSE );
    | ID_OPTION3:
      szString := sz3;
      b1 := WinInvalidateRegion( hwnd, 0, FALSE );
    | ID_EXITPROG:
      b1 := WinPostMsg( hwnd, WM_CLOSE, NIL, NIL );
    ELSE
      RETURN WinDefWindowProc( hwnd, msg, mp1, mp2 );
    END;
  | WM_ERASEBACKGROUND:
    (* Return TRUE to request PM to paint the window background *)
    (* in SYSCLR_WINDOW.                                        *)
    RETURN LONG( LONG( SHORTCARD( TRUE ) ) );
  | WM_PAINT:
    (*b4 := DosBeep( 400, 1000 );*)
    (* Window contents are drawn here *)
    (* Create a presentation space  *)
    hps := WinBeginPaint( hwnd, 0, ADR(rc) );
    (* Set the text coordinates *)
    pt.x := 50; pt.y := 50;
    (* Set the color of the text *)
    b1 := GpiSetColor( hps, CLR_NEUTRAL );
    (* Set the background color of the text and how it mixes *)
    b1 := GpiSetBackColor( hps, CLR_DARKGRAY );
    b1 := GpiSetBackMix( hps, BM_OVERPAINT );
    (* Draw the string... *)
    (*b4 := DosBeep( 350, 1000 );*)
    b4 := GpiCharStringAt( hps, pt, StrLen( szString ), szString );
    (*b4 := DosBeep( 300, 1000 );*)
    b1 := WinEndPaint( hps );
    (*b4 := DosBeep( 250, 1000 );*)
    (* Drawing is complete *)
  | WM_CLOSE:
    (* This is the place to put your termination routines *)
    (* Cause termination *)
    b1 := WinPostMsg( hwnd, WM_QUIT, NIL, NIL );
  ELSE
    (* Everything else comes here. *)
    (* This call MUST exist in your window procedure. *)
    RETURN WinDefWindowProc( hwnd, msg, mp1, mp2 );
  END;
  RETURN LONG( LONG( SHORTCARD( FALSE ) ) );
END MyWindowProc;

(*$CDECL-    Pascal-style procedures                                    *)



(**************************************************************************
  Name:
    AbortHello
  Description:
    Report an error returned from an API service
  Concepts:
    use of message box to display information
  Parameters:
    hwndFrame = frame window handle
    hwndClient = client window handle
  Return:
    [none]
***************************************************************************)

PROCEDURE AbortHello
( hwndFrame         : HWND;
  hwndClient        : HWND
);
VAR
  pErrInfoBlk       : PERRINFO;
  pusOffset         : POINTER TO CARDINAL;
  fStyle            : LONGCARD;
BEGIN
  (*b4 := DosBeep( 2000, 1000 );*)
  pErrInfoBlk := WinGetErrorInfo( hab );
  IF pErrInfoBlk <> NIL THEN
    pusOffset := ADR( pErrInfoBlk^ ) + pErrInfoBlk^.offaoffszMsg;
    pszErrMsg := ADR( pErrInfoBlk^ ) + pusOffset^;
    IF (hwndFrame <> 0) AND (hwndClient <> 0) THEN
      fStyle := MB_MOVEABLE OR MB_CUACRITICAL OR MB_CANCEL;
      b4 := WINDIALOGS.WinMessageBox
      ( HWND_DESKTOP,           (* Parent window is desk top *)
        hwndFrame,              (* Owner window is our frame *)
        pszErrMsg^,             (* PMWIN Error message       *)
        "Error Msg",            (* Title bar message         *)
        MSGBOXID,               (* Message identifier        *)
        fStyle                  (* Flags                     *)
      );
    END;
    b1 := WinFreeErrorInfo( pErrInfoBlk );
  END;
  b1 := WinPostMsg( hwndClient, WM_QUIT, NIL, NIL );
END AbortHello;



(**************************************************************************
  Name:
    HELLO mainline
  Description:
    Initializes the process for OS/2 PM services and
    process the application message queue until a
    WM_QUIT message is received.  It then destroys all
    OS/2 PM resources and terminates.
  Concepts:
    - obtains anchor block handle and creates message
      queue
    - creates the main frame window which creates the
      main client window
    - polls the message queue via Get/Dispatch Msg loop
    - upon exiting the loop, exits
  Parameters:
    [none]
  Return:
    1 - if successful execution completed
    0 - if error
***************************************************************************)

BEGIN (* of HELLO mainline *)

  hwndClient := NULLHANDLE;
  hwndFrame := NULLHANDLE;

  (* Initializes the process for OS/2 PM services *)
  szHello := "Hello";

  hab := WinInitialize( 0 );
  IF hab = 0 THEN
    AbortHello( hwndFrame, hwndClient );
  END;

  (* Create a message queue *)
  hmq := WinCreateMsgQueue( hab, 0 );
  IF hmq = 0 THEN
    AbortHello( hwndFrame, hwndClient );
  END;

  (* Register a new window class *)
  ok := WinRegisterClass
  ( hab,             (* Anchor block handle *)
    "MyWindow",      (* Window class name *)
    MyWindowProc,    (* Address of window procedure *)
    CS_SIZEREDRAW,   (* Class style *)
    0                (* No extra window words *)
  );
  IF NOT ok THEN
    AbortHello( hwndFrame, hwndClient );
  END;

  (* Set frame control flags to standard except for shell positioning *)
  flCreate := FCF_STANDARD AND NOT FCF_SHELLPOSITION;

  (* Create a standard window. OS/2 Presentation Manager sends the
     intial messages WM_CREATE and WM_ADJUSTWINDOWPOS to the associated
     window procedure 'MyWindowProc'.
  *)
  hwndFrame := WinCreateStdWindow
  ( HWND_DESKTOP,    (* Desktop window is parent *)
    0,               (* STD. window styles *)
    flCreate,        (* Frame control flag *)
    "MyWindow",      (* Client window class name *)
    "",              (* No window text *)
    0,               (* No special class style *)
    HMODULE( 0 ),    (* Resource is in .EXE file *)
    ID_WINDOW,       (* Frame window identifier *)
    hwndClient       (* Client window handle *)
  );
  IF hwndFrame = 0 THEN
    AbortHello( hwndFrame, hwndClient );
  END;

  ok := WinSetWindowText( hwndFrame, "HELLO SAMPLE" );

  (* Show and activate frame window at pos. 100,100 and size 200,200. *)
  ok := WinSetWindowPos
  ( hwndFrame,
    HWND_TOP,
    100, 100, 200, 200,
    SWP_SIZE OR SWP_MOVE OR SWP_ACTIVATE OR SWP_SHOW
  );
  IF NOT ok THEN
    AbortHello( hwndFrame, hwndClient );
  END;
  (*DosExit( EXIT_PROCESS, 0 );*)

  (* Get and dispatch messages from the application message queue *)
  (* until WinGetMsg returns FALSE, indicating a WM_QUIT message. *)

  WHILE WinGetMsg( hab, qmsg, 0, 0, 0 ) DO
    b4 := WinDispatchMsg( hab, qmsg );
  END;

  (* Tidy up and terminate the application *)
  ok := WinDestroyWindow( hwndFrame );
  ok := WinDestroyMsgQueue( hmq );
  ok := WinTerminate( hab );

END HELLO.
