;By Barry Kauler 1997
;Companion Disk, "Windows Assembly Language & Systems programming".
;W32DEMO.ASM --> W32DEMO.EXE	Windows 95 demo program.
;This skeleton assembly language program has been written for TASM5.0.
;It has the startup code built-in, rather than as a separate object file.

.386
.MODEL FLAT,STDCALL
UNICODE = 0
INCLUDE W32.INC

IDM_QUIT		EQU	100		;menu-identifiers -- must be
IDM_ABOUT		EQU	101		;same as defined in .RC file.


.DATA
;--------------------------------------------------------------------------

hInst		 DD 0
mainhwnd	 DD 0
s1		 WNDCLASS    <?>
s2		 MSG	 <?>
s3	 PAINTSTRUCT <?>
szTitleName	 DB "Win32 Assembly Language Demo Program",0
szClassName	 DB "W32DEMO",0
sziconname	 DB "ICON_1",0	    ;name of icon in .RC file.

g_hwnd	  DWORD 0
g_message   DWORD 0
g_wparam    DWORD 0
g_lparam    DWORD 0

szaboutstr  DB "This is an about-box",0 ;messagebox
sztitlestr  DB "Barry Kauler 1997",0	;/

.CODE
;-----------------------------------------------------------------------------
start:

	call GetModuleHandle, NULL
	mov	hInst, eax

; initialize the WndClass structure
	mov	s1.w_style, CS_HREDRAW + CS_VREDRAW + CS_DBLCLKS
	mov	s1.w_lpfnWndProc, offset ASMWNDPROC
	mov	s1.w_cbClsExtra, 0
	mov	s1.w_cbWndExtra, 0

	mov	eax, hInst
	mov	s1.w_hInstance, eax

;  call LoadIcon, NULL, IDI_APPLICATION	  ;loads default icon.
;let's load a custom icon....
	call LoadIcon, hInst, OFFSET sziconname
	mov	s1.w_hIcon, eax

  call LoadCursor,NULL, IDC_ARROW
	mov	s1.w_hCursor, eax

	mov	s1.w_hbrBackground, COLOR_WINDOW + 1
	mov	s1.w_lpszMenuName, OFFSET szClassName
	mov	s1.w_lpszClassName, OFFSET szClassName

  call RegisterClass, OFFSET s1

    call CreateWindowEx,0,OFFSET szClassName,OFFSET szTitleName, \
	WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,CW_USEDEFAULT, \
	CW_USEDEFAULT,CW_USEDEFAULT, 0, 0, hInst, 0
	mov	mainhwnd, eax

    call ShowWindow, mainhwnd,SW_SHOWNORMAL
    call UpdateWindow, mainhwnd

msg_loop:
    call GetMessage, OFFSET s2, 0,0,0
	cmp	ax, 0
        je      end_loop
    call TranslateMessage, OFFSET s2
    call DispatchMessage, OFFSET s2
	jmp	msg_loop

end_loop:
    call ExitProcess, s2.ms_wParam

;-----------------------------------------------------------------------------
    PUBLIC ASMWNDPROC
ASMWNDPROC proc STDCALL, hwnd:DWORD, wmsg:DWORD, wparam:DWORD, lparam:DWORD
	USES  ebx, edi, esi
	LOCAL	hDC:DWORD

    mov eax,hwnd	    ;useful to make these static.
    mov g_hwnd,eax
    mov eax,wmsg
    mov g_message,eax
    mov eax,wparam
    mov g_wparam,eax
    mov eax,lparam
    mov g_lparam,eax


	xor eax,eax
	mov ax,WORD PTR g_message
	.IF ax==WM_DESTROY
	  call	wmdestroy
	.ELSEIF ax==WM_RBUTTONDOWN
	  call	wmrbuttondown
	.ELSEIF ax==WM_SIZE
	  call	wmsize
	.ELSEIF ax==WM_CREATE
	  call	wmcreate
	.ELSEIF ax==WM_LBUTTONDOWN
	  call	wmlbuttondown
	.ELSEIF ax==WM_PAINT
	  call	wmpaint
	.ELSEIF ax==WM_COMMAND
	  call	wmcommand
	.ELSE
	  call DefWindowProc, hwnd,wmsg,wparam,lparam
	  ret
	.ENDIF
	xor eax,eax
	ret
ASMWNDPROC ENDP
;-----------------------------------------------------------------------------
wmcommand PROC
	mov ax,WORD PTR g_lparam
	.IF ax==0
	  mov  ax,WORD PTR g_wparam
	  .IF ax==IDM_QUIT
	    call PostQuitMessage,0
	  .ELSEIF ax==IDM_ABOUT
	   call MessageBox, g_hwnd, OFFSET szaboutstr, OFFSET sztitlestr, MB_OK
	  .ENDIF
	.ENDIF
    ret
wmcommand ENDP
;------------------------------------------------------------------------
wmpaint PROC
    call BeginPaint, hwnd,OFFSET s3
	mov	hDC, eax


    call EndPaint, hwnd,OFFSET s3
    ret
wmpaint ENDP

wmcreate PROC
    ret
wmcreate ENDP

wmdestroy PROC
    call PostQuitMessage,0
    ret
wmdestroy ENDP

wmlbuttondown PROC
    ret
wmlbuttondown ENDP

wmrbuttondown PROC
    call MessageBeep,0
    ret
wmrbuttondown ENDP

wmsize PROC
    ret
wmsize ENDP

;-----------------------------------------------------------------------------
ends
end start
