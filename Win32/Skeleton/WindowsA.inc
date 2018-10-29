;*******************************************************************************
;*    WindowsA.inc contains a very small ASCII (non-UNICODE) subset of the     *
;* Win32 API Constants, Type Definitions, Structures, and Function Prototypes  *
;*        converted from the MICROSOFT Win32 SDK C header file format to       *
;* the MICROSOFT MASM 6.11d include file format for assembly language programs *
;*******************************************************************************


;*******************************************************************************
;*          WINDEF.H                    ****************************************
;*******************************************************************************

MAX_PATH    EQU     0104h

NULL        EQU     0h
FALSE       EQU     0h
TRUE        EQU     1h

CALLBACK    TYPEDEF PROTO   STDCALL
WINAPI      TYPEDEF PROTO   STDCALL

BOOL        TYPEDEF SDWORD
LPBYTE      TYPEDEF PTR BYTE
LPDWORD     TYPEDEF PTR DWORD
LPVOID      TYPEDEF PTR
LPCVOID     TYPEDEF PTR

UINT        TYPEDEF DWORD
LONG        TYPEDEF DWORD

WPARAM      TYPEDEF UINT
LPARAM      TYPEDEF DWORD

HANDLE      TYPEDEF DWORD
HWND        TYPEDEF DWORD
HGLOBAL     TYPEDEF DWORD
HGDIOBJ     TYPEDEF DWORD
HACCEL      TYPEDEF DWORD
HBITMAP     TYPEDEF DWORD
HBRUSH      TYPEDEF DWORD
HDC         TYPEDEF DWORD
HFONT       TYPEDEF DWORD
HICON       TYPEDEF DWORD
HMENU       TYPEDEF DWORD
HINSTANCE   TYPEDEF DWORD
HRGN        TYPEDEF DWORD
HRSRC       TYPEDEF DWORD
HCURSOR     TYPEDEF DWORD
COLORREF    TYPEDEF DWORD

RECT        STRUCT
    left    LONG    ?
    top     LONG    ?
    right   LONG    ?
    bottom  LONG    ?
RECT        ENDS
LPRECT      TYPEDEF PTR RECT

POINT       STRUCT
    x   LONG    ?
    y   LONG    ?
POINT       ENDS
LPPOINT     TYPEDEF PTR POINT


;*******************************************************************************
;*          WINNT.H                     ****************************************
;*******************************************************************************

LPSTR       TYPEDEF DWORD
LPCSTR      TYPEDEF DWORD

FILE_ATTRIBUTE_READONLY     EQU     0001h
FILE_ATTRIBUTE_HIDDEN       EQU     0002h
FILE_ATTRIBUTE_SYSTEM       EQU     0004h
FILE_ATTRIBUTE_DIRECTORY    EQU     0010h
FILE_ATTRIBUTE_ARCHIVE      EQU     0020h
FILE_ATTRIBUTE_NORMAL       EQU     0080h
FILE_ATTRIBUTE_TEMPORARY    EQU     0100h
FILE_ATTRIBUTE_COMPRESSED   EQU     0800h

GENERIC_READ        EQU     080000000h
GENERIC_WRITE       EQU     040000000h
GENERIC_EXECUTE     EQU     020000000h
GENERIC_ALL         EQU     010000000h

DLL_PROCESS_ATTACH  EQU     01h
DLL_THREAD_ATTACH   EQU     02h
DLL_THREAD_DETACH   EQU     03h
DLL_PROCESS_DETACH  EQU     00h

RtlMoveMemory       PROTO   STDCALL :DWORD, :DWORD, :DWORD
MoveMemory          TEXTEQU <RtlMoveMemory>
RtlFillMemory       PROTO   STDCALL :DWORD, :DWORD, :BYTE
FillMemory          TEXTEQU <RtlFillMemory>

;*******************************************************************************
;*          WINERROR.H                  ****************************************
;*******************************************************************************

ERROR_SUCCESS           EQU     000h
ERROR_INVALID_HANDLE    EQU     006h
ERROR_ALREADY_EXISTS    EQU     0B7h


;*******************************************************************************
;*  KERNEL32.LIB    WINBASE.H           ****************************************
;*******************************************************************************

INVALID_HANDLE_VALUE    EQU     -1

CREATE_NEW              EQU     01h
CREATE_ALWAYS           EQU     02h
OPEN_EXISTING           EQU     03h
OPEN_ALWAYS             EQU     04h
TRUNCATE_EXISTING       EQU     05h

OVERLAPPED      STRUCT
    Internal        DWORD   ?
    InternalHigh    DWORD   ?
    _Offset         DWORD   ?
    OffsetHigh      DWORD   ?
    hEvent          HANDLE  ?
OVERLAPPED      ENDS
LPOVERLAPPED        TYPEDEF PTR OVERLAPPED

SECURITY_ATTRIBUTES STRUCT
    nLength                 DWORD   ?
    lpSecurityDescriptor    LPVOID  ?
    bInheritHandle          BOOL    ?
SECURITY_ATTRIBUTES ENDS
LPSECURITY_ATTRIBUTES   TYPEDEF PTR SECURITY_ATTRIBUTES

PROCESS_INFORMATION STRUCT
    hProcess        HANDLE  ?
    hThread         HANDLE  ?
    dwProcessID     DWORD   ?
    dwThreadID      DWORD   ?
PROCESS_INFORMATION ENDS
LPPROCESS_INFORMATION   TYPEDEF PTR PROCESS_INFORMATION

GMEM_FIXED      EQU 00000h
GMEM_MOVEABLE       EQU 00002h
GMEM_ZEROINIT       EQU 00040h
GMEM_SHARE      EQU 02000h

DEBUG_PROCESS       EQU 001h
DEBUG_ONLY_THIS_PROCESS EQU 002h
CREATE_SUSPENDED    EQU 004h
DETACHED_PROCESS    EQU 008h
CREATE_NEWE_CONSOLE EQU 010h
NORMAL_PRIORITY_CLASS   EQU 020h

WinMain         PROTO   WINAPI  :HINSTANCE, :HINSTANCE, :LPSTR, :SDWORD
GlobalAlloc     PROTO   WINAPI  :UINT, :DWORD
GlobalLock      PROTO   WINAPI  :HGLOBAL
GlobalUnlock        PROTO   WINAPI  :HGLOBAL
GlobalFree      PROTO   WINAPI  :HGLOBAL
ExitProcess     PROTO   WINAPI  :DWORD
GetLastError        PROTO   WINAPI
DebugBreak      PROTO   WINAPI
Sleep           PROTO   WINAPI  :DWORD
LoadResource        PROTO   WINAPI  :HINSTANCE, :HRSRC
GetFileSize     PROTO   WINAPI  :HANDLE, :LPDWORD
WriteFile       PROTO   WINAPI  :HANDLE, :LPCVOID, :DWORD, :LPDWORD, :LPOVERLAPPED
ReadFile        PROTO   WINAPI  :HANDLE, :LPVOID, :DWORD, :LPDWORD, :LPOVERLAPPED
CloseHandle     PROTO   WINAPI  :HANDLE
Beep            PROTO   WINAPI  :DWORD, :DWORD
lstrlenA        PROTO   WINAPI  :LPCSTR
lstrlen         TEXTEQU <lstrlenA>

STARTF_USESHOWWINDOW    EQU 0001h
STARTF_USESIZE      EQU 0002h
STARTF_USEPOSITION  EQU 0004h
STARTF_USECOUNTCHARS    EQU 0008h
STARTF_USEFILLATTRIBUTE EQU 0010h
STARTF_RUNFULLSCREEN    EQU 0020h
STARTF_FORCEONFEEDBACK  EQU 0040h
STARTF_FORCEOFFFEEDBACK EQU 0080h
STARTF_USESTDHANDLES    EQU 0100h
STARTF_USEHOTKEY    EQU 0200h

STARTUPINFOA        STRUCT
    cb      DWORD       ?
    lpReserved  LPSTR       ?
    lpDesktop   LPSTR       ?
    lpTitle     LPSTR       ?
    dwX     DWORD       ?
    dwY     DWORD       ?
    dwXSize     DWORD       ?
    dwYSize     DWORD       ?
    dwXCountChars   DWORD       ?
    dwYCountChars   DWORD       ?
    dwFillAttribute DWORD       ?
    dwFlags     DWORD       ?
    wShowWindow WORD        ?
    cbReserved2 WORD        ?
    lpReserved2 LPBYTE      ?
    hStdInput   HANDLE      ?
    hStdOutput  HANDLE      ?
    hStdError   HANDLE      ?
STARTUPINFOA        ENDS
LPSTARTUPINFO       TYPEDEF PTR STARTUPINFOA
STARTUPINFO     TEXTEQU <STARTUPINFOA>

CreateSemaphoreA    PROTO   WINAPI  :LPSECURITY_ATTRIBUTES, :LONG, :LONG, :LPCSTR
CreateSemaphore     TEXTEQU <CreateSemaphoreA>

GetModuleHandleA    PROTO   WINAPI  :DWORD
GetModuleHandle     TEXTEQU <GetModuleHandleA>
CreateProcessA      PROTO   STDCALL :LPCSTR, :LPSTR,\
                    :LPSECURITY_ATTRIBUTES,\
                    :LPSECURITY_ATTRIBUTES,\
                    :BOOL, :DWORD, :LPVOID, :LPCSTR,\
                    :LPSTARTUPINFO,\
                    :LPPROCESS_INFORMATION
CreateProcess       TEXTEQU <CreateProcessA>
GetStartupInfoA     PROTO   WINAPI  :LPSTARTUPINFO
GetStartupInfo      TEXTEQU <GetStartupInfoA>
GetCommandLineA     PROTO   WINAPI
GetCommandLine      TEXTEQU <GetCommandLineA>
OutputDebugStringA  PROTO   WINAPI  :LPCSTR
OutputDebugString   TEXTEQU <OutputDebugStringA>
FindResourceA       PROTO   WINAPI  :HINSTANCE, :LPCSTR, :LPCSTR
FindResource        TEXTEQU <FindResourceA>
CreateFileA     PROTO   WINAPI  :LPCSTR, :DWORD, :DWORD,\
                    :LPSECURITY_ATTRIBUTES,\
                    :DWORD, :DWORD, :HANDLE
CreateFile      TEXTEQU <CreateFileA>
QueryPerformanceCounter PROTO   WINAPI  :DWORD
QueryPerformanceFrequency PROTO WINAPI  :DWORD


;*******************************************************************************
;*  GDI32.LIB   WINGDI.H    ****************************************
;*******************************************************************************

SRCCOPY         EQU 00CC0020h   ;dest = source
SRCPAINT        EQU 00EE0086h   ;dest = source OR dest
SRCAND          EQU 008800C6h   ;dest = source AND dest
SRCINVERT       EQU 00660046h   ;dest = source XOR dest
SRCERASE        EQU 00440328h   ;dest = source AND (NOT dest)

TA_LEFT         EQU 000h
TA_RIGHT        EQU 002h
TA_CENTER       EQU 006h
TA_TOP          EQU 000h
TA_BOTTOM       EQU 008h
TA_BASELINE     EQU 018h

SP_ERROR        EQU -1

BITMAP          STRUCT
    bmType      LONG        ?
    bmWidth     LONG        ?
    bmHeight    LONG        ?
    bmWidthBytes    LONG        ?
    bmPlanes    WORD        ?
    bmBitsPixel WORD        ?
    bmBits      LPVOID      ?
BITMAP          ENDS

DRAFT_QUALITY       EQU 002h
PROOF_QUALITY       EQU 003h
FIXED_PITCH     EQU 001h
VARIABLE_PITCH      EQU 002h
FW_NORMAL       EQU 400
FW_BOLD         EQU 700
FF_ROMAN        EQU 010h
FF_MODERN       EQU 030h

TRANSPARENT     EQU 01h
OPAQUE          EQU 02h

WHITE_BRUSH     EQU 00h
LTGRAY_BRUSH        EQU 01h
GRAY_BRUSH      EQU 02h
DKGRAY_BRUSH        EQU 03h
BLACK_BRUSH     EQU 04h

BitBlt          PROTO   WINAPI  :HDC, :DWORD, :DWORD, :DWORD, :DWORD,\
                    :HDC, :DWORD, :DWORD, :DWORD
CreateCompatibleDC  PROTO   WINAPI  :HDC
CreateFontA     PROTO   WINAPI  :SDWORD, :SDWORD, :SDWORD, :SDWORD, :SDWORD, :DWORD, :DWORD,\
                    :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :LPCSTR
CreateFont      TEXTEQU <CreateFontA>
CreateSolidBrush    PROTO   WINAPI  :COLORREF
DeleteDC        PROTO   WINAPI  :HDC
DeleteObject        PROTO   WINAPI  :HGDIOBJ
GetStockObject      PROTO   WINAPI  :SDWORD
LineTo          PROTO   WINAPI  :HDC, :UINT, :UINT
RectVisible     PROTO   WINAPI  :HDC, :LPRECT
SelectObject        PROTO   WINAPI  :HDC, :HGDIOBJ
SetBkColor      PROTO   WINAPI  :HDC, :COLORREF
SetBkMode       PROTO   WINAPI  :HDC, :SDWORD
StretchBlt      PROTO   WINAPI  :HDC, :SDWORD, :SDWORD, :SDWORD, :SDWORD,\
                    :HDC, :SDWORD, :SDWORD, :SDWORD, :SDWORD, :DWORD
SetTextColor        PROTO   WINAPI  :HDC, :COLORREF
SetTextAlign        PROTO   WINAPI  :HDC, :UINT

ABORTPROC       TYPEDEF PROTO STDCALL

DOCINFOA        STRUCT
    cbSize      SDWORD  ?
    lpszDocName LPCSTR  ?
    lpszOutput  LPCSTR  ?
    lpszDataType    LPCSTR  ?
    fwType      DWORD   ?
DOCINFOA        ENDS
LPDOCINFO       TYPEDEF PTR DOCINFOA
DOCINFO         TEXTEQU <DOCINFOA>

StartDocA       PROTO   WINAPI  :HDC, :LPDOCINFO
StartDoc        TEXTEQU <StartDocA>
EndDoc          PROTO   WINAPI  :HDC
StartPage       PROTO   WINAPI  :HDC
EndPage         PROTO   WINAPI  :HDC
AbortDoc        PROTO   WINAPI  :HDC
SetAbortProc        PROTO   WINAPI  :HDC, :ABORTPROC

MoveToEx        PROTO   WINAPI  :HDC, :UINT, :UINT, :LPPOINT
TextOutA        PROTO   WINAPI  :HDC, :DWORD, :DWORD, :LPCSTR, :DWORD
TextOut         TEXTEQU <TextOutA>


;*******************************************************************************
;*  USER32.LIB  WINUSER.H   ****************************************
;*******************************************************************************

DLGPROC     TYPEDEF PROTO STDCALL

SB_HORZ         EQU 0
SB_VERT         EQU 1
SB_CTL          EQU 2
SB_BOTH         EQU 3
SB_THUMBPOSITION    EQU 4
SB_ENDSCROLL        EQU 8

SW_HIDE         EQU 00h
SW_SHOWNORMAL       EQU 01h
SW_SHOWMINIMIZED    EQU 02h
SW_SHOWMAXIMIZED    EQU 03h
SW_SHOW         EQU 05h
SW_RESTORE      EQU 09h
SW_SHOWDEFAULT      EQU 0Ah

WNDCLASSEXA     STRUCT
    cbSize      UINT        ?
    style       UINT        ?
    lpfnWndProc DWORD       ?
    cbClsExtra  SDWORD      ?
    cbWndExtra  SDWORD      ?
    hInstance   HINSTANCE   ?
    hIcon       HICON       ?
    hCursor     HCURSOR     ?
    hbrBackground   HBRUSH      ?
    lpszMenuName    LPCSTR      ?
    lpszClassName   LPCSTR      ?
    hIconSm     HICON       ?
WNDCLASSEXA     ENDS
WNDCLASSEX      TEXTEQU <WNDCLASSEXA>

MSG         STRUCT
    hwnd        HWND    ?
    message     UINT    ?
    wParam      WPARAM  ?
    lParam      LPARAM  ?
    time        DWORD   ?
    pt      POINT   <>
MSG         ENDS
LPMSG           TYPEDEF DWORD

GWL_ID          EQU 0FFFFFFF4h

WM_CREATE       EQU 0001h
WM_DESTROY      EQU 0002h
WM_SIZE         EQU 0005h
WM_SETTEXT      EQU 000Ch
WM_PAINT        EQU 000Fh
WM_CLOSE        EQU 0010h
WM_ERASEBKGND       EQU 0014h
WM_NOTIFY       EQU 004Eh
WM_HELP         EQU 0053h
WM_CHAR         EQU 0102h
WM_INITDIALOG       EQU 0110h
WM_COMMAND      EQU 0111h
WM_TIMER        EQU 0113h
WM_HSCROLL      EQU 0114h
WM_VSCROLL      EQU 0115h
WM_MENUSELECT       EQU 011Fh
WM_CTLCOLORDLG      EQU 0136h
WM_MOUSEMOVE        EQU 0200h
WM_LBUTTONDOWN      EQU 0201h
WM_LBUTTONUP        EQU 0202h
WM_LBUTTONDBLCLK    EQU 0203h
WM_RBUTTONDOWN      EQU 0204h
WM_RBUTTONUP        EQU 0205h
WM_RBUTTONDBLCLK    EQU 0206h
WM_CUT          EQU 0300h
WM_COPY         EQU 0301h
WM_PASTE        EQU 0302h
WM_CLEAR        EQU 0303h
WM_UNDO         EQU 0304h
WM_USER         EQU 0400h

WS_POPUP        EQU 080000000h
WS_CHILD        EQU 040000000h
WS_MINIMIZE     EQU 020000000h
WS_VISIBLE      EQU 010000000h
WS_MAXIMIZE     EQU 001000000h
WS_CAPTION      EQU 000C00000h
WS_BORDER       EQU 000800000h
WS_DLGFRAME     EQU 000400000h
WS_VSCROLL      EQU 000200000h
WS_HSCROLL      EQU 000100000h
WS_SYSMENU      EQU 000080000h
WS_SIZEBOX      EQU 000040000h
WS_MINIMIZEBOX      EQU 000020000h
WS_MAXIMIZEBOX      EQU 000010000h
WS_OVERLAPPEDWINDOW EQU 000CF0000h
WS_EX_NOPARENTNOTIFY    EQU 000000004h
WS_EX_WINDOWEDGE    EQU 000000100h
WS_EX_CLIENTEDGE    EQU 000000200h
WS_EX_OVERLAPPEDWINDOW  EQU WS_EX_WINDOWEDGE + WS_EX_CLIENTEDGE

CS_VREDRAW      EQU 00001h
CS_HREDRAW      EQU 00002h
CS_PARENTDC     EQU 00080h
CS_BYTEALIGNWINDOW  EQU 02000h

BDR_RAISEDOUTER     EQU 01h
BDR_SUNKENOUTER     EQU 02h
BDR_RAISEDINNER     EQU 04h
BDR_SUNKENINNER     EQU 08h
EDGE_RAISED     EQU BDR_RAISEDOUTER + BDR_RAISEDINNER
EDGE_SUNKEN     EQU BDR_SUNKENOUTER + BDR_SUNKENINNER
EDGE_ETCHED     EQU BDR_SUNKENOUTER + BDR_RAISEDINNER
EDGE_BUMP       EQU BDR_RAISEDOUTER + BDR_SUNKENINNER
BF_LEFT         EQU 01h
BF_TOP          EQU 02h
BF_RIGHT        EQU 04h
BF_BOTTOM       EQU 08h
BF_RECT         EQU BF_LEFT + BF_TOP + BF_RIGHT + BF_BOTTOM
DrawEdge        PROTO   WINAPI  :HDC, :LPRECT, :UINT, :UINT

PAINTSTRUCT     STRUCT
    hdc     HDC ?
    fErase      BOOL    ?
    rcPaint     RECT    <>
    fRestore    BOOL    ?
    fIncUpdate  BOOL    ?
    rgbReserved BYTE    32 DUP (?)
PAINTSTRUCT     ENDS
LPPAINTSTRUCT       TYPEDEF PTR PAINTSTRUCT

NMHDR           STRUCT
    hwndFrom    HWND    ?
    idFrom      UINT    ?
    code        UINT    ?
NMHDR           ENDS

GetMessageA     PROTO   WINAPI  :LPMSG, :HWND, :UINT, :UINT
GetMessage      TEXTEQU <GetMessageA>
TranslateMessage    PROTO   WINAPI  :LPMSG
DispatchMessageA    PROTO   WINAPI  :LPMSG
DispatchMessage     TEXTEQU <DispatchMessageA>

PeekMessageA        PROTO   WINAPI  :LPMSG, :HWND, :UINT, :UINT, :UINT
PeekMessage     TEXTEQU <PeekMessageA>
PM_NOREMOVE     EQU 00h
PM_REMOVE       EQU 01h
PM_NOYIELD      EQU 02h

SendMessageA        PROTO   WINAPI  :HWND, :UINT, :WPARAM, :LPARAM
SendMessage     TEXTEQU <SendMessageA>
PostMessageA        PROTO   WINAPI  :HWND, :UINT, :WPARAM, :LPARAM
PostMessage     TEXTEQU <PostMessageA>
DefWindowProcA      PROTO   WINAPI  :HWND, :UINT, :WPARAM, :LPARAM
DefWindowProc       TEXTEQU <DefWindowProcA>
PostQuitMessage     PROTO   WINAPI  :SWORD
RegisterClassExA    PROTO   WINAPI  :DWORD
RegisterClassEx     TEXTEQU <RegisterClassExA>
CreateWindowExA     PROTO   WINAPI  :DWORD, :LPCSTR, :LPCSTR, :DWORD, :SDWORD, :SDWORD,\
                    :SDWORD, :SDWORD, :HWND, :HMENU, :HINSTANCE, :DWORD
CreateWindowEx      TEXTEQU <CreateWindowExA>
DestroyWindow       PROTO   WINAPI  :HWND
ShowWindow      PROTO   WINAPI  :HWND, :SDWORD
MoveWindow      PROTO   WINAPI  :HWND, :UINT, :UINT, :UINT, :UINT, :BOOL
SetWindowPos        PROTO   WINAPI  :HWND, :HWND, :UINT, :UINT, :UINT, :UINT, :UINT
IsIconic        PROTO   WINAPI  :HWND

SWP_NOSIZE      EQU 001h
SWP_NOMOVE      EQU 002h
SWP_NOZORDER        EQU 004h
SWP_FRAMECHANGED    EQU 020h
SWP_DRAWFRAME       EQU SWP_FRAMECHANGED
HWND_TOP        EQU 000h

DLGTEMPLATE     STRUCT
    style       DWORD   ?
    dwExtendedStyle DWORD   ?
    cdit        WORD    ?
    x       SWORD   ?
    y       SWORD   ?
    nx      SWORD   ?
    ny      SWORD   ?
DLGTEMPLATE     ENDS
LPCDLGTEMPLATE      TYPEDEF PTR LPDLGTEMPLATE

CreateDialogParamA  PROTO   WINAPI  :HINSTANCE, :LPCSTR, :HWND, :DLGPROC, :LPARAM
CreateDialogParam   TEXTEQU <CreateDialogParamA>
DialogBoxParamA     PROTO   WINAPI  :HINSTANCE, :LPCSTR, :HWND, :DLGPROC, :LPARAM
DialogBoxParam      TEXTEQU <DialogBoxParamA>
EndDialog       PROTO   WINAPI  :HWND, :UINT
GetDlgItem      PROTO   WINAPI  :HWND, :UINT
SetDlgItemTextA     PROTO   WINAPI  :HWND, :SDWORD, :LPCSTR
SetDlgItemText      TEXTEQU <SetDlgItemTextA>
SendDlgItemMessageA PROTO   WINAPI  :HWND, :UINT, :UINT, :WPARAM, :LPARAM
SendDlgItemMessage  TEXTEQU <SendDlgItemMessageA>
DefDlgProcA     PROTO   WINAPI  :HWND, :UINT, :WPARAM, :LPARAM
DefDlgProc      TEXTEQU <DefDlgProcA>
DLGWINDOWEXTRA      EQU 00000001Eh

SetFocus        PROTO   WINAPI  :HWND
SetTimer        PROTO   WINAPI  :HWND, :UINT, :UINT, :PTR DWORD
KillTimer       PROTO   WINAPI  :HWND, :UINT
EnableWindow        PROTO   WINAPI  :HWND, :BOOL
LoadAcceleratorsA   PROTO   WINAPI  :HINSTANCE, :LPCSTR
LoadAccelerators    TEXTEQU <LoadAcceleratorsA>
TranslateAcceleratorA   PROTO   WINAPI  :HWND, :HACCEL, :LPMSG
TranslateAccelerator    TEXTEQU <TranslateAcceleratorA>

SM_CXSCREEN     EQU 000h
SM_CYSCREEN     EQU 001h
SM_CXFULLSCREEN     EQU 010h
SM_CYFULLSCREEN     EQU 011h
GetSystemMetrics    PROTO   WINAPI  :UINT
DrawTextA       PROTO   WINAPI  :HDC, :LPCSTR, :UINT, :LPRECT, :UINT
DrawText        TEXTEQU <DrawTextA>
UpdateWindow        PROTO   WINAPI  :HWND
SetForegroundWindow PROTO   WINAPI  :HWND
GetDC           PROTO   WINAPI  :HWND
ReleaseDC       PROTO   WINAPI  :HWND, :HDC
BeginPaint      PROTO   WINAPI  :HWND, :LPPAINTSTRUCT
EndPaint        PROTO   WINAPI  :HWND, :LPPAINTSTRUCT
InvalidateRect      PROTO   WINAPI  :HWND, :LPRECT, :UINT
InvalidateRgn       PROTO   WINAPI  :HWND, :HRGN, :BOOL
GetScrollPos        PROTO   WINAPI  :HWND, :UINT
SetWindowTextA      PROTO   WINAPI  :HWND, :LPCSTR
SetWindowText       TEXTEQU <SetWindowTextA>
GetClientRect       PROTO   WINAPI  :HWND, :LPRECT
GetWindowRect       PROTO   WINAPI  :HWND, :LPRECT

MB_OK           EQU 000h
MB_OKCANCEL     EQU 001h
MB_ABORTRETRYIGNORE EQU 002h
MB_YESNOCANCEL      EQU 003h
MB_YESNO        EQU 004h
MB_RETRYCANCEL      EQU 005h
MB_ICONERROR        EQU 010h
MB_ICONWARNING      EQU 030h
MessageBoxA     PROTO   WINAPI  :HWND, :LPCSTR, :LPCSTR, :UINT
MessageBox      TEXTEQU <MessageBoxA>

COLOR_BACKGROUND    EQU 001h
COLOR_WINDOW        EQU 005h
COLOR_3DFACE        EQU 00Fh
COLOR_3DSHADOW      EQU 010h
COLOR_APPWORKSPACE  EQU 00Ch
COLOR_3DLIGHT       EQU 016h
GetSysColor     PROTO   WINAPI  :UINT
FillRect        PROTO   WINAPI  :HDC, :LPRECT, :HBRUSH
GetWindowLongA      PROTO   WINAPI  :HWND, :DWORD
GetWindowLong       TEXTEQU <GetWindowLongA>
GetDesktopWindow    PROTO   WINAPI
FindWindowA     PROTO   WINAPI  :LPCSTR, :LPCSTR
FindWindow      TEXTEQU <FindWindowA>
GetLastActivePopup  PROTO   WINAPI  :HWND

MF_POPUP        EQU 00010h
MF_SYSMENU      EQU 02000h
MFT_SEPARATOR       EQU 00800h

SC_SIZE         EQU 0F000h
SC_MOVE         EQU 0F010h
SC_MINIMIZE     EQU 0F020h
SC_MAXIMIZE     EQU 0F030h
SC_CLOSE        EQU 0F060h
SC_RESTORE      EQU 0F120h

LoadBitmapA     PROTO   WINAPI  :HINSTANCE, :LPCSTR
LoadBitmap      TEXTEQU <LoadBitmapA>
LoadCursorA     PROTO   WINAPI  :HINSTANCE, :LPCSTR
LoadCursor      TEXTEQU <LoadCursorA>
LoadIconA       PROTO   WINAPI  :HINSTANCE, :LPCSTR
LoadIcon        TEXTEQU <LoadIconA>

IMAGE_BITMAP        EQU 00000h
IMAGE_ICON      EQU 00001h
IMAGE_CURSOR        EQU 00002h
LR_LOADTRANSPARENT  EQU 00020h
LR_LOADMAP3DCOLORS  EQU 01000h
LoadImageA      PROTO   WINAPI  :HINSTANCE, :LPCSTR, :UINT, :UINT, :UINT, :UINT
LoadImage       TEXTEQU <LoadImageA>

IDC_ARROW       EQU 07f00h

LoadStringA     PROTO   WINAPI  :HINSTANCE, :UINT, :LPCSTR, :UINT
LoadString      TEXTEQU <LoadStringA>

IDOK            EQU 01h
IDCANCEL        EQU 02h
IDABORT         EQU 03h
IDRETRY         EQU 04h
IDIGNORE        EQU 05h
IDYES           EQU 06h
IDNO            EQU 07h
IDCLOSE         EQU 08h
IDHELP          EQU 09h

ES_LEFT         EQU 000h
ES_MULTILINE        EQU 004h
ES_AUTOVSCROLL      EQU 040h

BM_GETCHECK     EQU 0F0h
BM_SETCHECK     EQU 0F1h
BM_CLICK        EQU 0F5h
BM_SETIMAGE     EQU 0F7h

BST_UNCHECKED       EQU 00h
BST_CHECKED     EQU 01h
BST_INDETERMINATE   EQU 02h

SS_LEFT         EQU 00h
SS_CENTER       EQU 01h
SS_RIGHT        EQU 02h
SS_ICON         EQU 03h
SS_BLACKFRAME       EQU 07h

IsDialogMessageA    PROTO   WINAPI  :HWND, :LPMSG
IsDialogMessage     TEXTEQU <IsDialogMessageA>

DS_MODALFRAME       EQU 0080h
DS_NOIDLEMSG        EQU 0100h
DS_3DLOOK       EQU 0004h

HELP_CONTEXT        EQU 01h
HELP_QUIT       EQU 02h
HELP_INDEX      EQU 03h
HELP_CONTENTS       EQU 03h
HELP_HELPONHELP     EQU 04h
HELP_CONTEXTMENU    EQU 0Ah
HELP_FINDER     EQU 0Bh
HELP_WM_HELP        EQU 0Ch

WinHelpA        PROTO   WINAPI  :HWND, :LPCSTR, :UINT, :DWORD
WinHelp         TEXTEQU <WinHelpA>


;*******************************************************************************
;*  COMDLG32.LIB    COMMDLG.H   ****************************************
;*******************************************************************************

OPENFILENAMEA       STRUCT
    lStructSize DWORD       ?
    hwndOwner   HWND        ?
    hInstance   HINSTANCE   ?
    lpstrFilter LPCSTR      ?
    lpstrCustomFilter LPSTR     ?
    nMaxCustFilter  DWORD       ?
    nFilterIndex    DWORD       ?
    lpstrFile   LPSTR       ?
    nMaxFile    DWORD       ?
    lpstrFileTitle  LPSTR       ?
    nMaxFileTitle   DWORD       ?
    lpstrInitialDir LPCSTR      ?
    lpstrTitle  LPCSTR      ?
    Flags       DWORD       ?
    nFileOffset WORD        ?
    nFileExtension  WORD        ?
    lpstrDefExt LPCSTR      ?
    lCustData   LPARAM      ?
    lpfnHook    DWORD       ?
    lpTemplateName  LPCSTR      ?
OPENFILENAMEA       ENDS
LPOPENFILENAME      TYPEDEF PTR OPENFILENAMEA
OPENFILENAME        TEXTEQU <OPENFILENAMEA>

GetOpenFileNameA    PROTO   WINAPI  :LPOPENFILENAME
GetOpenFileName     TEXTEQU <GetOpenFileNameA>
GetSaveFileNameA    PROTO   WINAPI  :LPOPENFILENAME
GetSaveFileName     TEXTEQU <GetSaveFileNameA>

OFN_READONLY        EQU 00000001h
OFN_OVERWRITEPROMPT EQU 00000002h
OFN_HIDEREADONLY    EQU 00000004h
OFN_NOCHANGEDIR     EQU 00000008h
OFN_SHOWHELP        EQU 00000010h
OFN_ENABLEHOOK      EQU 00000020h
OFN_ENABLETEMPLATE  EQU 00000040h
OFN_ENABLETEMPLATEHANDLE EQU    00000080h
OFN_NOVALIDATE      EQU 00000100h
OFN_ALLOWMULTISELECT    EQU 00000200h
OFN_EXTENSIONDIFFERENT  EQU 00000400h
OFN_PATHMUSTEXIST   EQU 00000800h
OFN_FILEMUSTEXIST   EQU 00001000h
OFN_CREATEPROMPT    EQU 00002000h
OFN_SHAREAWARE      EQU 00004000h
OFN_NOREADONLYRETURN    EQU 00008000h
OFN_NOTESTFILECREATE    EQU 00010000h
OFN_NONETWORKBUTTON EQU 00020000h
OFN_NOLONGNAMES     EQU 00040000h
OFN_EXPLORER        EQU 00080000h
OFN_NODEREFERENCELINKS  EQU 00100000h
OFN_LONGNAMES       EQU 00200000h

PRINTDLGA       STRUCT
    lStructSize DWORD   ?
    hwndOwner   HWND    ?
    hDevMode    HGLOBAL ?
    hDevNames   HGLOBAL ?
    hDC     HDC ?
    Flags       DWORD   ?
    nFromPage   WORD    ?
    nToPage     WORD    ?
    nMinPage    WORD    ?
    nMaxPage    WORD    ?
    nCopies     WORD    ?
    hInstance   HINSTANCE ?
    lCustData   DWORD   ?
    lpfnPrintHook   DWORD   ?
    lpfnSetupHook   DWORD   ?
    lpPrintTemplateName LPCSTR ?
    lpSetupTemplateName LPCSTR ?
    hPrintTemplate  HGLOBAL ?
    hSetupTemplate  HGLOBAL ?
PRINTDLGA       ENDS
LPPRINTDLG      TYPEDEF PTR PRINTDLGA
PRINTDLG        TEXTEQU <PRINTDLGA>

PrintDlgA       PROTO   WINAPI  :LPPRINTDLG
PrintDlg        TEXTEQU <PrintDlgA>

PD_ALLPAGES     EQU 00000h
PD_SELECTION        EQU 00001h
PD_PAGENUMS     EQU 00002h
PD_NOSELECTION      EQU 00004h
PD_NOPAGENUMS       EQU 00008h
PD_COLLATE      EQU 00010h
PD_PRINTTOFILE      EQU 00020h
PD_PRINTSETUP       EQU 00040h
PD_NOWARNING        EQU 00080h
PD_RETURNDC     EQU 00100h
PD_RETURNIC     EQU 00200h
PD_RETURNDEFAULT    EQU 00400h
PD_SHOWHELP     EQU 00800h
PD_ENABLEPRINTHOOK  EQU 01000h
PD_ENABLESETUPHOOK  EQU 02000h
PD_ENABLEPRINTTEMPLATE  EQU 04000h
PD_ENABLESETUPTEMPLATE  EQU 08000h
PD_ENABLEPRINTTEMPLATEHANDLE    EQU 0010000h
PD_ENABLESETUPTEMPLATEHANDLE    EQU 0020000h
PD_USEDEVMODECOPIES     EQU 0040000h
PD_USEDEVMODECOPIESANDCOLLATE   EQU 0040000h
PD_DISABLEPRINTTOFILE       EQU 0080000h
PD_HIDEPRINTTOFILE      EQU 0100000h
PD_NONETWORKBUTTON      EQU 0200000h

CommDlgExtendedError    PROTO   WINAPI

PAGESETUPDLGA       STRUCT
    lStructSize DWORD   ?
    hwndOwner   HWND    ?
    hDevMode    HGLOBAL ?
    hDevNames   HGLOBAL ?
    Flags       DWORD   ?
    ptPaperSize POINT   <>
    rtMinMargin RECT    <>
    rtMargin    RECT    <>
    hInstance   HINSTANCE ?
    lCustData   LPARAM  ?
    lpfnPageSetupHook   DWORD   ?
    lpfnPagePaintHook   DWORD   ?
    lpPageSetupTemplateName LPCSTR  ?
    hPageSetupTemplate  HGLOBAL ?
PAGESETUPDLGA       ENDS
LPPAGESETUPDLG      TYPEDEF PTR PAGESETUPDLGA
PAGESETUPDLG        TEXTEQU <PAGESETUPDLGA>

PageSetupDlgA       PROTO   WINAPI  :LPPAGESETUPDLG
PageSetupDlg        TEXTEQU <PageSetupDlgA>

PSD_DEFAULTMINMARGINS       EQU 0000000h
PSD_MINMARGINS          EQU 0000001h
PSD_MARGINS         EQU 0000002h
PSD_INTHOUSANDTHSOFINCHES   EQU 0000004h
PSD_INHUNDREDTHSOFMILLIMETERS   EQU 0000008h
PSD_DISABLEMARGINS      EQU 0000010h
PSD_DISABLEPRINTER      EQU 0000020h
PSD_NOWARNING           EQU 0000080h
PSD_DISABLEORIENTATION      EQU 0000100h
PSD_DISABLEPAPER        EQU 0000200h
PSD_RETURNDEFAULT       EQU 0000400h
PSD_SHOWHELP            EQU 0000800h
PSD_ENABLEPAGESETUPHOOK     EQU 0002000h
PSD_ENABLEPAGESETUPTEMPLATE EQU 0008000h
PSD_ENABLEPAGESETUPTEMPLATEHANDLE EQU   0020000h
PSD_ENABLEPAGEPAINTHOOK     EQU 0040000h
PSD_DISABLEPAGEPAINTING     EQU 0080000h
PSD_NONETWORKBUTTON     EQU 0200000h


;*******************************************************************************
;*  COMCTL32.LIB    COMMCTRL.H  ****************************************
;*******************************************************************************

InitCommonControls  PROTO   WINAPI

TBBUTTON        STRUCT
    iBitMap     SDWORD  ?
    idCommand   SDWORD  ?
    fsState     BYTE    ?
    fsStyle     BYTE    ?
    dwData      DWORD   ?
    iString     SDWORD  ?
TBBUTTON        ENDS
LPCTBBUTTON     TYPEDEF PTR TBBUTTON

CreateToolbarEx     PROTO   WINAPI  :HWND, :DWORD, :UINT, :SDWORD,\
                    :HINSTANCE, :UINT, :LPCTBBUTTON,\
                    :SDWORD, :SDWORD, :SDWORD,\
                    :SDWORD, :SDWORD, :UINT
TBSTATE_ENABLED     EQU 4h
TBSTYLE_BUTTON      EQU 0h
TBSTYLE_SEP     EQU 1h
TBSTYLE_TOOLTIPS    EQU 0100h

TB_ADDBITMAP        EQU WM_USER + 13h

TBADDBITMAP STRUCT
    hInst   HINSTANCE   ?
    nID UINT        ?
TBADDBITMAP ENDS

HINST_COMMCTRL      EQU -1h
IDB_STD_SMALL_COLOR EQU 00h

STD_CUT         EQU 00h
STD_COPY        EQU 01h
STD_PASTE       EQU 02h
STD_UNDO        EQU 03h
STD_REDOW       EQU 04h
STD_DELETE      EQU 05h
STD_FILENEW     EQU 06h
STD_FILEOPEN        EQU 07h
STD_FILESAVE        EQU 08h
STD_PRINTPRE        EQU 09h
STD_PROPERTIES      EQU 0Ah
STD_HELP        EQU 0Bh
STD_FIND        EQU 0Ch
STD_REPLACE     EQU 0Dh
STD_PRINT       EQU 0Eh

TTN_FIRST       EQU -520
TTN_NEEDTEXT        EQU TTN_FIRST - 0

TOOLTIPTEXTA        STRUCT
    hdr     NMHDR   <>
    lpszText    LPSTR   ?
    szText      SBYTE   80 DUP (?)
    hinst       HINSTANCE ?
    uFlags      UINT    ?
TOOLTIPTEXTA        ENDS
LPTOOLTIPTEXT       TYPEDEF PTR TOOLTIPTEXTA
TOOLTIPTEXT     TEXTEQU <TOOLTIPTEXTA>

CreateStatusWindow  PROTO   WINAPI  :LONG, :LPCSTR, :HWND, :UINT

SB_SETTEXTA     EQU (WM_USER+1)
SB_SETTEXT      EQU SB_SETTEXTA
SB_SIMPLE       EQU (WM_USER+9)
SBT_NOBORDERS       EQU 0100h
SBT_POPOUT      EQU 0200h

TBM_GETPOS      EQU (WM_USER)
TBM_SETPOS      EQU (WM_USER+5)
TBM_SETRANGE        EQU (WM_USER+6)
TBM_SETTICFREQ      EQU (WM_USER+20)
TBM_SETPAGESIZE     EQU (WM_USER+21)
TB_LINEUP       EQU 00h
TB_LINEDOWN     EQU 01h
TB_PAGEUP       EQU 02h
TB_PAGEDOWN     EQU 03h
TB_THUMBPOSITION    EQU 04h
TB_THUMBTRACK       EQU 05h
TB_TOP          EQU 06h
TB_BOTTOM       EQU 07h
TB_ENDTRACK     EQU 08h

UDM_SETRANGE        EQU (WM_USER+101)
UDM_SETPOS      EQU (WM_USER+103)
UDM_GETPOS      EQU (WM_USER+104)
