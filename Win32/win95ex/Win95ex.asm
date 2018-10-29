         .486p
         .model  flat,STDCALL
;         %nolist
include  w32.inc
;         %list
;*******************************************************************
;*  RESOURCE EQUATES                                               *
;*******************************************************************
ID_TIMER1        equ 1
IDI_ICON1        equ 101
IDR_MENU1        equ 102
IDD_DIALOG1      equ 103
IDD_ABOUTBOX     equ 2001
IDR_ACCEL        equ 3000
;
; Options menu
;
IDM_TITLE        equ 4001
;
; File menu
;
IDM_NEW          equ 5001
IDM_OPEN         equ 5002
IDM_CLOSE        equ 5003
IDM_SAVE         equ 5004
IDM_SAVEAS       equ 5005
IDM_PRINT        equ 5006
IDM_EXIT         equ 5007
;
; Edit menu
;
IDM_CUT          equ 6001
IDM_COPY         equ 6002
IDM_PASTE        equ 6003
;
; Help menu
;
IDM_ABOUT        equ 7001
IDM_HELP         equ 7002
;
IDC_EDIT1        equ 1000
ID_STATUSBAR     equ 201
IDB_TOOLBAR      equ 301
ID_TOOLBAR       equ 302
;
SB_SETTEXT       equ WM_USER+1
SB_SETPARTS      equ WM_USER+4
SB_SIMPLE        equ WM_USER+9
SBT_POPOUT       equ 0200h
;
; Status bar section equates
;
SBPART_MESSAGE   equ 0
SBPART_MESSAGE2  equ 1
SBPART_MOUSEMOVE equ 2
SBPART_TIME      equ 3
SBPARTS          equ 4
;
; Miscellaneous Equates
;
TRUE     equ     1
FALSE    equ     0
;*******************************************************************
;*  DATA                                                           *
;*******************************************************************
         .data
;
msg      MSGSTRUCT   <?>
;
szNULL   db      0
notoolb  db      'Could not create toolbar',0
nostatb  db      'Could not create status bar',0
ttl      db      'Test Assembler Program',0
already  db      'A copy of this program is already running',0
szHelp   db      'win95ex.hlp',0
class    db      'win95example',0
statcls  db      'msctls_statusbar32',0
msgbuff  db      'Test Win32 Assembler Program',0
         db      (64) dup(?)
msgbuffl equ     ($-msgbuff)-1
;
mmsg     db      'X:'
mmsgx    db      4 dup(0)
         db      ' Y:'
mmsgy    db      4 dup(0)
         db      0
;
tmsg     equ     $
tmsghour db      2 dup(?)
         db      ':'
tmsgmin  db      2 dup(?)
         db      ':'
tmsgsec  db      2 dup(?)
         db      ' '
tmsgampm db      '?'
         db      'M',0
;
szBuf    db      32 dup(?)
szBufl   equ     ($-szBuf)-1
szFile   db      256 dup(0)
szOpenTitle  db  'Open File',0
szSaveTitle  db  'Save File As',0
szFilter db      'Text Files',0,'*.txt',0,0
szExt    db      '*.txt',0
;
parts    dd      SBPARTS dup(0)
;
ycaption dd      0
ymenu    dd      0
newhwnd  dd      0
hwndstat dd      0
hwndtool dd      0
hInst    dd      0
hMenu    dd      0
hAccel   dd      0
msgl     dd      0
tempword dd      0
bytesread dd     0
hFile    dd      0
tb       TBBUTTON    <0,IDM_NEW,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
         TBBUTTON    <1,IDM_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
         TBBUTTON    <2,IDM_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
         TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,?,0,0>
         TBBUTTON    <3,IDM_CUT,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
         TBBUTTON    <4,IDM_COPY,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
         TBBUTTON    <5,IDM_PASTE,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
         TBBUTTON    <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,?,0,0>
         TBBUTTON    <6,IDM_PRINT,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
tbb      TBBUTTON    <7,IDM_ABOUT,TBSTATE_ENABLED,TBSTYLE_BUTTON,?,0,0>
tbl      equ         ($-tbb) ;size of a single TBBUTTON

ofs      OFSTRUCT    <?>
doci     DOCINFO     <?>
docil    equ    $-doci
ofn      OPENFILENAME <?>
ofnl     equ    $-ofn
pd       PRINTDLG <?>
pdl      equ    $-pd
time     SYSTEMTIME  <?>
rect     RECT        <?>
tm       TEXTMETRIC  <?>
ps       PAINTSTRUCT <?>
wc       WNDCLASS    <?>


;*******************************************************************
;*  CODE                                                           *
;*******************************************************************
         .code
start:
         call    InitCommonControls ;Initialize the common ctrl lib
         push    0
         call    GetModuleHandle ;get hmod (in eax)
         mov     [hInst],eax     ;hInstance is same as HMODULE
findcls:
         push    0
         push    offset class
         call    FindWindow
         or      eax,eax
         jz      regclass
         push    MB_ABORTRETRYIGNORE
         push    offset ttl
         push    offset already
         push    0
         call    MessageBox
         cmp     eax,IDABORT
         je      end_loop
         cmp     eax,IDRETRY
         je      findcls
         ;It's IDIGNORE
regclass:
;
; Initialize the WndClass structure and register our class
;
         mov     [wc.clsStyle],CS_HREDRAW+CS_VREDRAW+CS_GLOBALCLASS
         mov     [wc.clsLpfnWndProc],offset WndProc
         mov     [wc.clsCbClsExtra],0
         mov     [wc.clsCbWndExtra],0
         mov     eax,[hInst]
         mov     [wc.clsHInstance],eax
         push    IDI_ICON1
         push    eax
         call    LoadIcon
         mov     [wc.clsHIcon],eax
         push    IDC_ARROW
         push    0
         call    LoadCursor
         mov     [wc.clsHCursor],eax
         mov     [wc.clsHbrBackground],COLOR_WINDOW+1
         mov     dword ptr [wc.clsLpszMenuName],0
         mov     dword ptr [wc.clsLpszClassName],offset class
         push    offset wc
         call    RegisterClass
;
; Get our menu resource
;
         push    IDR_MENU1
         push    [hInst]
         call    LoadMenu
         mov     [hMenu],eax
;
; Create the main window
;
         push    0               ;lpParam
         push    [hInst]         ;hInstance
         push    [hMenu]         ;menu
         push    0               ;parent hwnd
         push    CW_USEDEFAULT   ;height
         push    CW_USEDEFAULT   ;width
         push    CW_USEDEFAULT   ;y
         push    CW_USEDEFAULT   ;x
         push    WS_OVERLAPPEDWINDOW ;Style
         push    offset ttl      ;Title string
         push    offset class    ;Class name
         push    0               ;extra style
         call    CreateWindowEx
         mov     [newhwnd],eax
;
; Show the window and go into message dispatch loop
;
         push    SW_SHOWNORMAL
         push    [newhwnd]
         call    ShowWindow
         push    [newhwnd]
         call    UpdateWindow
         push    IDR_ACCEL
         push    [hInst]
         call    LoadAccelerators
         mov     [hAccel],eax
msg_loop:
         push    0
         push    0
         push    0
         push    offset msg
         call    GetMessage
         cmp     ax,0
         je      end_loop
         push    offset msg
         push    [hAccel]
         push    [newhwnd]
         call    TranslateAccelerator
         cmp     eax,0
         jne     msg_loop
         push    offset msg
         call    TranslateMessage
         push    offset msg
         call    DispatchMessage
         jmp     msg_loop
end_loop:
         push    [msg.msWPARAM]
         call    ExitProcess
;*******************************************************************
;*  WNDPROC                                                        *
;*******************************************************************
WndProc  proc    uses ebx edi esi, hwnd:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
         LOCAL   theDC:DWORD
         mov     eax,[wmsg]
         cmp     eax,WM_PAINT
         je      wmpaint
         cmp     eax,WM_TIMER
         je      wmtimer
         cmp     eax,WM_MOUSEMOVE
         je      wmmousemove
         cmp     eax,WM_RBUTTONDOWN
         je      wmrbuttondown
         cmp     eax,WM_SIZE
         je      wmsize
         cmp     eax,WM_CREATE
         je      wmcreate
         cmp     eax,WM_LBUTTONDOWN
         je      wmlbuttondown
         cmp     eax,WM_COMMAND
         je      wmcommand
         cmp     eax,WM_DESTROY
         je      wmdestroy
         cmp     eax,WM_NOTIFY
         je      wmnotify
         cmp     eax,WM_MENUSELECT
         je      wmmenuselect
         jmp     defwndproc

wmcommand:
         mov     eax,[wparam]
         cwde    ;only low word contains command
         cmp     eax,IDM_EXIT
         je      wmdestroy
         cmp     eax,IDM_TITLE
         je      dotitle
         cmp     eax,IDM_NEW
         je      defwndproc
         cmp     eax,IDM_OPEN
         je      doopen
         cmp     eax,IDM_CLOSE
         je      defwndproc
         cmp     eax,IDM_SAVE
         je      dosave
         cmp     eax,IDM_SAVEAS
         je      dosave
         cmp     eax,IDM_PRINT
         je      doprint
         cmp     eax,IDM_CUT
         je      defwndproc
         cmp     eax,IDM_COPY
         je      defwndproc
         cmp     eax,IDM_PASTE
         je      defwndproc
         cmp     eax,IDM_HELP
         je      dohelp
         cmp     eax,IDM_ABOUT
         je      idmabout
         jmp     defwndproc

dohelp:
         push    0
         push    HELP_CONTENTS
         push    offset szHelp
         push    [hwnd]
         call    WinHelp
         jmp     return0

idmabout:
         push    0               ;LPARAM to pass to dialog
         push    offset AboutDlg ;DLGPROC lpDialogFunc
         push    [hwnd]          ;window handle of this window
         push    IDD_ABOUTBOX    ;Dialog ID
         push    [hInst]         ;Module Instance
         call    DialogBoxParam  ;Invoke Dialog
         jmp     return0

dotitle:
;
; Invoke a custom dialog (DIALOG1) defined in test.rc
;
         push    offset msgbuff  ;LPARAM to pass to dialog
         push    offset MyDialog ;DLGPROC lpDialogFunc
         push    [hwnd]          ;window handle of this window
         push    IDD_DIALOG1     ;Dialog ID
         push    [hInst]         ;Module Instance
         call    DialogBoxParam  ;Invoke Dialog
         push    1               ;Invalidate window erase=true
         push    0               ;rectangle = NULL
         push    [hwnd]          ;Handle to invalidate
         call    InvalidateRect  ;repaint window
         jmp     return0

doopen:
;
; Call the GetOpenFileName common dialog to retrieve the path in szFile
;
         mov     ecx,ofnl
         mov     edi,offset ofn
         xor     eax,eax
         rep     stosb
         mov     [ofn.lStructSize],ofnl
         mov     eax,[hwnd]
         mov     [ofn.hwndOwner],eax
         mov     eax,[hInst]
         mov     [ofn.hInstance],eax
         mov     [ofn.lpstrFilter],offset szFilter
         mov     [ofn.lpstrFile],offset szFile
         mov     [ofn.nMaxFile],length szFile
         mov     [ofn.lpstrInitialDir],0
         mov     [ofn.lpstrTitle],offset szOpenTitle
         mov     [ofn.lpstrDefExt],offset szExt
         mov     [ofn.Flags],OFN_PATHMUSTEXIST+OFN_FILEMUSTEXIST
         push    offset ofn
         call    GetOpenFileName
         cmp     eax,FALSE       ;Cancel'ed or error occurred
         je      return0
;
; Open the file and read in a some data
;
         push    OF_READ         ;open it read only
         push    offset ofs      ;open supplies some info
         push    offset szFile   ;path
         call    OpenFile
         cmp     eax,-1          ;error?
         je      return0
         mov     [hFile],eax
         push    0
         push    offset bytesread
         push    msgbuffl
         push    offset msgbuff
         push    eax
         call    ReadFile
         cmp     eax,FALSE
         je      return0
         mov     edi,[bytesread]
         mov     byte ptr[edi+offset msgbuff],0
         push    [hFile]
         call    CloseHandle
         mov     al,0dh
         mov     ecx,[bytesread]
         lea     edi,msgbuff
         cld
         repnz   scasb
         jnz     $+6
         mov     byte ptr[edi-1],0
         push    1               ;Invalidate window erase=true
         push    0               ;rectangle = NULL
         push    [hwnd]          ;Handle to invalidate
         call    InvalidateRect  ;repaint window
doopenx: jmp     return0

dosave:
;
; Call the GetSaveFileName common dialog to determine the save path
;
         mov     ecx,ofnl
         mov     edi,offset ofn
         xor     eax,eax
         rep     stosb
         mov     [ofn.lStructSize],ofnl
         mov     eax,[hwnd]
         mov     [ofn.hwndOwner],eax
         mov     eax,[hInst]
         mov     [ofn.hInstance],eax
         mov     [ofn.lpstrFilter],offset szFilter
         mov     [ofn.lpstrFile],offset szFile
         mov     [ofn.nMaxFile],length szFile
         mov     [ofn.lpstrInitialDir],0
         mov     [ofn.lpstrTitle],offset szSaveTitle
         mov     [ofn.lpstrDefExt],offset szExt
         mov     [ofn.Flags],OFN_PATHMUSTEXIST+OFN_FILEMUSTEXIST
         push    offset ofn
         call    GetSaveFileName
         jmp     return0

doprint:
;
; Call the PrintDlg common dialog function and print the msgbuff
;
         mov     ecx,pdl
         mov     edi,offset pd
         xor     eax,eax
         rep     stosb
         mov     [pd.pdlStructSize],pdl
         mov     eax,[hwnd]
         mov     [pd.pdhwndOwner],eax
         mov     eax,[hInst]
         mov     [pd.pdhInstance],eax
         mov     [pd.pdFlags],PD_RETURNDC+PD_USEDEVMODECOPIES+PD_COLLATE+PD_NOSELECTION+PD_PRINTSETUP
         push    offset pd
         call    PrintDlg
         cmp     eax,0
         jz      return0
         mov     [doci.cbSize],docil
         mov     [doci.lpszDocName],offset ttl
         mov     [doci.lpszOutput],0
         mov     [doci.fwType],0
         push    offset doci
         push    [pd.pdhDC]
         call    StartDoc
         push    [pd.pdhDC]
         call    StartPage
         cmp     eax,0
         jle     return0
         mov     ebx,offset msgbuff
         call    strlen
         push    ecx
         push    offset msgbuff
         push    10
         push    10
         push    [pd.pdhDC]
         call    TextOut         ;print a line of text
         push    [pd.pdhDC]
         call    EndPage
         push    [pd.pdhDC]
         call    EndDoc
         push    [pd.pdhDC]
         call    DeleteDC
         jmp     return0

wmnotify:
         mov     ebx,[lparam]    ;get pointer to NMHDR
         cmp     [(NMHDR ptr ebx).code],TTN_NEEDTEXT
         jne     defwndproc
         mov     eax,[(NMHDR ptr ebx).idFrom] ;resource id
         push    szBufl          ;size of our buffer
         push    offset szBuf    ;buffer to load string into
         push    eax             ;resource extracted from TOOLTIPTEXT
         push    [hInst]         ;Instance
         call    LoadString      ;Load the tip from STRINGTABLE
         mov     ebx,[lparam]    ;now just give him our buffer addr.
         mov     [(TOOLTIPTEXT ptr ebx).lpszText],offset szBuf
         jmp     return0

wmpaint:
         push    offset ps
         push    [hwnd]
         call    BeginPaint
         mov     [theDC],eax
         push    offset rect     ;rectangle structure
         push    [hwnd]          ;window handle
         call    GetWindowRect   ;get size of window
         push    offset tm       ;TEXTMETRIC structure
         push    [theDC]         ;device context
         call    GetTextMetrics  ;get the text metrics
         mov     ebx,offset msgbuff ;address of title
         call    strlen          ;get length of string
         mov     [msgl],ecx      ;save for later
         push    ecx             ;length of string
         push    offset msgbuff  ;string
         mov     eax,[rect.rcBottom]
         sub     eax,[rect.rcTop]
         shr     eax,1           ;(Bottom-Top)/2
         sub     eax,[ycaption]  ;subtract caption size
         sub     eax,[ymenu]     ;and our menu size
         push    eax             ;y
         mov     ebx,[rect.rcRight]
         sub     ebx,[rect.rcLeft]
         shr     ebx,1           ;(Right-Left)/2
         mov     eax,[tm.tmAveCharWidth]
         mul     [msgl]          ;AveCharWidth*MessageLength
         shr     eax,1           ;/2
         sub     ebx,eax         ;((Right-Left)/2)-((AveCharWidth*msgl)/2)
         push    ebx             ;x
         push    [theDC]         ;the DC
         call    TextOut         ;display the message in the center
         push    offset ps
         push    [hwnd]
         call    EndPaint
         jmp     return0

wmmousemove:
         mov     eax,[lparam]    ;get the x
         shr     eax,16          ;position in hiword(lparam)
         mov     [tempword],eax  ;save for load
         lea     ebx,tempword    ;address of the above conversion
         lea     edx,mmsgy       ;dest
                 mov     ecx,4           ;#bytes
         call    cvdec           ;convert to displayable ascii decimal
         mov     eax,[lparam]    ;get the y
         cwde                    ;position in loword(lparam)
         mov     [tempword],eax  ;save for load
         lea     ebx,tempword    ;source
         lea     edx,mmsgx       ;dest
                 mov     ecx,4           ;#bytes
         call    cvdec           ;convert to displayable ascii decimal
         push    offset mmsg     ;SendMessage; lparam
         push    SBPART_MOUSEMOVE ;wparam
         push    SB_SETTEXT      ;message to send
         push    [hwndstat]      ;handle to status area
         call    SendMessage     ;send it to the status area
         jmp     return0

wmcreate:
;
; Create the status bar window
;
         mov     [hwndstat],0    ;zero handle
         push    SM_CYMENU       ;get the size of the menu bar
         call    GetSystemMetrics
         mov     [ymenu],eax     ;save it
         push    SM_CYCAPTION    ;get the caption size also
         call    GetSystemMetrics
         mov     [ycaption],eax  ;save it
         push    0               ;lpParam
         push    [hInst]         ;hInstance
         push    ID_STATUSBAR    ;menu
         push    [hwnd]          ;parent hwnd
         push    0               ;height
         push    0               ;width
         push    0               ;y
         push    0               ;x
         push    WS_CHILD+WS_BORDER+WS_VISIBLE+SBS_SIZEGRIP ;style
         push    offset szNULL   ;Title string is null
         push    offset statcls  ;Use the new STATUSCLASSNAME
         push    0               ;extra style
         call    CreateWindowEx
         cmp     eax,0           ;Create go ok?
         jne     creatok         ;yes continue
         push    MB_OK           ;Complain to the user
         push    offset ttl
         push    offset nostatb
         push    0
         call    MessageBox
         jmp     wmcrexit
creatok:
         mov     [hwndstat],eax  ;save the handle to statusbar
         push    0               ;timerproc = null
         push    1000            ;every 1 sec
         push    ID_TIMER1       ;id of timer
         push    [hwnd]          ;handle
         call    SetTimer        ;set the timer
;
; Now create the toolbar
;
         push    tbl             ;structure size
         push    15              ;bitmap height
         push    16              ;bitmap width
         push    15              ;button height
         push    16              ;button width
         push    10              ;# of buttons
         push    offset tb       ;address of buttons
         push    IDB_TOOLBAR     ;Resource ID
         push    [hInst]         ;instance
         push    8               ;number of bitmaps
         push    ID_TOOLBAR      ;toolbar ID
         push    WS_CHILD+WS_BORDER+WS_VISIBLE+TBSTYLE_TOOLTIPS+CCS_ADJUSTABLE
         push    [hwnd]          ;our handle
         call    CreateToolbarEx
         cmp     eax,0           ;handle null?
         jne     tbok            ;no, toolbar created
         push    MB_OK           ;Complain to the user
         push    offset ttl
         push    offset notoolb
         push    0
         call    MessageBox
         jmp     wmcrexit
tbok:
         mov     [hwndtool],eax  ;save the handle to toolbar

wmcrexit:
         jmp     return0

wmtimer:
         cmp     [wparam],ID_TIMER1 ;is it our timer?
         jne     wmtimex         ;no, then exit
         call    fmtime          ;format and display the time
wmtimex: jmp     return0

defwndproc:
         push    [lparam]
         push    [wparam]
         push    [wmsg]
         push    [hwnd]
         call    DefWindowProc
         jmp     finish

wmdestroy:
         push    ID_TIMER1       ;Kill the timer
         push    [hwnd]
         call    KillTimer
         push    0
         call    PostQuitMessage ;Quit
         jmp     return0

wmlbuttondown:
         push    0
         push    0
         push    [hwnd]
         call    InvalidateRect  ;repaint window
         jmp     return0

wmrbuttondown:
         push    0
         call    MessageBeep
         jmp     finish

wmsize:
         cmp     [hwndstat],0    ;is status valid?
         jz      wmsizex         ;no, then exit
         mov     eax,[lparam]    ;height/width of new window
         mov     ebx,eax
         and     ebx,0000ffffh   ;ebx = LOWORD(lparam) = width
         shr     eax,16          ;eax = HIWORD(lparam) = height
         push    TRUE            ;repaint is true
         push    eax             ;height
         push    ebx             ;width
         push    eax             ;y
         push    0               ;x
         push    [hwndstat]      ;handle to statusbar
         call    MoveWindow      ;adjust window
         mov     eax,[lparam]    ;get width
         cwde                    ;lowword
         shr     eax,2           ;/4
         mov     ecx,eax         ;save factor
         mov     [parts],eax     ;make part 1 1/4 the width
         add     eax,ecx
         mov     [parts+4],eax   ;and also part2, .. etc
         add     eax,ecx
         mov     [parts+8],eax
         mov     [parts+12],-1   ;the last part extends to the end
         push    offset parts
         push    SBPARTS
         push    SB_SETPARTS
         push    [hwndstat]
         call    SendMessage     ;Set the sections in the statusbar
         cmp     [hwndtool],0    ;is there a valid toolbar?
         jz      wmsizex         ;no, then exit
         push    0
         push    0
         push    TB_AUTOSIZE
         push    [hwndtool]
         call    SendMessage     ;tell the toolbar to size itself
wmsizex: jmp     return0

wmmenuselect:
         mov     eax,[wparam]
         and     eax,0ffff0000h
         cmp     eax,0ffff0000h  ;special case, menu canceled
         jne     wmms1
         mov     eax,[lparam]
         cmp     eax,0
         jne     wmms1
         mov     byte ptr[szBuf],0 ;clear status area when exit from menu
         jmp     wmms2
wmms1:   mov     eax,[wparam]
         cwde
         add     eax,10000
         push    szBufl          ;size of our buffer
         push    offset szBuf    ;buffer to load string into
         push    eax             ;menu item message
         push    [hInst]         ;Instance
         call    LoadString      ;Load the tip from STRINGTABLE
         cmp     eax,0
         je      return0
wmms2:   push    offset szBuf
         push    SBPART_MESSAGE
         push    SB_SETTEXT
         push    [hwndstat]
         call    SendMessage     ;Display Menu help
         jmp     return0

return0: xor     eax,eax
finish:  ret
WndProc  endp
public   WndProc
;*******************************************************************
;*  DLGPROC                                                        *
;*******************************************************************
MyDialog proc    hdlg:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
         cmp     [wmsg],WM_INITDIALOG ;if message is INITDIALOG then
         jne     @1              ;just return
         mov     eax,[lparam]    ;save off address of
         mov     [tempword],eax  ;buffer
         push    IDC_EDIT1       ;get handle
         push    [hdlg]          ;of the edit
         call    GetDlgItem      ;field
         push    eax             ;push handle of edit1
         push    eax             ;and save for LIMITTEXT
         call    SetFocus        ;set focus to this field
         pop     eax
         push    0
         push    msgbuffl        ;buffer size to limit field
         push    EM_LIMITTEXT
         push    eax
         call    SendMessage     ;limit text size
         mov     eax,FALSE       ;FALSE because we set the focus
         jmp     MyDlgRet        ;go and return
@1:      cmp     [wmsg],WM_COMMAND ;Is message is a WM_COMMAND?
         jne     MyDlgDone       ;No, then just return
         mov     eax,[wparam]    ;Otherwise, see if it's OK or CANCEL
         cmp     eax,IDCANCEL    ;That was pressed
         je      isCANCEL        ;and if not either of these
         cmp     eax,IDOK        ;then just
         jne     MyDlgDone       ;return
         push    msgbuffl        ;nMaxCount
         push    [tempword]      ;Address of buffer to store
         push    IDC_EDIT1       ;Contents of the EDIT1 field
         push    [hdlg]          ;handle to the dialog
         call    GetDlgItemText  ;Get the text stored in EDIT1
isCANCEL:
         push    [wparam]        ;terminate with wparam as the return
         push    [hdlg]          ;handle of the dialog
         call    EndDialog       ;end the dialog
         mov     eax,TRUE        ;return
         jmp     MyDlgRet        ;with TRUE
MyDlgDone:
         mov     eax,FALSE       ;return with FALSE
MyDlgRet:
         ret                     ;return
MyDialog endp
public   MyDialog

;*******************************************************************
;*  ABOUTBOX DIALOG PROCEDURE                                      *
;*******************************************************************
AboutDlg proc    hdlg:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
         cmp     [wmsg],WM_COMMAND ;Is message is a WM_COMMAND?
         jne     MyDlgDone       ;No, then just return
         mov     eax,[wparam]    ;Otherwise, see if it's OK or CANCEL
         cmp     eax,IDOK        ;That was pressed
         je      @@1             ;and if not either of these
         cmp     eax,IDCANCEL    ;then just
         jne     AboutDone       ;return
@@1:     push    [wparam]        ;terminate with wparam as the return
         push    [hdlg]          ;handle of the dialog
         call    EndDialog       ;end the dialog
         mov     eax,TRUE        ;return
         jmp     AboutRet        ;with TRUE
AboutDone:
         mov     eax,FALSE       ;return with FALSE
AboutRet:
         ret                     ;return
AboutDlg endp
public   AboutDlg

;*******************************************************************
;*  STRLEN                                                         *
;*  ebx = input string pointer                                     *
;*  returns ecx with the string length                             *
;*******************************************************************
strlen   proc
         xor     ecx,ecx          ;clear count
loop:    mov     al,byte ptr[ebx] ;get char of string
         cmp     al,0             ;is it zero?
         je      done             ;done if zero term char
         inc     ecx              ;increment count
         inc     ebx              ;increment pointer
         jmp     loop             ;continue
done:    ret
strlen   endp


;*******************************************************************
;*  CVDEC                                                          *
;*  ebx = source integer                                           *
;*  edx = dest address                                             *
;*  destroys eax,ecx,esi,edi                                       *
;*******************************************************************
cvdec    proc
;
; ebx = source
; edx = dest
; ecx = even # bytes to convert
;
         LOCAL   tempbuf:TBYTE
         fild    word ptr[ebx]  ;integer load
         fbstp   tempbuf         ;convert to bcd
         lea     ebx,tempbuf     ;address of the above conversion
         shr     ecx,1
                 dec     ecx
         mov     esi,ecx
                 xor     edi,edi
cvloop:  mov     al,[ebx+esi]
         mov     cl,al
         and     al,0fh
         shr     cl,4
         or      al,30h
         or      cl,30h
         mov     [edx+edi],cl
         inc     edi
         mov     [edx+edi],al
         inc     edi
         dec     esi
         jns     cvloop
         ret
cvdec    endp

;*******************************************************************
;*  Format the time and send it to the status bar                  *
;*******************************************************************
fmtime   proc
         cmp     [hwndstat],0    ;valid statusbar?
         jz      ftimex          ;no, then exit
         push    offset time     ;get the local
         call    GetLocalTime    ;time from win32
         mov     byte ptr[tmsgampm],'A' ;default to AM
         mov     ax,[time.wHour] ;get hour
         cmp     ax,12           ;>12?
         jle     isAM            ;it's AM
         mov     byte ptr[tmsgampm],'P' ;reset to PM
         sub     ax,12           ;-12
         mov     [time.wHour],ax ;save it
isAM:    lea     ebx,time.wHour  ;integer load the hour
         lea     edx,tmsghour    ;dest
                 mov     ecx,2           ;#bytes
         call    cvdec           ;convert to displayable ascii decimal
         lea     ebx,time.wMinute ;integer load the minute
         lea     edx,tmsgmin     ;dest
                 mov     ecx,2           ;#bytes
         call    cvdec           ;convert to displayable ascii decimal
         lea     ebx,time.wSecond ;integer load the Second
         lea     edx,tmsgsec     ;dest
                 mov     ecx,2           ;#bytes
         call    cvdec           ;convert to displayable ascii decimal
         push    offset tmsg
         push    SBPART_TIME
         push    SB_SETTEXT
         push    [hwndstat]
         call    SendMessage     ;Display time in statusbar (section 2)
ftimex:  ret
fmtime   endp

         ends
         end     start

