        TITLE   About
        INCLUDE COMMON.INC

;--------------------------------------------------------------------;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
        .CODE


;--------------------------------------------------------------------;
;   PROC About                                                       ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
About   PROC    STDCALL, hDlg:HWND, uMsg:UINT, wParam:WPARAM, \
                        lParam:LPARAM
        mov     eax, uMsg
        cmp     eax, WM_INITDIALOG
        je      caseWM_INITDIALOG
        cmp     eax, WM_COMMAND
        je      caseWM_COMMAND

caseDEFAULT:    
        mov     eax, FALSE  ;message not processed
        jmp     caseRETURN

caseWM_INITDIALOG:
        INVOKE  MiscCenterWnd, hDlg, hMainWnd
        jmp     caseBREAK

caseWM_COMMAND: 
        mov     eax, wParam
        cmp     eax, IDOK
        je      caseEND
        cmp     eax, IDCANCEL
        je      caseEND
        jmp     caseDEFAULT

caseEND:    
        INVOKE  EndDialog, hDlg, TRUE

caseBREAK:  
        mov     eax, TRUE   ;message processed

caseRETURN: 
        ret

About   ENDP
        END
