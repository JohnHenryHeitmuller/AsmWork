        TITLE   Toolbar & Tooltips
        INCLUDE COMMON.INC

hWnd        TEXTEQU <[ebp+08h]>
uMsg        TEXTEQU <[ebp+0Ch]>
wParam      TEXTEQU <[ebp+10h]>
lParam      TEXTEQU <[ebp+14h]>


;====================================================================;
;   SEGMENT .CONST                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CONST
tbButtons   TBBUTTON <STD_FILENEW,  IDM_NEW,  TBSTATE_ENABLED, \
                        TBSTYLE_BUTTON, 0h, 0h>
            TBBUTTON <STD_FILEOPEN, IDM_OPEN, TBSTATE_ENABLED, \
                        TBSTYLE_BUTTON, 0h, 0h>
            TBBUTTON <STD_FILESAVE, IDM_SAVE, TBSTATE_ENABLED, \
                        TBSTYLE_BUTTON, 0h, 0h>


;====================================================================;
;   SEGMENT .DATA?                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .DATA?
hToolBar    HWND    ?
szToolTip   SBYTE   10h DUP (?)


;====================================================================;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CODE


;--------------------------------------------------------------------;
;   PROC CreateTBar                                                  ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
CreateTBar  PROC    STDCALL
        INVOKE  CreateToolbarEx, hWnd,\
            WS_CHILD + WS_BORDER + WS_VISIBLE + TBSTYLE_TOOLTIPS,\
            ID_TOOLBAR, 0Bh, HINST_COMMCTRL, IDB_STD_SMALL_COLOR,\
            ADDR tbButtons, 3h, 10h, 10h, 10h, 10h, SIZEOF(TBBUTTON)
        mov     hToolBar,eax
        ret
CreateTBar  ENDP


;--------------------------------------------------------------------;
;   PROC NtfTTN_NEEDTEXT                                             ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
NtfTTN_NEEDTEXT PROC    STDCALL
        mov     eax, lParam
        mov     eax, (TOOLTIPTEXT PTR [eax]).hdr.idFrom
        add     eax, 80h            ;eax=Tooltip StringID
        INVOKE  LoadString, hInst, eax, ADDR szToolTip, 10h

        mov     eax, lParam
        mov     (TOOLTIPTEXT PTR [eax]).lpszText,OFFSET szToolTip
        ret
NtfTTN_NEEDTEXT ENDP

        END
