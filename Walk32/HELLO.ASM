;
;	________________________________________________________________
;
;	                           Hello.asm
;	                  Win32 Demo Application V1.00
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
; Recommended MASM command line: ml /I. /Zm /c /Cp /Ta Hello.asm
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
	mov	esi,offset sHelloWorld		;display text
	call	OutputString
WinMain1:
	mov	eax,0				;load return code
	WinMainEpilogue
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
sMainCaption:		STRING	</=Hello/= Sample Application/0>
sHelloWorld:		STRING	</nHello World /:/:/:/n/0>
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
;==============================================================================
;
EndUData
;
;==============================================================================
;
EndImage

