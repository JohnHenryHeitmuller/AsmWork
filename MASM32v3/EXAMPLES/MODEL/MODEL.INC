; #########################################################################

;     include files
;     ~~~~~~~~~~~~~
      include \masm32\include\windows.inc
      include \masm32\include\gdi32.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \masm32\include\Comctl32.inc
      include \masm32\include\comdlg32.inc
      include \masm32\include\shell32.inc

;     libraries
;     ~~~~~~~~~
      includelib \masm32\lib\gdi32.lib
      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \masm32\lib\Comctl32.lib
      includelib \masm32\lib\comdlg32.lib
      includelib \masm32\lib\shell32.lib

; #########################################################################

        ;=================
        ; Local prototypes
        ;=================
        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD
        GetFileName  PROTO :DWORD,:DWORD,:DWORD
        SaveFileName PROTO :DWORD,:DWORD,:DWORD
        FillBuffer   PROTO :DWORD,:DWORD,:BYTE
        SetBmpColor  PROTO :DWORD
        Do_ToolBar   PROTO :DWORD

      ;=============
      ; Local macros
      ;=============

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      return MACRO arg
        mov eax, arg
        ret
      ENDM


    .data
        szDisplayName db "MASM32 Model",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0
        hIcon         dd 0
        hTbBmp        dd 0
        hToolBar      dd 0
        hStatus       dd 0
        szFileName    db 260 dup(0)
        ofn           OPENFILENAME <>  ; structure


