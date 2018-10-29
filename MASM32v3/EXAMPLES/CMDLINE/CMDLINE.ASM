; #########################################################################

      .386
      .model flat, stdcall
      option casemap :none   ; case sensitive

; #########################################################################

      include \masm32\include\windows.inc
      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc

      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib

; #########################################################################

    .data
        szBuffer      db 128 dup (0)
        szDlgTitle    db "Command Line Message",0
        cmdline       dd 0

    .code

start:

    invoke GetCommandLine
    mov cmdline, eax

    ; --------------------------------------------------------
    ; The following string stripper relies on the difference
    ; between a command line with NO command tail after it and
    ; a command line with a command tail.
    
    ; The string data returned by GetCommandLine() has the full
    ; path enclosed in the [ " ] character if there is a command
    ; tail and none if only the full path is returned.
    ;  
    ; Run the EXE with no command tail and it will display the
    ; full path and name of the EXE file. Run the EXE with a
    ; command tail and it will display only the command tail.
    ; --------------------------------------------------------

    mov esi, cmdline   ; value returned by GetCommandLine() is address
    mov ecx, 128       ; max command line length
    lea edi, szBuffer  ; load address of buffer
    
  lpStart:
    lodsb              ; load byte into al
    cmp al, 34         ; [ " ] character
    je SubLoop
    
    cmp al, 0          ; if zero terminator exit loop
    je PastIt

    stosb              ; write byte to buffer
    jmp lpStart

  SubLoop:
    lodsb              ; load byte into al
    cmp al, 34         ; [ " ] character
    je lpStart         ; return to main loop

    cmp al, 0          ; if zero terminator exit loop
    je PastIt
    
    jmp SubLoop
    
  PastIt:

    invoke MessageBox,0,ADDR szBuffer,ADDR szDlgTitle,MB_ICONINFORMATION

    ; TheEnd:

    invoke ExitProcess,0

end start