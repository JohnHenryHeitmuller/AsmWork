;
;	________________________________________________________________
;
;	                          NetEnum.asm
;	             Enumerate Network File Services V1.00
;	        03-10-1996 Sven B. Schreiber sbs@psbs.franken.de
;	                 This is Public Domain Software
;	________________________________________________________________
;
;
;
;==============================================================================
;
; Assembly Instructions
; ---------------------
;
; Use MASM 6.11 to assemble this file.
; Recommended MASM command line: ml /I. /Zm /c /Cp /Ta NetEnum.asm
;
;==============================================================================
;
; Disclaimer
; ----------
;
; This software is provided "as is" and any expressed or implied warranties,
; including, but not limited to, the implied warranties of merchantibility and
; fitness for a particular purpose are disclaimed. In no event shall the
; author Sven B. Schreiber be liable for any direct, indirect, incidental,
; special, exemplary, or consequential damages (including, but not limited to,
; procurement of substitute goods or services; loss of use, data, or profits;
; or business interruption) however caused and on any theory of liability,
; whether in contract, strict liability, or tort (including negligence or
; otherwise) arising in any way out of the use of this software, even if
; advised of the possibility of such damage.
;
;==============================================================================
;
CONSOLE			equ	1		;0 = gui, 1 = console
UNICODE			equ	0		;0 = ansi, 1 = unicode
DLL			equ	0		;0 = application, 1 = dll
WIN95			equ	0		;0 = windows nt, 1 = windows 95
;
;==============================================================================
;
	include	W32Main.inc			;Win32 main header file
;
;==============================================================================
;
IMPORT			"NT"			;import library list
;
;------------------------------------------------------------------------------
;
DEFAULT_ICON		equ	101		;application icon id
;
;==============================================================================
;
;	CONSTANTS
;
;==============================================================================
;
LF			equ	0Ah		;linefeed
CR			equ	0Dh		;carriage return
;
;==============================================================================
;
;	MAIN SEGMENT
;
;==============================================================================
;
BeginImage	_main, text, data
;
;==============================================================================
;
;	.TEXT SECTION
;
;==============================================================================
;
BeginCode
;
;------------------------------------------------------------------------------
;
	include	W32Start.inc			;Win32 startup code
;
;==============================================================================
;
;	MAIN PROGRAM BODY
;
;==============================================================================
;
;	>	[esp+04]  ->  [ebp+08]  -  hInstance
;		[esp+08]  ->  [ebp+12]  -  pEnvironment
;		[esp+12]  ->  [ebp+16]  -  pCmdLine
;		[esp+16]  ->  [ebp+20]  -  dCmdShow
;
;	<			   eax  -  return code
;
;------------------------------------------------------------------------------
;
WinMain:
	WinMainPrologue
	Win32	GetStdHandle,\			;get standard input handle
		STD_INPUT_HANDLE
	mov	hStdInput,eax
	cmp	eax,INVALID_HANDLE_VALUE
	jz	WinMain1
	Win32	GetStdHandle,\			;get standard output handle
		STD_OUTPUT_HANDLE
	mov	hStdOutput,eax
	cmp	eax,INVALID_HANDLE_VALUE
	jz	WinMain1
	Win32	GetStdHandle,\			;get standard error handle
		STD_ERROR_HANDLE
	mov	hStdError,eax
	cmp	eax,INVALID_HANDLE_VALUE
	jz	WinMain1
	call	EnumerateResources		;enumerate network connections
	call	DisplayStatus
WinMain1:
	mov	eax,0				;load return code
	WinMainEpilogue
;
;==============================================================================
;
;	<	eax  -  status code
;
;------------------------------------------------------------------------------
;
EnumerateResources:
	mov	dUserName,sUserName_		;get user name
	Win32	WNetGetUser,\
		NULL,\
		<offset sUserName>,\
		<offset dUserName>
	cmp	eax,NO_ERROR			;error?
	jnz	EnumerateResources4
	mov	esi,offset sListCaption		;start list caption
	call	OutputString
	push	esi
	mov	esi,offset sUserName		;insert user name
	call	OutputString
	pop	esi
	call	OutputString			;end list caption
	Win32	WNetOpenEnum,\			;start enumeration
		RESOURCE_CONNECTED,\
		RESOURCETYPE_DISK,\
		RESOURCEUSAGE_CONNECTABLE,\
		NULL,\
		<offset hEnumResource>
	cmp	eax,NO_ERROR			;error?
	jnz	EnumerateResources4
	mov	esi,offset sNone
EnumerateResources1:
	push	esi
	mov	dEnumResourceCount,-1		;enumerate resources
	mov	dEnumResourceBufferSize,EnumResourceBuffer_
	Win32	WNetEnumResource,\
		hEnumResource,\
		<offset dEnumResourceCount>,\
		<offset EnumResourceBuffer>,\
		<offset dEnumResourceBufferSize>
	pop	esi
	cmp	eax,ERROR_NO_MORE_ITEMS		;done?
	jz	EnumerateResources3
	cmp	eax,NO_ERROR			;error?
	jnz	EnumerateResources3
	mov	ebx,offset EnumResourceBuffer	;dump resource buffer
	mov	ecx,dEnumResourceCount
	jecxz	EnumerateResources1		;empty buffer
	mov	esi,offset sNewLine
EnumerateResources2:
	push	esi
	push	ecx
	push	ebx
	mov	esi,offset sOutputForm		;start output form
	call	OutputString
	pop	ebx
	push	ebx
	push	esi
	mov	esi,[ebx.nr_lpLocalName]	;display local name
	call	OutputString
	pop	esi
	call	OutputString			;continue output form
	pop	ebx
	push	ebx
	push	esi
	mov	esi,[ebx.nr_lpRemoteName]	;display remote name
	call	OutputString
	pop	esi
	call	OutputString			;end output form
	pop	ebx
	pop	ecx
	pop	esi
	add	ebx,NETRESOURCE_
	loop	EnumerateResources2
	jmp	EnumerateResources1
EnumerateResources3:
	mov	edx,eax				;save status code
	push	edx
	call	OutputString			;new line if data displayed
	Win32	WNetCloseEnum,\			;end enumeration
		hEnumResource
	pop	edx
	cmp	edx,ERROR_NO_MORE_ITEMS		;enumeration completed?
	jz	EnumerateResources4
	cmp	edx,NO_ERROR			;previous error?
	jz	EnumerateResources4
	mov	eax,edx				;return previous status code
EnumerateResources4:
	ret
;
;==============================================================================
;
;	>	eax  -  status code
;
;------------------------------------------------------------------------------
;
DisplayStatus:
	push	eax
	mov	esi,offset sStatus		;start status message
	call	OutputString
	pop	eax
	push	esi
	cmp	eax,NO_ERROR			;normal end?
	mov	esi,offset sNormalEnd
	jz	DisplayStatus1
	mov	esi,offset sWNetError		;wnet error
DisplayStatus1:
	call	OutputString			;insert status string
	pop	esi
	jmp	OutputString			;end status message
;
;==============================================================================
;
;	>	esi  -  string
;
;	<	esi  -  next address
;
;------------------------------------------------------------------------------
;
OutputString:
;
	if	UNICODE
	push	esi
	Win32	WideCharToMultiByte,\		;convert unicode -> ansi
		CP_ACP,\
		0,\
		esi,\
		-1,\
		NULL,\
		0,\
		NULL,\
		NULL
	mov	ecx,eax
	push	ecx
	Win32	LocalAlloc,\
		LMEM_FIXED,\
		ecx
	pop	ecx
	pop	esi
	cmp	eax,NULL
	jz	OutputString3
	push	eax
	push	esi
	Win32	WideCharToMultiByte,\		;convert unicode -> ansi
		CP_ACP,\
		0,\
		esi,\
		-1,\
		eax,\
		ecx,\
		NULL,\
		NULL
	pop	esi
	shl	eax,1				;compute next address
	add	esi,eax
	pop	eax
	push	esi
	push	eax
	mov	esi,eax				;use ansi string
	endif
;
	mov	ebx,esi				;seek string terminator
OutputString1:
	inc	ebx
	cmp	byte ptr [ebx-1],0
	jnz	OutputString1
	push	ebx
	dec	ebx				;compute string length
	sub	ebx,esi
	jz	OutputString2
	Win32	WriteFile,\			;display string
		hStdOutput,\
		esi,\
		ebx,\
		<offset dWriteFileCount>,\
		NULL
OutputString2:
	pop	esi				;load next address
;
	if	UNICODE
	pop	eax
	Win32	LocalFree,\
		eax
	pop	esi				;load next address
OutputString3:
	endif
;
	ret
;
;==============================================================================
;
EndCode
;
;==============================================================================
;
;	.DATA SECTION
;
;==============================================================================
;
BeginData
;
;==============================================================================
;
;	INITIALIZED DATA
;
;------------------------------------------------------------------------------
;
sMainCaption:		STRING	<SBS NetEnum V1.00/0>
sListCaption:		STRING	</nRemote drives of user /=/0/=:/n/0>
;
sStatus:		STRING	</nNetEnum: /0/n/0>
sNormalEnd:		STRING	<Normal end./0>
sWNetError:		STRING	<WNet error./0>
;
sOutputForm:		STRING	</n/0 -/) /=/0/=/0>
sNone:			STRING	</n+++ NONE +++/n/0>
sNewLine:		STRING	</n/0>
;
;==============================================================================
;
EndIData
;
;==============================================================================
;
;	UNINITIALIZED DATA
;
;------------------------------------------------------------------------------
;
OsVersionInfo		OSVERSIONINFO {}
StartupInfo		STARTUPINFO {}
sLoadFile		CHAR MAX_PATH dup (?)
;
;------------------------------------------------------------------------------
;
hStdInput		HANDLE	?
hStdOutput		HANDLE	?
hStdError		HANDLE	?
dWriteFileCount		DWORD	?	
;
;------------------------------------------------------------------------------
;
sUserName_		equ	0100h
sUserName		CHAR	sUserName_ dup (?)
dUserName		DWORD	?
;
;------------------------------------------------------------------------------
;
hEnumResource		HANDLE	?
dEnumResourceCount	DWORD	?
dEnumResourceBufferSize	DWORD	?
;
EnumResourceBuffer_	equ	8000h
EnumResourceBuffer	BYTE	EnumResourceBuffer_ dup (?)
;
;==============================================================================
;
EndUData
;
;==============================================================================
;
EndImage

