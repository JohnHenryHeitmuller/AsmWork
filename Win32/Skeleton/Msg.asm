        TITLE   Msg - Handle messages from WndProc
        INCLUDE COMMON.INC

hWnd        TEXTEQU <[ebp+08h]>
uMsg        TEXTEQU <[ebp+0Ch]>
wParam      TEXTEQU <[ebp+10h]>
lParam      TEXTEQU <[ebp+14h]>


;====================================================================;
;   SEGMENT .DATA?                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .DATA?
hdc         HDC ?       ;for WM_PAINT
ps          PAINTSTRUCT <>


;====================================================================;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CODE


;--------------------------------------------------------------------;
;   PROC MsgWM_PAINT                                                 ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MsgWM_PAINT PROC    STDCALL
        INVOKE  BeginPaint, hWnd, ADDR ps
        mov     hdc, eax

        ;!!!!   !!!!!!!!

        INVOKE  EndPaint, hWnd, ADDR ps
        ret
MsgWM_PAINT ENDP


;--------------------------------------------------------------------;
;   PROC MsgWM_CREATE                                                ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MsgWM_CREATE    PROC    STDCALL
        INVOKE  GetDesktopWindow
        INVOKE  MiscCenterWnd, hWnd, eax    ;Center Main Window

        INVOKE  InitCommonControls

        call    CreateSBar
        test    eax,eax
        jz      caseEXIT

        call    CreateTBar
        test    eax,eax
        jz      caseEXIT

        call    CmdIDM_NEW

        jmp     caseCONTINUE

caseEXIT:   
        xor     eax, eax
        dec     eax
        jmp     caseRETURN      ;return -1 to exit

caseCONTINUE:   
        xor     eax, eax        ;return 0 to continue

caseRETURN: 
        ret
MsgWM_CREATE    ENDP


;--------------------------------------------------------------------;
;   PROC MsgWM_CLOSE                                                 ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MsgWM_CLOSE PROC    STDCALL
        call    SaveChanges
        test    eax, eax        ;CANCEL if FALSE (eax=0)
        jz      caseRETURN

        INVOKE  DestroyWindow, hMainWnd

caseRETURN: 
        ret
MsgWM_CLOSE ENDP


;--------------------------------------------------------------------;
;   PROC MsgWM_SIZE                                                  ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MsgWM_SIZE  PROC    STDCALL
        INVOKE  SendMessage, hStatusBar, uMsg, wParam, lParam
        INVOKE  SendMessage, hToolBar, uMsg, wParam, lParam
        ret
MsgWM_SIZE  ENDP
        END
