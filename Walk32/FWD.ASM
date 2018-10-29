;
;	________________________________________________________________
;
;	                            FWD.asm
;	                      Forwarder DLL V1.00
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
; Recommended MASM command line: ml /I. /Zm /c /Cp /Ta FWD.asm
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
CONSOLE			equ	0		;0 = gui, 1 = console
UNICODE			equ	0		;0 = ansi, 1 = unicode
DLL			equ	1		;0 = application, 1 = dll
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
;	FORWARDED FUNCTIONS
;
;==============================================================================
;
Forward SHELL32, CheckEscapesA
Forward SHELL32, CheckEscapesW
Forward SHELL32, CommandLineToArgvW
Forward SHELL32, Control_FillCache_RunDLL
Forward SHELL32, Control_RunDLL
Forward SHELL32, DllGetClassObject
Forward SHELL32, DoEnvironmentSubstA
Forward SHELL32, DoEnvironmentSubstW
Forward SHELL32, DragAcceptFiles
Forward SHELL32, DragFinish
Forward SHELL32, DragQueryFile
Forward SHELL32, DragQueryFileA
Forward SHELL32, DragQueryFileAorW
Forward SHELL32, DragQueryFileW
Forward SHELL32, DragQueryPoint
Forward SHELL32, DuplicateIcon
Forward SHELL32, ExtractAssociatedIconA
Forward SHELL32, ExtractAssociatedIconExA
Forward SHELL32, ExtractAssociatedIconExW
Forward SHELL32, ExtractAssociatedIconW
Forward SHELL32, ExtractIconA
Forward SHELL32, ExtractIconEx
Forward SHELL32, ExtractIconExA
Forward SHELL32, ExtractIconResInfoA
Forward SHELL32, ExtractIconResInfoW
Forward SHELL32, ExtractIconW
Forward SHELL32, ExtractVersionResource16W
Forward SHELL32, FindExecutableA
Forward SHELL32, FindExecutableW
Forward SHELL32, FreeIconList
Forward SHELL32, InternalExtractIconListA
Forward SHELL32, InternalExtractIconListW
Forward SHELL32, OpenAs_RunDLL
Forward SHELL32, PrintersGetCommand_RunDLL
Forward SHELL32, RealShellExecuteA
Forward SHELL32, RealShellExecuteExA
Forward SHELL32, RealShellExecuteExW
Forward SHELL32, RealShellExecuteW
Forward SHELL32, RegenerateUserEnvironment
Forward SHELL32, SHAddToRecentDocs
Forward SHELL32, SHAppBarMessage
Forward SHELL32, SHBrowseForFolder
Forward SHELL32, SHBrowseForFolderA
Forward SHELL32, SHChangeNotify
Forward SHELL32, SHFileOperation
Forward SHELL32, SHFileOperationA
Forward SHELL32, SHFormatDrive
Forward SHELL32, SHFreeNameMappings
Forward SHELL32, SHGetDesktopFolder
Forward SHELL32, SHGetFileInfo
Forward SHELL32, SHGetFileInfoA
Forward SHELL32, SHGetInstanceExplorer
Forward SHELL32, SHGetMalloc
Forward SHELL32, SHGetPathFromIDList
Forward SHELL32, SHGetPathFromIDListA
Forward SHELL32, SHGetSpecialFolderLocation
Forward SHELL32, SHHelpShortcuts_RunDLL
Forward SHELL32, SHLoadInProc
Forward SHELL32, SheChangeDirA
Forward SHELL32, SheChangeDirExA
Forward SHELL32, SheChangeDirExW
Forward SHELL32, SheChangeDirW
Forward SHELL32, SheConvertPathW
Forward SHELL32, SheFullPathA
Forward SHELL32, SheFullPathW
Forward SHELL32, SheGetCurDrive
Forward SHELL32, SheGetDirA
Forward SHELL32, SheGetDirExW
Forward SHELL32, SheGetDirW
Forward SHELL32, SheGetPathOffsetW
Forward SHELL32, SheRemoveQuotesA
Forward SHELL32, SheRemoveQuotesW
Forward SHELL32, SheSetCurDrive
Forward SHELL32, SheShortenPathA
Forward SHELL32, SheShortenPathW
Forward SHELL32, ShellAboutA
Forward SHELL32, ShellAboutW
Forward SHELL32, ShellExecuteA
Forward SHELL32, ShellExecuteEx
Forward SHELL32, ShellExecuteExA
Forward SHELL32, ShellExecuteW
Forward SHELL32, Shell_NotifyIcon
Forward SHELL32, Shell_NotifyIconA
;
;==============================================================================
;
;	DLL ENTRY POINT
;
;==============================================================================
;
;	>	[ebp+08]  -  hInstDLL
;		[ebp+12]  -  dReason
;		[ebp+16]  -  dParamDLL
;
;	<	     eax  -  return code
;
;------------------------------------------------------------------------------
;
LibMain:
	mov	eax,dReason			;dispatch init call
	mov	ebx,LibMainTable
	jmp	Dispatcher
;
;------------------------------------------------------------------------------
;
;	DLL INITIALIZATION
;
;------------------------------------------------------------------------------
;
LibMainTable:
;
	DWORD	DLL_PROCESS_ATTACH, DllProcessAttach
	DWORD	DLL_PROCESS_DETACH, DllProcessDetach
	DWORD	DLL_THREAD_ATTACH,  DllThreadAttach
	DWORD	DLL_THREAD_DETACH,  DllThreadDetach
;
	DWORD	-1, DllUnknownReason
;
;------------------------------------------------------------------------------
;
DllProcessAttach:
	mov	eax,hInstDLL			;save dll instance handle
	mov	hInst,eax
	mov	esi,offset sExtDataFile		;get data file path
	mov	edi,offset sDataFile
	mov	ecx,MAX_PATH
	call	GetAssociatedFile
	mov	eax,FALSE
	jb	DllProcessAttach1
	Win32	GetPrivateProfileString,\	;get command to execute
		<offset sSecSettings>,\
		<offset sKeySettingsCommand>,\
		<offset sNull>,\
		<offset sCommand>,\
		sCommand_,\
		<offset sDataFile>
	cmp	eax,0
	mov	eax,FALSE
	jz	DllProcessAttach1
	Win32	CreateProcess,\			;start helper application
		NULL,\
		<offset sCommand>,\
		NULL,\
		NULL,\
		FALSE,\
		NORMAL_PRIORITY_CLASS,\
		NULL,\
		NULL,\
		<offset StartupInfo>,\
		<offset ProcessInformation>
	mov	fProcessAttached,eax		;save and return status
DllProcessAttach1:
	ret
;
;------------------------------------------------------------------------------
;
DllProcessDetach:
	cmp	fProcessAttached,FALSE		;process attached?
	jz	DllProcessDetach1
	Win32	PostThreadMessage,\		;terminate helper application
		ProcessInformation.pi_dwThreadId,\
		WM_QUIT,\
		0,\
		NULL
	mov	fProcessAttached,FALSE		;process detached
DllProcessDetach1:
	mov	eax,TRUE			;ok
	ret
;
;------------------------------------------------------------------------------
;
DllThreadAttach:
DllThreadDetach:
	mov	eax,TRUE			;ok
	ret
;
;------------------------------------------------------------------------------
;
DllUnknownReason:
	mov	eax,FALSE			;error
	ret
;
;==============================================================================
;
;	>	eax  -  parameter
;		ebx  -  dispatch table
;
;	<	eax  -  return code
;
;------------------------------------------------------------------------------
;
Dispatcher:
	add	ebx,4+4				;next entry
	cmp	dword ptr [ebx-4-4],-1		;end of table?
	jz	Dispatcher1
	cmp	dword ptr [ebx-4-4],eax		;message entry found?
	jnz	Dispatcher
Dispatcher1:
	jmp	dword ptr [ebx-4]		;handle message
;
;==============================================================================
;
;	>	esi  -  extension
;		edi  -  buffer
;		ecx  -  buffer length (characters)
;
;	<	  c  -  set if buffer overflow
;
;------------------------------------------------------------------------------
;
GetAssociatedFile:
	cc2bc	ecx				;character count -> byte count
	mov	CHAR ptr [edi],0		;clear buffer
	mov	ebx,offset sLoadFile		;scan load file name
	mov	edx,ebx				;initialize marker
GetAssociatedFile1:
	cmp	CHAR ptr [ebx],0		;end?
	jz	GetAssociatedFile4
	cmp	CHAR ptr [ebx],"\"		;directory separator?
	jz	GetAssociatedFile2
	cmp	CHAR ptr [ebx],"."		;extension separator?
	jnz	GetAssociatedFile3
GetAssociatedFile2:
	mov	edx,ebx				;set marker
GetAssociatedFile3:
	add	ebx,CHAR_			;next character
	jmp	GetAssociatedFile1
GetAssociatedFile4:
	xchg	ebx,edx				;marker on extension separator?
	cmp	CHAR ptr [ebx],"."
	jz	GetAssociatedFile5
	mov	ebx,edx				;set marker to end
GetAssociatedFile5:
	mov	edx,ebx				;compute prefix length
	sub	edx,offset sLoadFile
	mov	ebx,esi				;get extension length
GetAssociatedFile6:
	add	ebx,CHAR_
	cmp	CHAR ptr [ebx-CHAR_],0
	jnz	GetAssociatedFile6
	sub	ebx,esi
	add	ebx,edx				;compute total length
	cmp	ecx,ebx
	jb	GetAssociatedFile9
	mov	ebx,offset sLoadFile		;copy prefix
GetAssociatedFile7:
	sub	edx,CHAR_			;end?
	jb	GetAssociatedFile8
	lodc	[ebx]				;copy character
	add	ebx,CHAR_
	stoc	[edi]
	add	edi,CHAR_
	jmp	GetAssociatedFile7		;next character
GetAssociatedFile8:
	lodc	[esi]				;copy extension
	add	esi,CHAR_
	stoc	[edi]
	add	edi,CHAR_
	cmpc	0				;end?
	jnz	GetAssociatedFile8
	clc					;ok
GetAssociatedFile9:
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
sMainCaption:		STRING	<Forwarder DLL/0>
sNull:			STRING	</0>
;
;------------------------------------------------------------------------------
;
StartupInfo		STARTUPINFO {STARTUPINFO_, NULL, NULL, NULL,\
				     0, 0, 0, 0, 0, 0,\
				     0, 0, SW_SHOW, 0, NULL,\
				     INVALID_HANDLE_VALUE,\
				     INVALID_HANDLE_VALUE,\
				     INVALID_HANDLE_VALUE}
;
ProcessInformation	PROCESS_INFORMATION {NULL, NULL, 0, 0}
;
fProcessAttached	BOOL	FALSE
;
;------------------------------------------------------------------------------
;
sExtDataFile:		STRING	<.ini/0>
;
sSecSettings:		STRING	<Settings/0>
sKeySettingsCommand:	STRING	<Command/0>
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
sLoadFile		CHAR MAX_PATH dup (?)
sDataFile		CHAR MAX_PATH dup (?)
hInst			HINSTANCE ?	
;
;------------------------------------------------------------------------------
;
sCommand_		equ	0100h
sCommand		CHAR	sCommand_ dup (?)
;
;==============================================================================
;
EndUData
;
;==============================================================================
;
EndImage

