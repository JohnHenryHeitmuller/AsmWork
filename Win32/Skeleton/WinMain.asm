        TITLE   WinMain
        INCLUDE COMMON.INC

;====================================================================;
;   SEGMENT .CONST                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CONST
szClassName    SBYTE    "Skeleton",0h


;====================================================================;
;   SEGMENT .DATA?                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .DATA?
hInst           HINSTANCE ?
lpCmdLine       LPSTR ?
nCmdShow        SDWORD ?

szWindowName    SBYTE   (MAX_PATH + 10h) DUP (0h)

hMainWnd        HWND ?
hAccel          HACCEL ?


;====================================================================;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CODE


;--------------------------------------------------------------------;
;  Program entry point                                               ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
Start:
        INVOKE  GetModuleHandle, NULL
        mov     hInst, eax
        INVOKE  GetCommandLine
        mov     lpCmdLine, eax
        mov     nCmdShow, SW_SHOWDEFAULT

        INVOKE  WinMain, hInst, 0h, lpCmdLine, nCmdShow
        INVOKE  ExitProcess, eax    ;eax=Exit Code

;--------------------------------------------------------------------;
;   PROC OnlyOneInstance                                             ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
OnlyOneInstance PROC    STDCALL
        LOCAL   hSemaphore:HANDLE

        INVOKE  CreateSemaphore, NULL, 0h, 1h, ADDR szClassName
        mov     hSemaphore, eax

        INVOKE  GetLastError
        cmp     eax, ERROR_ALREADY_EXISTS
        je      caseEXISTS
        cmp     eax, ERROR_SUCCESS
        je      caseONLYONE         ; if not equal then CreateSemaphore failed so
        jmp     caseFIND            ;  return FALSE to exit by trying FindWindow

caseONLYONE:    
        mov     eax, TRUE           ; created Semaphore will prevent other instances
        jmp     caseRETURN          ; return TRUE to continue

caseEXISTS:
        INVOKE  CloseHandle, hSemaphore

caseFIND:
        INVOKE  FindWindow, ADDR szClassName, NULL
        test    eax, eax
        jz      caseRETURN          ; return FALSE (eax=0) to exit

        INVOKE  GetLastActivePopup, eax
        mov     hMainWnd, eax       ; eax=hMainWnd or hPopupWnd

        INVOKE  IsIconic, hMainWnd
        test    eax, eax
        jz      @F

        INVOKE  ShowWindow, hMainWnd, SW_RESTORE
        xor     eax, eax
        jmp     caseRETURN          ; return FALSE (eax=0) to exit

@@:     INVOKE  SetForegroundWindow, hMainWnd
        xor     eax, eax            ; return FALSE (eax=0) to exit

caseRETURN:
        ret
OnlyOneInstance ENDP


;--------------------------------------------------------------------;
;   PROC Initialization                                              ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
Initialization  PROC    STDCALL
        LOCAL   wcex:WNDCLASSEX

        mov     wcex.cbSize, SIZEOF(WNDCLASSEX)
        mov     wcex.style, CS_HREDRAW + CS_VREDRAW
        mov     wcex.lpfnWndProc, OFFSET WndProc
        xor     eax, eax
        mov     wcex.cbClsExtra, eax
        mov     wcex.cbWndExtra, eax

        mov     eax, hInst
        mov     wcex.hInstance, eax

        INVOKE  LoadIcon, hInst, IDI_ICON
        mov     wcex.hIcon, eax

        INVOKE  LoadCursor, NULL, IDC_ARROW
        mov     wcex.hCursor, eax

        mov     wcex.hbrBackground, COLOR_WINDOW + 1
        mov     wcex.lpszMenuName, IDM_MENU
        mov     wcex.lpszClassName, OFFSET szClassName

        INVOKE  LoadImage, hInst, IDI_ICON, IMAGE_ICON, 16, 16, NULL
        mov     wcex.hIconSm, eax

        INVOKE  RegisterClassEx, ADDR wcex
        test    eax, eax
        jz      caseRETURN         ; return FALSE (eax=0) to exit

        INVOKE  CreateWindowEx, NULL,\
                    ADDR szClassName, ADDR szClassName,\
                    WS_OVERLAPPEDWINDOW,\
                    0h, 0h, 1A0h, 180h, NULL, NULL, hInst, NULL
        test    eax, eax
        jz      caseRETURN         ; return FALSE (eax=0) to exit
        mov     hMainWnd,eax

        INVOKE  ShowWindow, hMainWnd, nCmdShow
        INVOKE  UpdateWindow, hMainWnd

caseRETURN:
      ret
Initialization  ENDP


;--------------------------------------------------------------------;
;   PROC WinMain                                                     ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
WinMain     PROC    STDCALL,    hInstance:HINSTANCE, \
                                hPrevInstance:HINSTANCE, \
                                pCmdLine:LPSTR, CmdShow:SDWORD
        LOCAL   msg:MSG

        call    OnlyOneInstance
        test    eax, eax
        jz      caseRETURN

        call    Initialization
        test    eax, eax
        jz      caseRETURN

        INVOKE  LoadAccelerators, hInst, IDA_ACCEL
        test    eax, eax
        jz      caseRETURN
        mov     hAccel,eax

MessageLoop:
        INVOKE  GetMessage, ADDR msg, NULL, 0h, 0h
        test    eax,eax             ; FALSE (eax=0) if WM_QUIT
        jz      caseWM_QUIT

        INVOKE  TranslateAccelerator, msg.hwnd, hAccel, ADDR msg
        test    eax,eax
        jnz     MessageLoop

        INVOKE  TranslateMessage, ADDR msg
        INVOKE  DispatchMessage, ADDR msg
        jmp     MessageLoop

caseWM_QUIT:
        mov     eax, msg.wParam     ; wParam=Exit Code

caseRETURN:
        ret

WinMain         ENDP

        END     Start
