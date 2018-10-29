        TITLE   CmdFile - Handle file commands from WndProc
        INCLUDE COMMON.INC

hWnd            TEXTEQU <[ebp+08h]>
uMsg            TEXTEQU <[ebp+0Ch]>
wParam          TEXTEQU <[ebp+10h]>
lParam          TEXTEQU <[ebp+14h]>


;====================================================================;
;   SEGMENT .CONST                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CONST
szFilter        SBYTE   "Text Files (*.TXT)",0h,"*.TXT",0h
                SBYTE   "All Files (*.*)",0h,"*.*",0h,0h
szDefExt        SBYTE   "txt",0h


;====================================================================;
;   SEGMENT .DATA                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .DATA
ofn             OPENFILENAME <SIZEOF(OPENFILENAME), NULL, NULL,\
                    OFFSET szFilter, NULL, NULL, 1h,\
                    OFFSET szFile, MAX_PATH,\
                    OFFSET szFileTitle, MAX_PATH,\
                    NULL, NULL, 0h, 0h, 0h,\
                    OFFSET szDefExt, 0h, 0h, 0h>
szSaveChanges   SBYTE   "Save changes to the following file?",0Ah,0Ah
szFile          SBYTE   MAX_PATH DUP (0h)


;====================================================================;
;   SEGMENT .DATA?                                                   ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .DATA?
hFile           HANDLE  ?
fFileStatus     DWORD   ?       ;see COMMON.INC for EQUs
szFileTitle     SBYTE   MAX_PATH DUP (?)


;====================================================================;
;   SEGMENT .CODE                                                    ;
;                                                                    ;
;                                                                    ;
;===================================================================='
        .CODE


;--------------------------------------------------------------------;
;   PROC CmdIDM_NEW                                                  ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
CmdIDM_NEW  PROC    STDCALL
        call    SaveChanges
        test    eax, eax
        jz      caseRETURN

        ;!!!!   !!!!!!!!

        mov     DWORD PTR szFile,"itnU" ;Untitled
        mov     DWORD PTR szFile[4h],"delt"
        xor     eax, eax
        mov     DWORD PTR szFile[8h],eax
        mov     ofn.nFileOffset, ax
        mov     ofn.nFileExtension, 9h
        and     fFileStatus, NOT NAMEDbit
        and     fFileStatus, NOT CHANGEDbit
        call    NewWindowName

caseRETURN: 
        ret
CmdIDM_NEW  ENDP


;--------------------------------------------------------------------;
;   PROC CmdIDM_OPEN                                                 ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
CmdIDM_OPEN PROC    STDCALL
        call    SaveChanges
        test    eax,eax
        jz      caseRETURN

        mov     eax, hMainWnd
        mov     ofn.hwndOwner, eax
        mov     ofn.Flags,OFN_PATHMUSTEXIST + OFN_FILEMUSTEXIST
        INVOKE  GetOpenFileName, ADDR ofn
        test    eax, eax
        jz      caseCANCEL

        ;!!!!   !!!!!!!!

        or      fFileStatus, NAMEDbit
        and     fFileStatus, NOT CHANGEDbit
        call    NewWindowName

        mov     eax, TRUE   ;return TRUE
        jmp     caseRETURN

caseERROR:  
        INVOKE  GetLastError

        ;!!!!   !!!!!!!!

caseCANCEL: 
        xor     eax, eax    ;return FALSE

caseRETURN: 
        ret
CmdIDM_OPEN ENDP


;--------------------------------------------------------------------;
;   PROC CmdIDM_SAVE                                                 ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
CmdIDM_SAVE PROC    STDCALL
        test    fFileStatus, NAMEDbit   ;Does the file need a name?
        jnz     caseSAVE

        mov     eax, hMainWnd   ;Get file name
        mov     ofn. hwndOwner,eax
        mov     ofn.Flags, OFN_HIDEREADONLY + OFN_OVERWRITEPROMPT

        INVOKE  GetSaveFileName, ADDR ofn
        test    eax, eax
        jz      caseCANCEL

caseSAVE:
        ;!!!!   !!!!!!!!

        or      fFileStatus, NAMEDbit
        and     fFileStatus, NOT CHANGEDbit
        call    NewWindowName

        mov     eax, TRUE       ;return TRUE to continue
        jmp     caseRETURN

caseERROR:  
        INVOKE  GetLastError

        ;!!!!   !!!!!!!!
        
caseCANCEL: 
        xor     eax, eax        ;return FALSE to CANCEL NEW or CLOSE

caseRETURN: 
        ret
CmdIDM_SAVE ENDP


;--------------------------------------------------------------------;
;   PROC SaveChanges                                                 ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
SaveChanges PROC    STDCALL
        mov     eax, IDNO

        test    fFileStatus,CHANGEDbit
        jz      caseIDNO

        INVOKE  MessageBox, hMainWnd, ADDR szSaveChanges, \
                    ADDR szClassName,MB_YESNOCANCEL + MB_ICONWARNING
        cmp     eax, IDYES
        je      caseIDYES
        cmp     eax, IDCANCEL
        je      caseIDCANCEL

caseIDNO:   
        mov     eax, TRUE
        jmp     caseRETURN      ;return TRUE to continue

caseIDCANCEL:   
        xor     eax, eax        ;return FALSE to CANCEL
        jmp     caseRETURN

caseIDYES:  
        call    CmdIDM_SAVE     ;returns FALSE to CANCEL or TRUE to continue

caseRETURN: 
        ret
SaveChanges ENDP


;--------------------------------------------------------------------;
;  PROC NewWindowName                                                ;
;                                                                    ;
;                                                                    ;
;--------------------------------------------------------------------'
NewWindowName   PROC    STDCALL USES ESI EDI
        mov     esi, OFFSET szFile
        xor     eax, eax
        mov     ax, ofn.nFileOffset
        add     esi, eax            ;copy filename only
        xor     ecx, ecx
        mov     cx, ofn.nFileExtension
        sub     ecx, eax            ;do not show extension
        mov     edi, OFFSET szWindowName
        rep     movsb

        dec     edi         ;add changed status
        test    fFileStatus, CHANGEDbit
        jz      @F
        mov     BYTE PTR [edi],"*"
        inc     edi
@@:     mov     DWORD PTR [edi],"  - "  ;add application name
        add     edi, 3h
        mov     esi, OFFSET szClassName
        mov     ecx, 9h
        rep     movsb

        INVOKE  SetWindowText, hWnd, ADDR szWindowName

        ret
NewWindowName   ENDP

        END
