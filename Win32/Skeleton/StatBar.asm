        TITLE   Status Bar
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
hStatusBar  HWND    ?
szStatusBar SBYTE   40h DUP (?)
bSimpleMode DWORD   ?             ; Simple Status Bar TRUE/FALSE


;====================================================================;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CODE

;--------------------------------------------------------------------;
;   PROC CreateSBar                                                  ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
CreateSBar  PROC    STDCALL
        INVOKE  CreateStatusWindow, WS_CHILD + WS_BORDER + WS_VISIBLE,\
                     ADDR szStatusBar, hWnd, ID_STATUSBAR
        mov    hStatusBar, eax
        ret
CreateSBar  ENDP


;--------------------------------------------------------------------;
;   PROC MsgWM_MENUSELECT                                            ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MsgWM_MENUSELECT PROC   STDCALL
        xor     eax, eax          ; Clear Status Text
        mov     DWORD PTR szStatusBar, eax

        mov     eax, wParam       ; fuFlags = HIWORD wParam
        shr     eax, 10h

        cmp     eax, 0FFFFh
        jne     caseMENUOPEN
        mov     ecx, lParam       ; hMenu = lParam
        test    ecx, ecx          ; NULL (ecx=0) if menu is closed
        jnz     caseMENUOPEN
        mov     bSimpleMode, FALSE
        INVOKE  SendMessage, hStatusBar, SB_SIMPLE, FALSE, 0
        jmp     caseRETURN

caseMENUOPEN:
        test    eax, MFT_SEPARATOR
        jnz     caseUPDATE
        test    eax, MF_POPUP
        jnz     casePOPUP
        jmp     caseCOMMAND

casePOPUP:
        test    eax, MF_SYSMENU ; System Menu
        jnz     caseSYSMENU
        mov     eax, wParam       ; Menu Index = LOWORD wParam
        add     eax, IDM_FILEMENU
        jmp     caseSTRING

caseSYSMENU:
        mov     eax, IDS_SYSMENU
        jmp     caseSTRING

caseCOMMAND:
        mov     eax, wParam       ; CommandID = LOWORD wParam
        and     eax, 0FFFFh       ; eax = StatusBar StringID

caseSTRING:
        INVOKE  LoadString, hInst, eax, ADDR szStatusBar, 40h

caseUPDATE:
        mov     eax, TRUE
        cmp     bSimpleMode, eax    ; eax=TRUE
        je      caseDISPLAY
        mov     bSimpleMode, eax    ; eax=TRUE
        INVOKE  SendMessage, hStatusBar, SB_SIMPLE, eax, 0h

caseDISPLAY:
        INVOKE  SendMessage, hStatusBar, SB_SETTEXT, \
                              0FFh + SBT_NOBORDERS, ADDR szStatusBar
caseRETURN:
        ret

MsgWM_MENUSELECT ENDP

        END
