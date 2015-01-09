/*************************************************************************
   MOD.H      Common resource compiler definitions for Modula-2
              Last update: 19.08.95 21.35

   Copyright (c) 1995 by Juergen Neuhoff
**************************************************************************/

#ifndef _MOD_H_INCLUDED
#define _MOD_H_INCLUDED 1


/* Menu item styles & attributes.
   Note: In multiple choice submenus a style of 'MIS_SINGLE' denotes 
         the item is a radiobutton.  Absence of this style defaults 
         the item to a checkbox.       
*/

#define MIS_TEXT                   0x0001
#define MIS_BITMAP                 0x0002
#define MIS_SEPARATOR              0x0004
#define MIS_OWNERDRAW              0x0008
#define MIS_SUBMENU                0x0010
#define MIS_MULTMENU               0x0020    /* multiple choice submenu     */
#define MIS_SYSCOMMAND             0x0040
#define MIS_HELP                   0x0080
#define MIS_STATIC                 0x0100
#define MIS_BUTTONSEPARATOR        0x0200
#define MIS_BREAK                  0x0400
#define MIS_BREAKSEPARATOR         0x0800
#define MIS_GROUP                  0x1000    /* multiple choice group start */
#define MIS_SINGLE                 0x2000



#define MIA_NODISMISS              0x0020
#define MIA_FRAMED                 0x1000
#define MIA_CHECKED                0x2000
#define MIA_DISABLED               0x4000
#define MIA_HILITED                0x8000



/* Frame window styles */
/* All unused FCF_xxx bits are reserved */

#define FCF_TITLEBAR               0x00000001L
#define FCF_SYSMENU                0x00000002L
#define FCF_MENU                   0x00000004L
#define FCF_SIZEBORDER             0x00000008L
#define FCF_MINBUTTON              0x00000010L
#define FCF_MAXBUTTON              0x00000020L
#define FCF_MINMAX                 0x00000030L /* minmax means BOTH buttons */
#define FCF_VERTSCROLL             0x00000040L
#define FCF_HORZSCROLL             0x00000080L
#define FCF_DLGBORDER              0x00000100L
#define FCF_BORDER                 0x00000200L
#define FCF_SHELLPOSITION          0x00000400L
#define FCF_TASKLIST               0x00000800L
#define FCF_NOBYTEALIGN            0x00001000L
#define FCF_NOMOVEWITHOWNER        0x00002000L
#define FCF_ICON                   0x00004000L
#define FCF_ACCELTABLE             0x00008000L
#define FCF_SYSMODAL               0x00010000L
#define FCF_SCREENALIGN            0x00020000L
#define FCF_MOUSEALIGN             0x00040000L
#define FCF_HIDEBUTTON             0x01000000L
#define FCF_HIDEMAX                0x01000020L /* hidemax means BOTH buttons */
#define FCF_DBE_APPSTAT            0x80000000L
#define FCF_AUTOICON               0x40000000L
#define FCF_STANDARD               0x0000CC3FL



/* frame styles */

#define FS_ICON                    0x00000001L
#define FS_ACCELTABLE              0x00000002L
#define FS_SHELLPOSITION           0x00000004L
#define FS_TASKLIST                0x00000008L
#define FS_NOBYTEALIGN             0x00000010L
#define FS_NOMOVEWITHOWNER         0x00000020L
#define FS_SYSMODAL                0x00000040L
#define FS_DLGBORDER               0x00000080L
#define FS_BORDER                  0x00000100L
#define FS_SCREENALIGN             0x00000200L
#define FS_MOUSEALIGN              0x00000400L
#define FS_SIZEBORDER              0x00000800L
#define FS_AUTOICON                0x00001000L
#define FS_DBE_APPSTAT             0x00008000L
#define FS_STANDARD                0x0000000FL



/* Standard Window Styles */

#define WS_VISIBLE                 0x80000000L
#define WS_DISABLED                0x40000000L
#define WS_CLIPCHILDREN            0x20000000L
#define WS_CLIPSIBLINGS            0x10000000L
#define WS_PARENTCLIP              0x08000000L
#define WS_SAVEBITS                0x04000000L
#define WS_SYNCPAINT               0x02000000L
#define WS_MINIMIZED               0x01000000L
#define WS_MAXIMIZED               0x00800000L
#define WS_ANIMATE                 0x00400000L



/* Dialog manager styles */

#define WS_GROUP                   0x00010000L
#define WS_TABSTOP                 0x00020000L
#define WS_MULTISELECT             0x00040000L



/* Standard Window Classes */

typedef unsigned char *PSZ;
#define WC_FRAME             ((PSZ)0xffff0001L)
#define WC_COMBOBOX          ((PSZ)0xffff0002L)
#define WC_BUTTON            ((PSZ)0xffff0003L)
#define WC_MENU              ((PSZ)0xffff0004L)
#define WC_STATIC            ((PSZ)0xffff0005L)
#define WC_ENTRYFIELD        ((PSZ)0xffff0006L)
#define WC_LISTBOX           ((PSZ)0xffff0007L)
#define WC_SCROLLBAR         ((PSZ)0xffff0008L)
#define WC_TITLEBAR          ((PSZ)0xffff0009L)
#define WC_MLE               ((PSZ)0xffff000AL)
/* 000B to 000F reserved */
#define WC_APPSTAT           ((PSZ)0xffff0010L)
#define WC_KBDSTAT           ((PSZ)0xffff0011L)
#define WC_PECIC             ((PSZ)0xffff0012L)
#define WC_DBE_KKPOPUP       ((PSZ)0xffff0013L)
/* 0014 to 001F reserved */
#define WC_SPINBUTTON        ((PSZ)0xffff0020L)
/* 0021 to 0024 reserved */
#define WC_CONTAINER         ((PSZ)0xffff0025L)
#define WC_SLIDER            ((PSZ)0xffff0026L)
#define WC_VALUESET          ((PSZ)0xffff0027L)
#define WC_NOTEBOOK          ((PSZ)0xffff0028L)
/* 0029 to 002C used by PEN */
#define WC_PENFIRST          ((PSZ)0xffff0029L)
#define WC_PENLAST           ((PSZ)0xffff002CL)
/* 002D to 0030 reserved */
/* 0030 to 003F reserved */
#define WC_MMPMFIRST         ((PSZ)0xffff0040L)
#define WC_MMPMLAST          ((PSZ)0xffff004fL)



/* SPINBUTTON Creation Flags : Character Acceptance */

#define SPBS_ALLCHARACTERS 0x00000000L /* Default: All chars accepted  */
#define SPBS_NUMERICONLY   0x00000001L /* Only 0 - 9 accepted & VKeys  */
#define SPBS_READONLY      0x00000002L /* No chars allowed in entryfld */



/* SPINBUTTON Creation Flags : Type of Component */

#define SPBS_MASTER        0x00000010L
#define SPBS_SERVANT       0x00000000L /* Default: Servant            */



/* SPINBUTTON Creation Flags : Type of Justification */

#define SPBS_JUSTDEFAULT  0x00000000L /* Default: Same as Left        */
#define SPBS_JUSTLEFT     0x00000008L
#define SPBS_JUSTRIGHT    0x00000004L
#define SPBS_JUSTCENTER   0x0000000CL



/* SPINBUTTON Creation Flags :  Border or not */

#define SPBS_NOBORDER     0x00000020L /* Borderless SpinField         */
                                      /* Default is to have a border. */


/* SPINBUTTON Creation Flags : Fast spin or not */

#define SPBS_FASTSPIN     0x00000100L /* Allow fast spinning.  Fast   */
                                      /* spinning is performed by     */
                                      /* skipping over numbers        */



/* SPINBUTTON Creation Flags : Pad numbers on front with 0's */

#define SPBS_PADWITHZEROS 0x00000080L /* Pad the number with zeroes   */



/* Virtual key values */

#define VK_BUTTON1                 0x01
#define VK_BUTTON2                 0x02
#define VK_BUTTON3                 0x03
#define VK_BREAK                   0x04
#define VK_BACKSPACE               0x05
#define VK_TAB                     0x06
#define VK_BACKTAB                 0x07
#define VK_NEWLINE                 0x08
#define VK_SHIFT                   0x09
#define VK_CTRL                    0x0A
#define VK_ALT                     0x0B
#define VK_ALTGRAF                 0x0C
#define VK_PAUSE                   0x0D
#define VK_CAPSLOCK                0x0E
#define VK_ESC                     0x0F
#define VK_SPACE                   0x10
#define VK_PAGEUP                  0x11
#define VK_PAGEDOWN                0x12
#define VK_END                     0x13
#define VK_HOME                    0x14
#define VK_LEFT                    0x15
#define VK_UP                      0x16
#define VK_RIGHT                   0x17
#define VK_DOWN                    0x18
#define VK_PRINTSCRN               0x19
#define VK_INSERT                  0x1A
#define VK_DELETE                  0x1B
#define VK_SCRLLOCK                0x1C
#define VK_NUMLOCK                 0x1D
#define VK_ENTER                   0x1E
#define VK_SYSRQ                   0x1F
#define VK_F1                      0x20
#define VK_F2                      0x21
#define VK_F3                      0x22
#define VK_F4                      0x23
#define VK_F5                      0x24
#define VK_F6                      0x25
#define VK_F7                      0x26
#define VK_F8                      0x27
#define VK_F9                      0x28
#define VK_F10                     0x29
#define VK_F11                     0x2A
#define VK_F12                     0x2B
#define VK_F13                     0x2C
#define VK_F14                     0x2D
#define VK_F15                     0x2E
#define VK_F16                     0x2F
#define VK_F17                     0x30
#define VK_F18                     0x31
#define VK_F19                     0x32
#define VK_F20                     0x33
#define VK_F21                     0x34
#define VK_F22                     0x35
#define VK_F23                     0x36
#define VK_F24                     0x37
#define VK_ENDDRAG                 0x38
#define VK_CLEAR                   0x39
#define VK_EREOF                   0x3A
#define VK_PA1                     0x3B
#define VK_MENU                    VK_F10
#define VK_DBCSFIRST               0x0080
#define VK_DBCSLAST                0x00ff
#define VK_USERFIRST               0x0100
#define VK_USERLAST                0x01ff


/* Button control styles */

#define BS_PUSHBUTTON              0L
#define BS_CHECKBOX                1L
#define BS_AUTOCHECKBOX            2L
#define BS_RADIOBUTTON             3L
#define BS_AUTORADIOBUTTON         4L
#define BS_3STATE                  5L
#define BS_AUTO3STATE              6L
#define BS_USERBUTTON              7L
#define BS_PRIMARYSTYLES           0x000fL
#define BS_BITMAP                  0x0040L
#define BS_ICON                    0x0080L
#define BS_HELP                    0x0100L
#define BS_SYSCOMMAND              0x0200L
#define BS_DEFAULT                 0x0400L
#define BS_NOPOINTERFOCUS          0x0800L
#define BS_NOBORDER                0x1000L
#define BS_NOCURSORSELECT          0x2000L
#define BS_AUTOSIZE                0x4000L



/* List box styles */

#define LS_MULTIPLESEL             0x00000001L
#define LS_OWNERDRAW               0x00000002L
#define LS_NOADJUSTPOS             0x00000004L
#define LS_HORZSCROLL              0x00000008L
#define LS_EXTENDEDSEL             0x00000010L


#endif /* _MOD_H_INCLUDED */
