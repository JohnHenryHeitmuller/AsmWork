        TITLE   Misc
        INCLUDE COMMON.INC


;====================================================================;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CODE


;--------------------------------------------------------------------;
;   PROC MiscCenterWnd                                               ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
MiscCenterWnd   PROC    STDCALL, hChild:HWND, hParent:HWND
        LOCAL   rcP:RECT, rcC:RECT
        LOCAL   xNew:DWORD, yNew:DWORD

        INVOKE  GetWindowRect, hParent, ADDR rcP
        test    eax,eax
        jz      caseRETURN

        INVOKE  GetWindowRect, hChild, ADDR rcC
        test    eax,eax
        jz      caseRETURN

        mov     eax, rcP.right      ;center horizontally
        sub     eax, rcP.left       ;x=Px+(Pdx-Cdx)/2
        sub     eax, rcC.right
        add     eax, rcC.left
        sar     eax, 1h
        add     eax, rcP.left
        jns     @F                  ;check if off screen at left
        xor     eax, eax
@@:     mov     xNew, eax

        INVOKE  GetSystemMetrics, SM_CXFULLSCREEN
        sub     eax, rcC.right
        add     eax, rcC.left
        cmp     eax, xNew           ;check if off screen at right
        ja      @F
        mov     xNew, eax

@@:     mov     eax, rcP.bottom     ;center vertically
        sub     eax, rcP.top        ;y=Py+(Pdy-Cdy)/2
        sub     eax, rcC.bottom
        add     eax, rcC.top
        sar     eax, 1h
        add     eax, rcP.top
        jns     @F                  ;check if off screen at top
        xor     eax, eax
@@:     mov     yNew, eax

        INVOKE  GetSystemMetrics, SM_CYFULLSCREEN
        sub     eax,rcC.bottom
        add     eax,rcC.top
        cmp     eax,yNew            ;check if off screen at bottom
        ja      @F
        mov     yNew,eax

@@:     INVOKE  SetWindowPos, hChild, NULL,\
            xNew, yNew, 0h, 0h, SWP_NOSIZE + SWP_NOZORDER
caseRETURN: 
        ret

MiscCenterWnd   ENDP
        END
