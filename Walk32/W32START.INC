;
;	________________________________________________________________
;
;	                          W32Start.inc
;	                    Win32 Startup Code V1.00
;	        03-10-1996 Sven B. Schreiber sbs@psbs.franken.de
;	                 This is Public Domain Software
;	________________________________________________________________
;
;
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
_Win32Startup:
	if	DLL
	LibMainPrologue
	endif
	mov	OsVersionInfo.ov_dwOSVersionInfoSize,OSVERSIONINFO_
	Win32	GetVersionEx,\
		<offset OsVersionInfo>
	if	UNICODE
	call	_TestUnicodeSupport		;test if unicode supported
	jb	_Win32Startup2
	endif
	if	DLL
	Win32	GetModuleFileName,\		;get load file path
		hInstDLL,\
		<offset sLoadFile>,\
		MAX_PATH
	call	LibMain
	jmp	_Win32Startup3
	else
	mov	StartupInfo.si_dwFlags,0	;get startup info
	Win32	GetStartupInfo,\
		<offset StartupInfo>
	test	StartupInfo.si_dwFlags,STARTF_USESHOWWINDOW
	mov	eax,SW_SHOWDEFAULT
	jz	_Win32Startup1
	movzx	eax,StartupInfo.si_wShowWindow
_Win32Startup1:
	push	eax				;pass nCmdShow
	Win32	GetCommandLine			;pass lpCmdLine
	push	eax
	Win32	GetEnvironmentStrings		;pass environment data
	push	eax
	Win32	GetModuleHandle,\		;pass hInstance
		NULL
	push	eax
	Win32	GetModuleFileName,\		;get load file path
		eax,\
		<offset sLoadFile>,\
		MAX_PATH
	call	WinMain				;call main program
	endif
_Win32Startup2:
	if	DLL
	mov	eax,FALSE
_Win32Startup3:
	LibMainEpilogue
	else
	Win32	ExitProcess,\			;terminate program
		eax
	ret
	endif
;
;==============================================================================
;
;	<	eax  -  exit code
;		  c  -  set if unicode not supported
;
;------------------------------------------------------------------------------
;
	if	UNICODE
_TestUnicodeSupport:
	mov	eax,OsVersionInfo.ov_dwPlatformId	;windows nt?
	cmp	eax,VER_PLATFORM_WIN32_NT
	clc						;ok
	jz	_TestUnicodeSupport1
	push	eax
	Win32	MessageBox,\				;display error message
		NULL,\
		<offset _sUnicodeNotSupported>,\
		<offset sMainCaption>,\
		MB_ICONSTOP+MB_OK
	pop	eax
	stc						;error
_TestUnicodeSupport1:
	ret
	endif
;
;==============================================================================
;
	if	UNICODE
_sUnicodeNotSupported:
	STRING	<This application doesn/-t run on your current Win32 >
	STRING	<platform, because it uses the Unicode character set./0>
	endif
;
;==============================================================================

