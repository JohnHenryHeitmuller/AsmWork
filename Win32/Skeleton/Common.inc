        TITLE   Common
        OPTION  CASEMAP:NONE

        .386                ; 32-Bit when .386 before .MODEL
        .MODEL  FLAT, STDCALL

        INCLUDE WindowsA.inc

;--------------------------------------------------------------------;
;   Resource.rc                                                      ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
IDI_ICON        EQU 01h     ; Resource IDs
IDM_MENU        EQU 02h
IDA_ACCEL       EQU 03h
IDD_ABOUT       EQU 04h

IDS_SYSMENU     EQU 10h     ; System Menu ID
IDM_FILEMENU    EQU 11h     ; Menu IDs
IDM_HELPMENU    EQU 12h

IDM_NEW         EQU 20h     ; File Menu Command IDs
IDM_OPEN        EQU 21h
IDM_SAVE        EQU 22h
IDM_SAVEAS      EQU 23h
IDM_EXIT        EQU 24h
IDM_HELPTOPICS  EQU 25h     ; Help Menu Command IDs
IDM_ABOUT       EQU 26h

;--------------------------------------------------------------------;
;   WinMain.asm                                                      ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
EXTERNDEF       hInst:HINSTANCE
EXTERNDEF       lpCmdLine:LPSTR
EXTERNDEF       hMainWnd:HWND
EXTERNDEF       szClassName:SBYTE
EXTERNDEF       szWindowName:SBYTE

;--------------------------------------------------------------------;
;   WndProc.asm                                                      ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
WndProc         PROTO   STDCALL :HWND, :UINT, :WPARAM, :LPARAM

;--------------------------------------------------------------------;
;   Msg.asm                                                          ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MsgWM_PAINT     PROTO   STDCALL
MsgWM_CREATE    PROTO   STDCALL
MsgWM_CLOSE     PROTO   STDCALL
MsgWM_SIZE      PROTO   STDCALL

;--------------------------------------------------------------------;
;   CmdFile.asm                                                      ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
NAMEDbit        EQU     1h  ; fFileStatus 0=NoChanges 1=Changed
CHANGEDbit      EQU     2h  ; fFileStatus 0=NeedsName 1=Named
CmdIDM_NEW      PROTO   STDCALL
CmdIDM_OPEN     PROTO   STDCALL
CmdIDM_SAVE     PROTO   STDCALL
SaveChanges     PROTO   STDCALL
EXTERNDEF       fFileStatus:DWORD

;--------------------------------------------------------------------;
;   Statbar.asm                                                      ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
ID_STATUSBAR        EQU     0F0h
CreateSBar          PROTO   STDCALL
MsgWM_MENUSELECT    PROTO   STDCALL
EXTERNDEF           hStatusBar:HWND

;--------------------------------------------------------------------;
;   ToolBar.asm                                                      ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
ID_TOOLBAR      EQU 0F1h
CreateTBar      PROTO   STDCALL
NtfTTN_NEEDTEXT PROTO   STDCALL
EXTERNDEF       hToolBar:HWND

;--------------------------------------------------------------------;
;   Misc.asm                                                         ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MiscCenterWnd   PROTO   STDCALL :HWND, :HWND

;--------------------------------------------------------------------;
;   About.asm                                                        ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
About       PROTO   STDCALL :HWND, :UINT, :WPARAM, :LPARAM
