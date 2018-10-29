        TITLE   WndProc
        INCLUDE COMMON.INC

;====================================================================;
;   SEGMENT .CONST                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CONST
szHelpFile  SBYTE   "Skeleton.hlp",0h


;====================================================================;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CODE


;--------------------------------------------------------------------;
;   PROC WndProc                                                     ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
WndProc     PROC    STDCALL hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
        mov     eax,uMsg

        cmp     eax, WM_MENUSELECT  ;highest Msg ID processed
        ja      caseDEFAULT         ;if above then default
        je      caseWM_MENUSELECT
        cmp     eax, WM_PAINT
        je      caseWM_PAINT
        cmp     eax, WM_SIZE
        je      caseWM_SIZE
        cmp     eax, WM_CREATE
        je      caseWM_CREATE
        cmp     eax, WM_CLOSE
        je      caseWM_CLOSE
        cmp     eax, WM_DESTROY
        je      caseWM_DESTROY
        cmp     eax, WM_NOTIFY
        je      caseWM_NOTIFY       ;process notifications
        cmp     eax, WM_COMMAND
        je      caseWM_COMMAND      ;process menu commands

caseDEFAULT:    
        INVOKE  DefWindowProc, hWnd, uMsg, wParam, lParam
        jmp     caseRETURN

caseWM_MENUSELECT:
        call    MsgWM_MENUSELECT
        jmp     caseRETURN0

caseWM_PAINT:   
        call    MsgWM_PAINT
        jmp     caseRETURN0

caseWM_SIZE:    
        call    MsgWM_SIZE
        jmp     caseRETURN0

caseWM_CREATE:  
        call    MsgWM_CREATE
        jmp     caseRETURN

caseWM_CLOSE:   
        call    MsgWM_CLOSE
        jmp     caseRETURN0

caseWM_DESTROY: 
        INVOKE  WinHelp, hMainWnd, ADDR szHelpFile, HELP_QUIT, 0h
        INVOKE  PostQuitMessage, 0h
        jmp     caseRETURN0


caseWM_NOTIFY:  
        mov     eax, lParam     ;**** Process Notifications ****
        mov     eax, (NMHDR PTR [eax]).code
        cmp     eax, TTN_NEEDTEXT
        je      caseTTN_NEEDTEXT
        jmp     caseDEFAULT

caseTTN_NEEDTEXT:
        call    NtfTTN_NEEDTEXT
        jmp caseRETURN0


caseWM_COMMAND: 
        mov     eax, wParam     ;**** Process Menu Commands ****
        and     eax, 0FFFFh

        cmp     eax, IDM_NEW
        je      caseIDM_NEW
        cmp     eax, IDM_OPEN
        je      caseIDM_OPEN
        cmp     eax, IDM_SAVE
        je      caseIDM_SAVE
        cmp     eax, IDM_SAVEAS
        je      caseIDM_SAVEAS
        cmp     eax, IDM_EXIT
        je      caseWM_CLOSE
        cmp     eax, IDM_HELPTOPICS
        je      caseIDM_HELPTOPICS
        cmp     eax, IDM_ABOUT
        je      caseIDM_ABOUT
        jmp     caseDEFAULT

caseIDM_NEW:    
        call    CmdIDM_NEW
        jmp     caseRETURN0

caseIDM_OPEN:   
        call    CmdIDM_OPEN
        jmp     caseRETURN0

caseIDM_SAVEAS: 
        and     fFileStatus,NOT NAMEDbit

caseIDM_SAVE:   
        call    CmdIDM_SAVE
        jmp     caseRETURN0

caseIDM_HELPTOPICS:
        INVOKE  WinHelp, hMainWnd, ADDR szHelpFile, HELP_FINDER, 0h
        jmp     caseRETURN0

caseIDM_ABOUT:  
        INVOKE  DialogBoxParam, hInst, IDD_ABOUT, hMainWnd, ADDR About, NULL
        jmp     caseRETURN0

caseRETURN0:    
        xor     eax, eax        ;return 0 if message is processed

caseRETURN: 
        ret

WndProc     ENDP

        END
