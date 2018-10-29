; @#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
;
;                               MODEL.ASM
;                               ~~~~~~~~~
; This template is designed for a larger architecture application which
; has a separate include file for its local prototypes and .data section.
;
; It uses a tool bar technique which is easier to modify & extend and it
; uses a multi-part status bar for displaying different values at the same
; time. It also has standard File Open & File Save common dialog boxes.

; @#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@

      .386
      .model flat, stdcall  ; 32 bit memory model
      option casemap :none  ; case sensitive

      include model.inc     ; local includes for this file

; #########################################################################

.code

start:
      invoke GetModuleHandle, NULL
      mov hInstance, eax

      invoke GetCommandLine
      mov CommandLine, eax

      invoke InitCommonControls

      invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
      invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

      ;====================
      ; Put LOCALs on stack
      ;====================

      LOCAL wc   :WNDCLASSEX
      LOCAL msg  :MSG
      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD

      ;==================================================
      ; Fill WNDCLASSEX structure with required variables
      ;==================================================

      invoke LoadIcon,hInst,500    ; icon ID
      mov hIcon, eax

      mov wc.cbSize,         sizeof WNDCLASSEX
      mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                             or CS_BYTEALIGNWINDOW
      mov wc.lpfnWndProc,    offset WndProc
      mov wc.cbClsExtra,     NULL
      mov wc.cbWndExtra,     NULL
      m2m wc.hInstance,      hInst
      mov wc.hbrBackground,  COLOR_BTNFACE+1
      mov wc.lpszMenuName,   NULL
      mov wc.lpszClassName,  offset szClassName
      m2m wc.hIcon,          hIcon
        invoke LoadCursor,NULL,IDC_ARROW
      mov wc.hCursor,        eax
      m2m wc.hIconSm,        hIcon

      invoke RegisterClassEx, ADDR wc

      ;================================
      ; Centre window at following size
      ;================================

      mov Wwd, 500
      mov Wht, 350

      invoke GetSystemMetrics,SM_CXSCREEN
      invoke TopXY,Wwd,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN
      invoke TopXY,Wht,eax
      mov Wty, eax

      szText szClassName,"Template_Class"

      invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPEDWINDOW,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL
      mov   hWnd,eax

      szText stTxt1," Advanced MASM32 template"
      invoke SendMessage,hStatus,SB_SETTEXT,3,ADDR stTxt1

      invoke LoadMenu,hInst,600  ; menu ID
      invoke SetMenu,hWnd,eax

      invoke ShowWindow,hWnd,SW_SHOWNORMAL
      invoke UpdateWindow,hWnd

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      invoke TranslateMessage, ADDR msg
      invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL caW :DWORD
    LOCAL caH :DWORD
    LOCAL Rct :RECT
    LOCAL tbab:TBADDBITMAP
    LOCAL tbb :TBBUTTON
    LOCAL sbParts[4] :DWORD

    .if uMsg == WM_COMMAND
    ;======== toolbar commands ========
        .if wParam == 50
            szText tb1,"Button 1"
            invoke MessageBox,hWin,ADDR tb1,ADDR szDisplayName,MB_OK
        .elseif wParam == 51
            szText tb2,"Button 2"
            invoke MessageBox,hWin,ADDR tb2,ADDR szDisplayName,MB_OK
        .elseif wParam == 52
            szText tb3,"Button 3"
            invoke MessageBox,hWin,ADDR tb3,ADDR szDisplayName,MB_OK
        .elseif wParam == 53
            szText tb4,"Button 4"
            invoke MessageBox,hWin,ADDR tb4,ADDR szDisplayName,MB_OK
        .elseif wParam == 54
            szText tb5,"Button 5"
            invoke MessageBox,hWin,ADDR tb5,ADDR szDisplayName,MB_OK
        .elseif wParam == 55
            szText tb6,"Button 6"
            invoke MessageBox,hWin,ADDR tb6,ADDR szDisplayName,MB_OK

    ;======== menu commands ========
        .elseif wParam == 1000
           jmp @F
             szTitleO   db "Open A File",0
             szFilterO  db "All files",0,"*.*",0,
                           "Text files",0,"*.TEXT",0,0
           @@:
    
           invoke FillBuffer,ADDR szFileName,length szFileName,0
           invoke GetFileName,hWin,ADDR szTitleO,ADDR szFilterO
    
           cmp szFileName[0],0   ;<< zero if cancel pressed in dlgbox
           je @F
           ; file name returned in szFileName
           invoke MessageBox,hWin,ADDR szFileName,
                             ADDR szDisplayName,MB_OK
           @@:

        .elseif wParam == 1001
           jmp @F
             szTitleS   db "Save file as",0
             szFilterS  db "All files",0,"*.*",0,
                           "Text files",0,"*.TEXT",0,0
           @@:
    
           invoke FillBuffer,ADDR szFileName,length szFileName,0
           invoke SaveFileName,hWin,ADDR szTitleS,ADDR szFilterS
    
           cmp szFileName[0],0   ;<< zero if cancel pressed in dlgbox
           je @F
           ; file name returned in szFileName
           invoke MessageBox,hWin,ADDR szFileName,
                             ADDR szDisplayName,MB_OK
           @@:

        .elseif wParam == 1010
            invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL
        .elseif wParam == 1900
            szText AboutMsg,"MASM32 Pure Assembler Template",13,10,\
            "Copyright © MASM32 1999"
            invoke ShellAbout,hWin,ADDR szDisplayName,ADDR AboutMsg,hIcon
        .endif
    ;====== end menu commands ======

    .elseif uMsg == WM_SYSCOLORCHANGE
        invoke Do_ToolBar,hWin

    .elseif uMsg == WM_CREATE
        invoke Do_ToolBar,hWin

        invoke CreateStatusWindow,WS_CHILD or WS_VISIBLE or \
                                  SBS_SIZEGRIP,NULL, hWin, 200
        mov hStatus, eax
        
      ; -------------------------------------
      ; sbParts is a DWORD array of 4 members
      ; -------------------------------------
        mov [sbParts + 0],  100    ; 1st member, pixels from edge
        mov [sbParts + 4],  200    ; 2nd member, pixels from edge
        mov [sbParts + 8],  300    ; 3rd member, pixels from edge
        mov [sbParts +12],   -1    ; 4th member, furthest right side

        invoke SendMessage,hStatus,SB_SETPARTS,4,ADDR sbParts

    .elseif uMsg == WM_SIZE
        invoke SendMessage,hToolBar,TB_AUTOSIZE,0,0
        invoke MoveWindow,hStatus,0,0,0,0,TRUE

    .elseif uMsg == WM_CLOSE
        szText TheText,"Please Confirm Exit"
        invoke MessageBox,hWin,ADDR TheText,ADDR szDisplayName,MB_YESNO
          .if eax == IDNO
            return 0
          .endif

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; ########################################################################

GetFileName proc hParent:DWORD,lpTitle:DWORD,lpFilter:DWORD

    mov ofn.lStructSize,        sizeof OPENFILENAME
    m2m ofn.hWndOwner,          hParent
    m2m ofn.hInstance,          hInstance
    m2m ofn.lpstrFilter,        lpFilter
    m2m ofn.lpstrFile,          offset szFileName
    mov ofn.nMaxFile,           sizeof szFileName
    m2m ofn.lpstrTitle,         lpTitle
    mov ofn.Flags,              OFN_EXPLORER or OFN_FILEMUSTEXIST or \
                                OFN_LONGNAMES

    invoke GetOpenFileName,ADDR ofn

    ret

GetFileName endp

; #########################################################################

SaveFileName proc hParent:DWORD,lpTitle:DWORD,lpFilter:DWORD

    mov ofn.lStructSize,        sizeof OPENFILENAME
    m2m ofn.hWndOwner,          hParent
    m2m ofn.hInstance,          hInstance
    m2m ofn.lpstrFilter,        lpFilter
    m2m ofn.lpstrFile,          offset szFileName
    mov ofn.nMaxFile,           sizeof szFileName
    m2m ofn.lpstrTitle,         lpTitle
    mov ofn.Flags,              OFN_EXPLORER or OFN_LONGNAMES
                                
    invoke GetSaveFileName,ADDR ofn

    ret

SaveFileName endp

; ########################################################################

FillBuffer proc lpBuffer:DWORD,lenBuffer:DWORD,TheChar:BYTE

    push edi

    mov edi, lpBuffer   ; address of buffer
    mov ecx, lenBuffer  ; buffer length
    mov  al, TheChar    ; load al with character
    rep stosb           ; write character to buffer until ecx = 0

    pop edi

    ret

FillBuffer endp

; ########################################################################

SetBmpColor proc hBitmap:DWORD

    LOCAL mDC       :DWORD
    LOCAL hBrush    :DWORD
    LOCAL hOldBmp   :DWORD
    LOCAL hReturn   :DWORD
    LOCAL hOldBrush :DWORD

      invoke CreateCompatibleDC,NULL
      mov mDC,eax

      invoke SelectObject,mDC,hBitmap
      mov hOldBmp,eax

      invoke GetSysColor,COLOR_BTNFACE
      invoke CreateSolidBrush,eax
      mov hBrush,eax

      invoke SelectObject,mDC,hBrush
      mov hOldBrush,eax

      invoke GetPixel,mDC,1,1
      invoke ExtFloodFill,mDC,1,1,eax,FLOODFILLSURFACE

      invoke SelectObject,mDC,hOldBrush
      invoke DeleteObject,hBrush

      invoke SelectObject,mDC,hBitmap
      mov hReturn,eax
      invoke DeleteDC,mDC

      mov eax,hReturn

    ret

SetBmpColor endp

; ########################################################################

Do_ToolBar proc hWin :DWORD

    LOCAL bSize :DWORD
    LOCAL tbab  :TBADDBITMAP
    LOCAL tbb   :TBBUTTON

    szText tbClass,"ToolbarWindow32"

    invoke CreateWindowEx,0,
                          ADDR tbClass,
                          ADDR szDisplayName,
                          WS_CHILD or WS_VISIBLE,  ; or TBSTYLE_FLAT,
                          0,0,500,40,
                          hWin,NULL,
                          hInstance,NULL
    mov hToolBar, eax

    invoke SendMessage,hToolBar,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0

    ; ---------------------------------------
    ; Put width & height of bitmap into DWORD
    ; ---------------------------------------
    mov  ecx,25  ; loword = bitmap Width
    mov  eax,25  ; hiword = bitmap Height
    shl  eax,16
    mov  ax, cx

    mov bSize, eax

    invoke SendMessage,hToolBar,TB_SETBITMAPSIZE,0,bSize

    ; ------------------
    ; the toolbar bitmap
    ; ------------------
    invoke LoadBitmap,hInstance,750
    mov hTbBmp,eax

    invoke SetBmpColor,hTbBmp
    mov hTbBmp,eax
    mov tbab.hInst, 0
    m2m tbab.nID,   hTbBmp
    invoke SendMessage,hToolBar,TB_ADDBITMAP,12,ADDR tbab

    invoke SendMessage,hToolBar,TB_SETBUTTONSIZE,0,bSize

    mov tbb.fsState,   TBSTATE_ENABLED
    mov tbb.dwData,    0
    mov tbb.iString,   0

    mov tbb.iBitmap,   0
    mov tbb.idCommand, 0
    mov tbb.fsStyle,   TBSTYLE_SEP
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    mov tbb.iBitmap,   0
    mov tbb.idCommand, 50
    mov tbb.fsStyle,   TBSTYLE_BUTTON
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    mov tbb.iBitmap,   1
    mov tbb.idCommand, 51
    mov tbb.fsStyle,   TBSTYLE_BUTTON
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    mov tbb.iBitmap,   2
    mov tbb.idCommand, 52
    mov tbb.fsStyle,   TBSTYLE_BUTTON
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    mov tbb.iBitmap,   0
    mov tbb.idCommand, 0
    mov tbb.fsStyle,   TBSTYLE_SEP
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    mov tbb.iBitmap,   3
    mov tbb.idCommand, 53
    mov tbb.fsStyle,   TBSTYLE_BUTTON
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    mov tbb.iBitmap,   4
    mov tbb.idCommand, 54
    mov tbb.fsStyle,   TBSTYLE_BUTTON
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    mov tbb.iBitmap,   5
    mov tbb.idCommand, 55
    mov tbb.fsStyle,   TBSTYLE_BUTTON
    invoke SendMessage,hToolBar,TB_ADDBUTTONS,1,ADDR tbb

    ret

Do_ToolBar endp

; ########################################################################

end start