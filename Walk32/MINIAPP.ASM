;
;	________________________________________________________________
;
;	                          MiniApp.asm
;	               Win32 Miniature Application V1.00
;	        03-14-1996 Sven B. Schreiber sbs@psbs.franken.de
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
; Recommended MASM command line: ml /I. /Zm /c /Cp /Ta MiniApp.asm
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
WMU_INIT		equ	WM_USER+0101h		;initialization message
;
;------------------------------------------------------------------------------
;
IDM_FILE		equ	100			;file menu
IDM_FILE_EXIT		equ	IDM_FILE+00		;file / exit
;
IDM_HELP		equ	200			;help menu
IDM_HELP_HOWTO		equ	IDM_HELP+00		;help / how to use help
IDM_HELP_ABOUT		equ	IDM_HELP+01		;help / about
;
;------------------------------------------------------------------------------
;
IDW_STATUSBAR		equ	1000			;status bar
;
;------------------------------------------------------------------------------
;
IDC_HELP_ABOUT		equ	2000			;help / about box
IDC_HELP_ABOUT_INFO	equ	IDC_HELP_ABOUT+00	;help / about / info
;
;------------------------------------------------------------------------------
;
MAX_DIALOGS		equ	30			;dialog directory size
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
;==============================================================================
;====== .TEXT SECTION =========================================================
;==============================================================================
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
	mov	eax,hInstance			;make hInstance global
	mov	hInst,eax
	call	Initialize			;initialize application
	jb	WinMain2
	Win32	PostMessage,\			;post initialization message
		MainWnd.wp_hWnd,\
		WMU_INIT,\
		pEnvironment,\
		pCmdLine
	cmp	eax,FALSE			;error?
	jz	WinMain2
WinMain1:
	Win32	GetMessage,\			;wait for message
		<offset Msg>,\
		NULL,\
		0,\
		0
	cmp	eax,-1				;error?
	jz	WinMain2
	cmp	eax,FALSE			;WM_QUIT?
	jz	WinMain2
	mov	esi,offset Msg			;message for modeless dialog?
	call	DispatchDialogMessage
	jnb	WinMain1
	Win32	TranslateMessage,\		;translate virtual-key messages
		<offset Msg>
	Win32	DispatchMessage,\		;dispatch message to wndproc
		<offset Msg>
	jmp	WinMain1			;next message
WinMain2:
	call	CleanUp				;clean up application
	mov	eax,0				;load return code
	WinMainEpilogue
;
;==============================================================================
;
;	>	[ebp+08]  -  hInstance
;		[ebp+12]  -  pEnvironment
;		[ebp+16]  -  pCmdLine
;		[ebp+20]  -  dCmdShow
;
;	<	       c  -  set if error
;
;------------------------------------------------------------------------------
;
Initialize:
	Win32	Ctl3dRegister,\			;request 3d effects
		hInst
	Win32	Ctl3dAutoSubclass,\
		hInst
	Win32	InitCommonControls		;load common control library
	mov	WndClass.wc_hbrBackground,NULL	;clear background brush
	mov	esi,offset sExtDataFile		;get data file path
	mov	edi,offset sDataFile
	mov	ecx,MAX_PATH
	call	GetApplicationFile
	jb	Initialize1
	mov	esi,offset sExtHelpFile		;get help file path
	mov	edi,offset sHelpFile
	mov	ecx,MAX_PATH
	call	GetApplicationFile
	jb	Initialize1
	mov	ebx,tMainMenu			;create main menu
	call	CreateMainMenu
	jb	Initialize1
	call	CreateMainWindow		;create main window
	jb	Initialize1
	call	CreateStatusBar			;create status bar
	jb	Initialize1
	Win32	ShowWindow,\			;display main window
		MainWnd.wp_hWnd,\
		dCmdShow
	Win32	UpdateWindow,\
		MainWnd.wp_hWnd
	clc					;ok
Initialize1:
	ret
;
;==============================================================================
;
;	>	[ebp+08]  -  hInstance
;		[ebp+12]  -  pEnvironment
;		[ebp+16]  -  pCmdLine
;		[ebp+20]  -  dCmdShow
;
;------------------------------------------------------------------------------
;
CleanUp:
	cmp	WndClass.wc_hbrBackground,NULL	;background brush defined?
	jz	CleanUp1
	Win32	DeleteObject,\			;delete background brush
		WndClass.wc_hbrBackground
CleanUp1:
	Win32	Ctl3dUnregister,\		;no more 3d effects
		hInst
	ret
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
GetApplicationFile:
	cc2bc	ecx				;character count -> byte count
	mov	CHAR ptr [edi],0		;clear buffer
	mov	ebx,offset sLoadFile		;scan load file name
	mov	edx,ebx				;initialize marker
GetApplicationFile1:
	cmp	CHAR ptr [ebx],0		;end?
	jz	GetApplicationFile4
	cmp	CHAR ptr [ebx],"\"		;directory separator?
	jz	GetApplicationFile2
	cmp	CHAR ptr [ebx],"."		;extension separator?
	jnz	GetApplicationFile3
GetApplicationFile2:
	mov	edx,ebx				;set marker
GetApplicationFile3:
	add	ebx,CHAR_			;next character
	jmp	GetApplicationFile1
GetApplicationFile4:
	xchg	ebx,edx				;marker on extension separator?
	cmp	CHAR ptr [ebx],"."
	jz	GetApplicationFile5
	mov	ebx,edx				;set marker to end
GetApplicationFile5:
	mov	edx,ebx				;compute prefix length
	sub	edx,offset sLoadFile
	mov	ebx,esi				;get extension length
GetApplicationFile6:
	add	ebx,CHAR_
	cmp	CHAR ptr [ebx-CHAR_],0
	jnz	GetApplicationFile6
	sub	ebx,esi
	add	ebx,edx				;compute total length
	cmp	ecx,ebx
	jb	GetApplicationFile9
	mov	ebx,offset sLoadFile		;copy prefix
GetApplicationFile7:
	sub	edx,CHAR_			;end?
	jb	GetApplicationFile8
	lodc	[ebx]				;copy character
	add	ebx,CHAR_
	stoc	[edi]
	add	edi,CHAR_
	jmp	GetApplicationFile7		;next character
GetApplicationFile8:
	lodc	[esi]				;copy extension
	add	esi,CHAR_
	stoc	[edi]
	add	edi,CHAR_
	cmpc	0				;end?
	jnz	GetApplicationFile8
	clc					;ok
GetApplicationFile9:
	ret
;
;==============================================================================
;
;	<	  c  -  set if error
;
;------------------------------------------------------------------------------
;
CreateMainWindow:
	mov	WndClass.wc_style,CS_HREDRAW+CS_VREDRAW	;init window class
	mov	WndClass.wc_lpfnWndProc,MainWndProc
	mov	WndClass.wc_cbClsExtra,0
	mov	WndClass.wc_cbWndExtra,0
	mov	eax,hInstance
	mov	WndClass.wc_hInstance,eax
	Win32	LoadIcon,\			;load icon
		hInstance,\
		DEFAULT_ICON
	mov	WndClass.wc_hIcon,eax
	cmp	eax,NULL
	jz	CreateMainWindow3
	Win32	LoadCursor,\			;load cursor
		NULL,\
		IDC_ARROW
	mov	WndClass.wc_hCursor,eax
	cmp	eax,NULL
	jz	CreateMainWindow3
	Win32	CreateSolidBrush,\		;create background brush
		MainWnd.wp_BkColor
	mov	WndClass.wc_hbrBackground,eax
	cmp	eax,NULL
	jz	CreateMainWindow3
	mov	WndClass.wc_lpszMenuName,NULL	;no default menu
	mov	WndClass.wc_lpszClassName,offset sMainClass
	Win32	RegisterClass,\			;register window class
		<offset WndClass>
	cmp	eax,0				;ok?
	jz	CreateMainWindow3
	cmp	RectMainWnd.rc_left,-1		;left border fixed?
	jnz	CreateMainWindow1
	Win32	GetSystemMetrics,\		;center window horizontally
		SM_CXSCREEN
	sub	eax,RectMainWnd.rc_right
	sar	eax,1
	mov	RectMainWnd.rc_left,eax
	add	RectMainWnd.rc_right,eax
CreateMainWindow1:
	cmp	RectMainWnd.rc_top,-1		;top border fixed?
	jnz	CreateMainWindow2
	Win32	GetSystemMetrics,\		;center window vertically
		SM_CYSCREEN
	sub	eax,RectMainWnd.rc_bottom
	sar	eax,1
	mov	RectMainWnd.rc_top,eax
	add	RectMainWnd.rc_bottom,eax
CreateMainWindow2:
	mov	eax,RectMainWnd.rc_left		;prepare window coordinates
	mov	ebx,RectMainWnd.rc_top
	mov	ecx,RectMainWnd.rc_right
	mov	edx,RectMainWnd.rc_bottom
	sub	ecx,eax
	sub	edx,ebx
	Win32	CreateWindowEx,\		;create main window
		WS_EX_NONE,\
		<offset sMainClass>,\
		<offset sMainCaption>,\
		WS_OVERLAPPEDWINDOW,\
		eax,\
		ebx,\
		ecx,\
		edx,\
		NULL,\
		hMainMenu,\
		hInstance,\
		NULL
	cmp	eax,NULL			;ok?
	jz	CreateMainWindow3
	mov	MainWnd.wp_hWnd,eax		;save main window handle
	clc					;ok
	jmp	CreateMainWindow4
CreateMainWindow3:
	stc					;error
CreateMainWindow4:
	ret
;
;==============================================================================
;
;	<	  c  -  set if error
;
;------------------------------------------------------------------------------
;
CreateStatusBar:
	Win32	CreateStatusWindow,\		;create status bar
		WS_CONTROL+WS_BORDER,\
		<offset sNull>,\
		MainWnd.wp_hWnd,\
		IDW_STATUSBAR
	cmp	eax,NULL			;ok?
	jz	CreateStatusBar1
	mov	hStatusBar,eax			;save status bar handle
	Win32	SendMessage,\
		hStatusBar,\
		SB_SETPARTS,\
		dStatusBarParts,\
		<offset dStatusBarParts+4>
	cmp	eax,FALSE			;ok?
	jz	CreateStatusBar1
	Win32	SendMessage,\
		hStatusBar,\
		SB_SIMPLE,\
		FALSE,\
		0
	clc					;ok
	jmp	CreateStatusBar2
CreateStatusBar1:
	stc					;error
CreateStatusBar2:
	ret
;
;==============================================================================
;
;	>	ebx  -  menu table
;
;	<	  c  -  set if error
;
;------------------------------------------------------------------------------
;
CreateMainMenu:
	push	ebx
	Win32	CreateMenu			;create new menu
	pop	ebx
	cmp	eax,NULL			;ok?
	jz	CreateMainMenu6
	mov	[ebx],eax			;save main menu handle
	lea	esi,[ebx+4]			;skip main menu handle
CreateMainMenu1:
	cmp	dword ptr [esi],-1		;end of menu table?
	clc					;ok
	jz	CreateMainMenu7
	push	ebx
	push	esi
	Win32	CreatePopupMenu			;create new pop-up menu
	pop	esi
	pop	ebx
	cmp	eax,NULL			;ok?
	jz	CreateMainMenu6
	mov	[esi],eax			;save pop-up menu handle
	mov	edi,esi
CreateMainMenu2:
	add	edi,4+4				;skip control data
CreateMainMenu3:
	add	edi,CHAR_			;skip pop-up name
	cmp	CHAR ptr [edi-CHAR_],0
	jnz	CreateMainMenu3
	add	di,CHAR_			;end of pop-up item list?
	cmp	CHAR ptr [edi-CHAR_],0
	jnz	CreateMainMenu4
	lea	edx,[esi+4+4]			;prepare string pointer
	mov	ecx,[esi+4]			;prepare attributes
	or	ecx,MF_POPUP
	push	ebx
	push	edi
	Win32	AppendMenu,\			;set pop-up name
		[ebx],\
		ecx,\
		[esi],\
		edx
	pop	edi
	pop	ebx
	cmp	eax,FALSE			;ok?
	jz	CreateMainMenu6
	mov	esi,edi				;next pop-up menu
	jmp	CreateMainMenu1
CreateMainMenu4:
	lea	edx,[edi+4+4]			;prepare string pointer
	cmp	CHAR ptr [edi+4+4],0		;separator item?
	mov	ecx,MF_SEPARATOR
	jz	CreateMainMenu5
	mov	ecx,[edi+4]			;prepare attributes
	or	ecx,MF_STRING
CreateMainMenu5:
	push	ebx
	push	esi
	push	edi
	Win32	AppendMenu,\			;set pop-up item
		[esi],\
		ecx,\
		[edi],\
		edx
	pop	edi
	pop	esi
	pop	ebx
	cmp	eax,FALSE			;ok?
	jnz	CreateMainMenu2
CreateMainMenu6:
	stc					;error
CreateMainMenu7:
	ret
;
;==============================================================================
;
;	>	eax  -  pop-up menu handle
;		ebx  -  menu table
;
;	<	esi  -  pop-up menu definition
;		  c  -  set if menu not found
;
;------------------------------------------------------------------------------
;
FindMainMenuPopup:
	lea	esi,[ebx+4]			;skip main menu handle
FindMainMenuPopup1:
	cmp	dword ptr [esi],-1		;end of menu table?
	stc
	jz	FindMainMenuPopup4
	cmp	[esi],eax			;pop-up menu definition found?
	clc
	jz	FindMainMenuPopup4
FindMainMenuPopup2:
	add	esi,4+4				;skip control data
FindMainMenuPopup3:
	add	esi,CHAR_			;skip name
	cmp	CHAR ptr [esi-CHAR_],0
	jnz	FindMainMenuPopup3
	add	esi,CHAR_			;end of pop-up item list?
	cmp	CHAR ptr [esi-CHAR_],0
	jnz	FindMainMenuPopup2
	jmp	FindMainMenuPopup1
FindMainMenuPopup4:
	ret
;
;==============================================================================
;
;	>	ebx  -  menu table
;		esi  -  pop-up menu definition
;
;------------------------------------------------------------------------------
;
UpdateMainMenuPopup:
	add	esi,4+4				;skip control data
UpdateMainMenuPopup1:
	add	esi,CHAR_			;skip name
	cmp	CHAR ptr [esi-CHAR_],0
	jnz	UpdateMainMenuPopup1
	add	esi,CHAR_			;end of pop-up item list?
	cmp	CHAR ptr [esi-CHAR_],0
	jz	UpdateMainMenuPopup2
	mov	ecx,MF_UNCHECKED or MF_CHECKED	;get menu item flags
	and	ecx,[esi+4]
	push	ebx
	push	esi
	Win32	CheckMenuItem,\			;update check mark
		[ebx],\
		[esi],\
		ecx
	pop	esi
	pop	ebx
	mov	ecx,MF_ENABLED or MF_GRAYED or MF_DISABLED ;get menu item flags
	and	ecx,[esi+4]
	push	ebx
	push	esi
	Win32	EnableMenuItem,\		;update activation status
		[ebx],\
		[esi],\
		ecx
	pop	esi
	pop	ebx
	jmp	UpdateMainMenuPopup		;next menu item
UpdateMainMenuPopup2:
	ret
;
;==============================================================================
;
;	STATUS BAR MANAGEMENT
;
;==============================================================================
;
;	>	esi  -  text
;		ecx  -  destination index
;		edx  -  style
;
;------------------------------------------------------------------------------
;
SetStatusBarText:
	or	ecx,edx				;combine index and style
	Win32	SendMessage,\			;set status bar text
		hStatusBar,\
		SB_SETTEXT,\
		ecx,\
		esi
	ret
;
;==============================================================================
;
;	DIALOG MANAGEMENT
;
;==============================================================================
;
;	>	eax  -  parent window
;		ebx  -  dialog definition
;		edx  -  callback function
;
;	<	eax  -  dialog handle
;
;------------------------------------------------------------------------------
;
ModelessDialog:
	mov	esi,ebx				;load attributes list pointer
	add	ebx,DIALOGATTRIBUTES_		;set pointer to dialog template
	push	eax
	push	ebx
	push	edx
	push	esi
	call	CenterDialog			;center dialog window
	pop	esi
	pop	edx
	pop	ebx
	pop	eax
	Win32	CreateDialogIndirectParam,\	;create dialog
		hInst,\
		ebx,\
		eax,\
		edx,\
		esi
	ret
;
;==============================================================================
;
;	>	eax  -  parent window
;		ebx  -  dialog definition
;		edx  -  callback function
;
;	<	eax  -  dialog result
;
;------------------------------------------------------------------------------
;
ModalDialog:
	mov	esi,ebx				;load attributes list pointer
	add	ebx,DIALOGATTRIBUTES_		;set pointer to dialog template
	push	eax
	push	ebx
	push	edx
	push	esi
	call	CenterDialog			;center dialog window
	pop	esi
	pop	edx
	pop	ebx
	pop	eax
	Win32	DialogBoxIndirectParam,\	;create dialog
		hInst,\
		ebx,\
		eax,\
		edx,\
		esi
	ret
;
;==============================================================================
;
;	>	ebx  -  dialog template
;
;------------------------------------------------------------------------------
;
CenterDialog:
	cmp	dword ptr [ebx+4+4+2],-1	;template already initialized?
	jnz	CenterDialog3
	push	ebx
	Win32	GetSystemMetrics,\		;get screen width
		SM_CXSCREEN
	mov	esi,eax				;*4
	shl	esi,2
	push	esi
	Win32	GetSystemMetrics,\		;get screen height
		SM_CYSCREEN
	mov	edi,eax				;*8
	shl	edi,3
	push	edi
	Win32	GetSystemMetrics,\		;get caption height
		SM_CYCAPTION
	mov	ecx,eax				;*8
	shl	ecx,3
	pop	edi
	sub	edi,ecx				;screen height - caption height
	push	edi
	push	ecx
	Win32	GetDialogBaseUnits		;get dialog base units
	pop	ecx
	pop	edi
	pop	esi
	pop	ebx
	mov	edx,eax				;split result
	shr	edx,16
	and	eax,0FFFFh
	push	ecx
	push	edx
	mov	ecx,eax
	mov	edx,0				;compute horizontal free space
	mov	dx,[ebx+4+4+2+2+2]
	mul	edx
	sub	esi,eax
	mov	eax,0				;window too wide
	jb	CenterDialog1
	mov	eax,esi				;load horizontal origin
CenterDialog1:
	mov	edx,0				;convert to dialog units
	div	ecx
	shl	edx,1				;round
	cmp	edx,ecx
	sbb	eax,-1
	shr	eax,1				;/2
	mov	[ebx+4+4+2],ax			;set horizontal origin
	pop	edx
	pop	ecx
	mov	esi,edx
	mov	eax,0
	mov	ax,[ebx+4+4+2+2+2+2]		;compute vertical free space
	mul	edx
	sub	edi,eax
	mov	eax,0				;window too high
	jb	CenterDialog2
	mov	eax,edi				;load vertical origin
CenterDialog2:
	add	eax,ecx				;add caption height twice
	add	eax,ecx
	mov	edx,0				;convert to dialog units
	div	esi
	shl	edx,1				;round
	cmp	edx,esi
	sbb	eax,-1
	shr	eax,1				;/2
	mov	[ebx+4+4+2+2],ax		;set vertical origin
CenterDialog3:
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
ClearDialogDirectory:
	mov	ebx,offset DialogDirectory	;load dialog directory pointer
	mov	ecx,MAX_DIALOGS			;load number of dialog records
ClearDialogDirectory1:
	sub	ecx,1				;count dialog records
	jb	ClearDialogDirectory2
	mov	[ebx.dr_hWnd],NULL		;clear dialog record
	add	ebx,DIALOGRECORD_		;next dialog record
	jmp	ClearDialogDirectory1
ClearDialogDirectory2:
	ret
;
;==============================================================================
;
;	>	eax  -  window handle
;		edx  -  mode flag (FALSE = modal, TRUE = modeless)
;		esi  -  attributes list
;
;	<	  c  -  set if error
;
;------------------------------------------------------------------------------
;
AllocDialogRecord:
	mov	ebx,offset DialogDirectory	;load dialog directory pointer
	mov	ecx,MAX_DIALOGS			;load number of dialog records
AllocDialogRecord1:
	sub	ecx,1				;count dialog records
	jb	AllocDialogRecord3
	cmp	[ebx.dr_hWnd],NULL		;unused dialog record?
	jz	AllocDialogRecord2
	add	ebx,DIALOGRECORD_		;next dialog record
	jmp	AllocDialogRecord1
AllocDialogRecord2:
	mov	[ebx.dr_hWnd],eax		;save dialog window handle
	mov	[ebx.dr_fModeless],edx		;save mode flag
	mov	[ebx.dr_Attributes],esi		;save attributes list
	mov	[ebx.dr_Data],NULL		;data not yet defined
	mov	[ebx.dr_hDlgBrush],NULL		;brush handles not yet defined
	mov	[ebx.dr_hStaticBrush],NULL
	mov	[ebx.dr_hTextBoxBrush],NULL
	mov	[ebx.dr_hEditBrush],NULL
	mov	[ebx.dr_hListBoxBrush],NULL
	clc					;ok
	jmp	AllocDialogRecord4
AllocDialogRecord3:
	Win32	MessageBox,\			;display error message
		eax,\
		sDialogDirOverflow,\
		sMainCaption,\
		MB_ICONINFORMATION+MB_OK
	stc					;error
AllocDialogRecord4:
	ret
;
;==============================================================================
;
;	>	eax  -  window handle
;
;	<	ebx  -  dialog record
;		  c  -  set if error
;
;------------------------------------------------------------------------------
;
GetDialogRecord:
	mov	ebx,offset DialogDirectory	;load dialog directory pointer
	mov	ecx,MAX_DIALOGS			;load number of dialog records
GetDialogRecord1:
	sub	ecx,1				;count dialog records
	jb	GetDialogRecord3
	cmp	[ebx.dr_hWnd],eax		;dialog record found?
	jz	GetDialogRecord2
	add	ebx,DIALOGRECORD_		;next dialog record
	jmp	GetDialogRecord1
GetDialogRecord2:
	clc					;ok
GetDialogRecord3:
	ret
;
;==============================================================================
;
;	>	eax  -  window handle
;
;------------------------------------------------------------------------------
;
FreeDialogRecord:
	mov	ebx,offset DialogDirectory	;load dialog directory pointer
	mov	ecx,MAX_DIALOGS			;load number of dialog records
FreeDialogRecord1:
	sub	ecx,1				;count dialog records
	jb	FreeDialogRecord7
	cmp	[ebx.dr_hWnd],eax		;dialog record found?
	jz	FreeDialogRecord2
	add	ebx,DIALOGRECORD_		;next dialog record
	jmp	FreeDialogRecord1
FreeDialogRecord2:
	mov	[ebx.dr_hWnd],NULL		;clear dialog record
	cmp	[ebx.dr_hDlgBrush],NULL		;delete dialog brush if any
	jz	FreeDialogRecord3
	Win32	DeleteObject,\
		[ebx.dr_hDlgBrush]
FreeDialogRecord3:
	cmp	[ebx.dr_hStaticBrush],NULL	;delete static brush if any
	jz	FreeDialogRecord4
	Win32	DeleteObject,\
		[ebx.dr_hStaticBrush]
FreeDialogRecord4:
	cmp	[ebx.dr_hTextBoxBrush],NULL	;delete text box brush if any
	jz	FreeDialogRecord5
	Win32	DeleteObject,\
		[ebx.dr_hTextBoxBrush]
FreeDialogRecord5:
	cmp	[ebx.dr_hEditBrush],NULL	;delete edit brush if any
	jz	FreeDialogRecord6
	Win32	DeleteObject,\
		[ebx.dr_hEditBrush]
FreeDialogRecord6:
	cmp	[ebx.dr_hListBoxBrush],NULL	;delete list box brush if any
	jz	FreeDialogRecord7
	Win32	DeleteObject,\
		[ebx.dr_hListBoxBrush]
FreeDialogRecord7:
	ret
;
;==============================================================================
;
;	>	eax  -  window handle
;		edx  -  data
;
;	<	  c  -  set if error
;
;------------------------------------------------------------------------------
;
SetDialogRecordData:
	push	edx
	call	GetDialogRecord			;get dialog record
	pop	edx
	jb	SetDialogRecordData1		;error
	mov	[ebx.dr_Data],edx		;save dialog record data
SetDialogRecordData1:
	ret
;
;==============================================================================
;
;	>	eax  -  window handle
;
;	<	edx  -  data (NULL if error)
;		  c  -  set if error
;
;------------------------------------------------------------------------------
;
GetDialogRecordData:
	call	GetDialogRecord			;get dialog record
	mov	edx,NULL
	jb	GetDialogRecordData1		;error
	mov	edx,[ebx.dr_Data]		;load dialog record data
GetDialogRecordData1:
	ret
;
;==============================================================================
;
;	>	esi  -  message structure
;
;	<	  c  -  set if message not processed
;
;------------------------------------------------------------------------------
;
DispatchDialogMessage:
	mov	ebx,offset DialogDirectory	;load dialog directory pointer
	mov	ecx,MAX_DIALOGS			;load number of dialog records
DispatchDialogMessage1:
	sub	ecx,1				;count dialog records
	jb	DispatchDialogMessage3
	cmp	[ebx.dr_hWnd],NULL		;unused dialog record?
	jz	DispatchDialogMessage2
	cmp	[ebx.dr_fModeless],FALSE	;modal dialog?
	jz	DispatchDialogMessage2
	push	esi
	push	ebx
	push	ecx
	Win32	IsDialogMessage,\		;try to dispatch message
		[ebx.dr_hWnd],\
		esi
	pop	ecx
	pop	ebx
	pop	esi
	cmp	eax,FALSE			;message processed?
	clc
	jnz	DispatchDialogMessage3
DispatchDialogMessage2:
	add	ebx,DIALOGRECORD_		;next dialog record
	jmp	DispatchDialogMessage1
DispatchDialogMessage3:
	ret
;
;==============================================================================
;
;	MESSAGE HANDLING
;
;==============================================================================
;
;	>	eax  -  message
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
;	>	[ebp+08]  -  hWnd
;		[ebp+12]  -  dMsg
;		[ebp+16]  -  dParam1
;		[ebp+20]  -  dParam2
;
;	<	     eax  -  return code
;
;------------------------------------------------------------------------------
;
DefaultHandler:
	Win32	DefWindowProc,\			;default message processing
		hWnd,\
		dMsg,\
		dParam1,\
		dParam2
	ret
;
;==============================================================================
;
;	<	eax  -  return code
;
;------------------------------------------------------------------------------
;
ReturnNULL:
	mov	eax,NULL			;return null
	ret
;
;==============================================================================
;
;	<	eax  -  return code
;
;------------------------------------------------------------------------------
;
ReturnFALSE:
	mov	eax,FALSE			;return false
	ret
;
;==============================================================================
;
;	<	eax  -  return code
;
;------------------------------------------------------------------------------
;
ReturnTRUE:
	mov	eax,TRUE			;return true
	ret
;
;==============================================================================
;
;	>	eax  -  return code
;
;	<	eax  -  return code
;
;------------------------------------------------------------------------------
;
ReturnEAX:
	ret					;return contents of eax
;
;==============================================================================
;
;	MAIN WINDOW
;
;==============================================================================
;
;	>	[esp+04]  ->  [ebp+08]  -  hWnd
;		[esp+08]  ->  [ebp+12]  -  dMsg
;		[esp+12]  ->  [ebp+16]  -  dParam1
;		[esp+16]  ->  [ebp+20]  -  dParam2
;
;	<			   eax  -  return code
;
;------------------------------------------------------------------------------
;
MainWndProc:
	CallbackPrologue
	mov	eax,dMsg			;dispatch messages
	mov	ebx,MainWndTable
	call	Dispatcher
	CallbackEpilogue
;
;------------------------------------------------------------------------------
;
MainWndTable:
;
	DWORD	WMU_INIT, MainWndInit
	DWORD	WM_DESTROY, MainWndDestroy
	DWORD	WM_INITMENUPOPUP, MainWndInitMenuPopup
	DWORD	WM_SIZE, MainWndSize
	DWORD	WM_PAINT, MainWndPaint
	DWORD	WM_COMMAND, MainWndCommand
;
	DWORD	-1, DefaultHandler
;
;------------------------------------------------------------------------------
;
MainWndInit:
	call	ClearDialogDirectory		;clear dialog directory
	mov	esi,offset sLoadFile		;set status bar text
	mov	ecx,0
	mov	edx,SBT_DEFAULT
	call	SetStatusBarText
	jmp	ReturnNULL
;
;------------------------------------------------------------------------------
;
MainWndDestroy:
	Win32	WinHelp,\			;quit windows help
		hWnd,\
		<offset sHelpFile>,\
		HELP_QUIT,\
		0
	Win32	PostQuitMessage,\		;terminate program
		0
	jmp	ReturnNULL
;
;------------------------------------------------------------------------------
;
MainWndInitMenuPopup:
	mov	eax,dParam2			;system menu?
	shr	eax,16
	cmp	eax,FALSE
	jnz	MainWndInitMenuPopup1
	mov	eax,dParam1			;get pop-up menu definition
	mov	ebx,tMainMenu
	call	FindMainMenuPopup
	jb	MainWndInitMenuPopup1
	mov	ebx,tMainMenu			;update pop-up menu
	call	UpdateMainMenuPopup
MainWndInitMenuPopup1:
	jmp	ReturnNULL
;
;------------------------------------------------------------------------------
;
MainWndSize:
	Win32	GetWindowRect,\			;get status bar coordinates
		hStatusBar,\
		<offset Rect>
	mov	ecx,dParam2			;get status bar width
	and	ecx,0FFFFh
	mov	edx,Rect.rc_bottom		;get status bar height
	sub	edx,Rect.rc_top
	mov	eax,0				;get status bar origin
	mov	ebx,dParam2
	shr	ebx,16
	sub	ebx,edx
	Win32	SetWindowPos,\			;move status bar
		hStatusBar,\
		NULL,\
		eax,\
		ebx,\
		ecx,\
		edx,\
		SWP_NOZORDER
	jmp	ReturnNULL
;
;------------------------------------------------------------------------------
;
MainWndPaint:
	Win32	BeginPaint,\			;prepare window for painting
		hWnd,\
		<offset PaintStruct>
	Win32	GetStockObject,\		;set font
		MainWnd.wp_FontId
	Win32	SelectObject,\
		PaintStruct.ps_hdc,\
		eax
	Win32	SetTextColor,\			;set text color
		PaintStruct.ps_hdc,\
		MainWnd.wp_TextColor
	Win32	SetBkColor,\			;set background color
		PaintStruct.ps_hdc,\
		MainWnd.wp_BkColor
	Win32	SetBkMode,\			;set background mode
		PaintStruct.ps_hdc,\
		MainWnd.wp_BkMode
	Win32	GetClientRect,\			;get status bar height
		hStatusBar,\
		<offset Rect>
	mov	edx,Rect.rc_bottom
	sub	edx,Rect.rc_top
	push	edx
	Win32	GetClientRect,\			;get client area coordinates
		hWnd,\
		<offset Rect>
	pop	edx
	sub	Rect.rc_bottom,edx		;exclude status bar area
	Win32	DrawText,\			;display text
		PaintStruct.ps_hdc,\
		<offset sDataFile>,\
		-1,\
		<offset Rect>,\
		DT_SINGLELINE+DT_CENTER+DT_VCENTER
	Win32	EndPaint,\			;end painting
		hWnd,\
		<offset PaintStruct>
	jmp	ReturnNULL
;
;------------------------------------------------------------------------------
;
MainWndCommand:
	mov	eax,dParam1			;dispatch commands
	and	eax,0FFFFh
	mov	ebx,MainCmdTable
	jmp	Dispatcher
;
;------------------------------------------------------------------------------
;
;	MAIN MENU
;
;------------------------------------------------------------------------------
;
MainCmdTable:
;
	DWORD	IDM_FILE_EXIT, MainCmdFileExit
;
	DWORD	IDM_HELP_HOWTO, MainCmdHelpHowTo
	DWORD	IDM_HELP_ABOUT, MainCmdHelpAbout
;
	DWORD	-1, DefaultHandler
;
;------------------------------------------------------------------------------
;
MainCmdFileExit:
	Win32	PostMessage,\			;terminate program
		hWnd,\
		WM_CLOSE,\
		NULL,\
		NULL
	jmp	ReturnNULL
;
;------------------------------------------------------------------------------
;
MainCmdHelpHowTo:
	Win32	WinHelp,\			;display help on help
		hWnd,\
		NULL,\
		HELP_HELPONHELP,\
		0
	jmp	ReturnNULL
;
;------------------------------------------------------------------------------
;
MainCmdHelpAbout:
	mov	eax,hWnd			;display about box
	mov	ebx,TemplateHelpAbout
	mov	edx,ModalDlgProc
	call	ModalDialog
	jmp	ReturnNULL
;
;==============================================================================
;
;	STANDARD DIALOGS
;
;==============================================================================
;
;	>	[esp+04]  ->  [ebp+08]  -  hWnd
;		[esp+08]  ->  [ebp+12]  -  dMsg
;		[esp+12]  ->  [ebp+16]  -  dParam1
;		[esp+16]  ->  [ebp+20]  -  dParam2
;
;	<			   eax  -  return code
;
;------------------------------------------------------------------------------
;
ModelessDlgProc:
	CallbackPrologue
	mov	eax,dMsg			;dispatch messages
	mov	ebx,ModelessDlgTable
	call	Dispatcher
	CallbackEpilogue
;
;------------------------------------------------------------------------------
;
ModalDlgProc:
	CallbackPrologue
	mov	eax,dMsg			;dispatch messages
	mov	ebx,ModalDlgTable
	call	Dispatcher
	CallbackEpilogue
;
;------------------------------------------------------------------------------
;
ModelessDlgTable:
;
	DWORD	WM_INITDIALOG, ModelessDlgInitDialog
	DWORD	WM_CTLCOLORDLG, ModelessDlgCtlColorDlg
	DWORD	WM_CTLCOLORSTATIC, ModelessDlgCtlColorStatic
	DWORD	WM_CTLCOLOREDIT, ModelessDlgCtlColorEdit
	DWORD	WM_CTLCOLORLISTBOX, ModelessDlgCtlColorListBox
	DWORD	WM_COMMAND, ModelessDlgCommand
;
	DWORD	-1, ReturnFALSE
;
;------------------------------------------------------------------------------
;
ModalDlgTable:
;
	DWORD	WM_INITDIALOG, ModalDlgInitDialog
	DWORD	WM_CTLCOLORDLG, ModalDlgCtlColorDlg
	DWORD	WM_CTLCOLORSTATIC, ModalDlgCtlColorStatic
	DWORD	WM_CTLCOLOREDIT, ModalDlgCtlColorEdit
	DWORD	WM_CTLCOLORLISTBOX, ModalDlgCtlColorListBox
	DWORD	WM_COMMAND, ModalDlgCommand
;
	DWORD	-1, ReturnFALSE
;
;------------------------------------------------------------------------------
;
ModelessDlgInitDialog:
	mov	eax,hWnd			;allocate dialog record
	mov	edx,TRUE
	mov	esi,dParam2
	call	AllocDialogRecord
	jmp	ReturnTRUE
;
;------------------------------------------------------------------------------
;
ModalDlgInitDialog:
	mov	eax,hWnd			;allocate dialog record
	mov	edx,FALSE
	mov	esi,dParam2
	call	AllocDialogRecord
	jmp	ReturnTRUE
;
;------------------------------------------------------------------------------
;
ModelessDlgCtlColorDlg:
ModalDlgCtlColorDlg:
	mov	eax,hWnd			;get dialog record
	call	GetDialogRecord
	mov	eax,NULL			;error
	jb	ModalDlgCtlColorDlg1
	mov	esi,[ebx.dr_Attributes]		;load color palette
	mov	esi,[esi.da_Palette]
	push	ebx
	push	esi
	Win32	SetTextColor,\			;set text color
		dParam1,\
		[esi.dp_DlgText]
	pop	esi
	push	esi
	Win32	SetBkColor,\			;set background color
		dParam1,\
		[esi.dp_DlgBk]
	pop	esi
	pop	ebx
	mov	eax,[ebx.dr_hDlgBrush]		;background brush defined?
	cmp	eax,NULL
	jnz	ModalDlgCtlColorDlg1
	push	ebx
	Win32	CreateSolidBrush,\		;create background brush
		[esi.dp_DlgBk]
	pop	ebx
	mov	[ebx.dr_hDlgBrush],eax		;save background brush handle
ModalDlgCtlColorDlg1:
	jmp	ReturnEAX			;return background brush handle
;
;------------------------------------------------------------------------------
;
ModelessDlgCtlColorStatic:
ModalDlgCtlColorStatic:
	mov	eax,hWnd			;get dialog record
	call	GetDialogRecord
	mov	eax,NULL			;error
	jb	ModalDlgCtlColorStatic4
	push	ebx
	Win32	GetDlgCtrlID,\			;get control id
		dParam2
	pop	ebx
	mov	esi,[ebx.dr_Attributes]		;load dialog attributes
	mov	edi,[esi.da_TextBox]
	mov	esi,[esi.da_Palette]
ModalDlgCtlColorStatic1:
	add	edi,4				;next text box entry
	cmp	dword ptr [edi-4],NULL		;end of list?
	jz	ModalDlgCtlColorStatic2
	cmp	dword ptr [edi-4],eax		;text box id found?
	jnz	ModalDlgCtlColorStatic1
	mov	edx,[esi.dp_TextBoxText]	;load text box parameters
	mov	ecx,[esi.dp_TextBoxBk]
	lea	edi,[ebx.dr_hTextBoxBrush]
	jmp	ModalDlgCtlColorStatic3
ModalDlgCtlColorStatic2:
	mov	edx,[esi.dp_StaticText]		;load default static parameters
	mov	ecx,[esi.dp_StaticBk]
	lea	edi,[ebx.dr_hStaticBrush]
ModalDlgCtlColorStatic3:
	push	edi
	push	ecx
	Win32	SetTextColor,\			;set text color
		dParam1,\
		edx
	pop	ecx
	push	ecx
	Win32	SetBkColor,\			;set background color
		dParam1,\
		ecx
	pop	ecx
	pop	edi
	mov	eax,[edi]			;background brush defined?
	cmp	eax,NULL
	jnz	ModalDlgCtlColorStatic4
	push	edi
	Win32	CreateSolidBrush,\		;create background brush
		ecx
	pop	edi
	mov	[edi],eax			;save background brush handle
ModalDlgCtlColorStatic4:
	jmp	ReturnEAX			;return background brush handle
;
;------------------------------------------------------------------------------
;
ModelessDlgCtlColorEdit:
ModalDlgCtlColorEdit:
	mov	eax,hWnd			;get dialog record
	call	GetDialogRecord
	mov	eax,NULL			;error
	jb	ModalDlgCtlColorEdit1
	mov	esi,[ebx.dr_Attributes]		;load color palette
	mov	esi,[esi.da_Palette]
	push	ebx
	push	esi
	Win32	SetTextColor,\			;set text color
		dParam1,\
		[esi.dp_EditText]
	pop	esi
	push	esi
	Win32	SetBkColor,\			;set background color
		dParam1,\
		[esi.dp_EditBk]
	pop	esi
	pop	ebx
	mov	eax,[ebx.dr_hEditBrush]		;background brush defined?
	cmp	eax,NULL
	jnz	ModalDlgCtlColorEdit1
	push	ebx
	Win32	CreateSolidBrush,\		;create background brush
		[esi.dp_EditBk]
	pop	ebx
	mov	[ebx.dr_hEditBrush],eax		;save background brush handle
ModalDlgCtlColorEdit1:
	jmp	ReturnEAX			;return background brush handle
;
;------------------------------------------------------------------------------
;
ModelessDlgCtlColorListBox:
ModalDlgCtlColorListBox:
	mov	eax,hWnd			;get dialog record
	call	GetDialogRecord
	mov	eax,NULL			;error
	jb	ModalDlgCtlColorListBox1
	mov	esi,[ebx.dr_Attributes]		;load color palette
	mov	esi,[esi.da_Palette]
	push	ebx
	push	esi
	Win32	SetTextColor,\			;set text color
		dParam1,\
		[esi.dp_ListBoxText]
	pop	esi
	push	esi
	Win32	SetBkColor,\			;set background color
		dParam1,\
		[esi.dp_ListBoxBk]
	pop	esi
	pop	ebx
	mov	eax,[ebx.dr_hListBoxBrush]	;background brush defined?
	cmp	eax,NULL
	jnz	ModalDlgCtlColorListBox1
	push	ebx
	Win32	CreateSolidBrush,\		;create background brush
		[esi.dp_ListBoxBk]
	pop	ebx
	mov	[ebx.dr_hListBoxBrush],eax	;save background brush handle
ModalDlgCtlColorListBox1:
	jmp	ReturnEAX			;return background brush handle
;
;------------------------------------------------------------------------------
;
ModelessDlgCommand:
	mov	eax,dParam1			;dispatch commands
	and	eax,0FFFFh
	mov	ebx,ModelessCmdTable
	jmp	Dispatcher
;
;------------------------------------------------------------------------------
;
ModalDlgCommand:
	mov	eax,dParam1			;dispatch commands
	and	eax,0FFFFh
	mov	ebx,ModalCmdTable
	jmp	Dispatcher
;
;------------------------------------------------------------------------------
;
;	DIALOG COMMANDS
;
;------------------------------------------------------------------------------
;
ModelessCmdTable:
;
	DWORD	IDCANCEL, ModelessCmdExit
	DWORD	IDOK, ModelessCmdExit
;
	DWORD	-1, ReturnFALSE
;
;------------------------------------------------------------------------------
;
ModalCmdTable:
;
	DWORD	IDCANCEL, ModalCmdExit
	DWORD	IDOK, ModalCmdExit
;
	DWORD	-1, ReturnFALSE
;
;------------------------------------------------------------------------------
;
ModelessCmdExit:
	mov	eax,hWnd			;free dialog record
	call	FreeDialogRecord
	Win32	SetFocus,\			;select main window
		MainWnd.wp_hWnd
	Win32	DestroyWindow,\			;close dialog
		hWnd
	jmp	ReturnTRUE
;
;------------------------------------------------------------------------------
;
ModalCmdExit:
	mov	eax,hWnd			;free dialog record
	call	FreeDialogRecord
	mov	eax,dParam1			;return control id
	and	eax,0FFFFh
	Win32	EndDialog,\			;close dialog
		hWnd,\
		eax
	jmp	ReturnTRUE
;
;==============================================================================
;
EndCode
;
;==============================================================================
;==============================================================================
;====== .DATA SECTION =========================================================
;==============================================================================
;==============================================================================
;
BeginData
;
;==============================================================================
;
;	DIALOG TEMPLATES
;
;------------------------------------------------------------------------------
;
TemplateHelpAbout	equ	$
;
DIALOGATTRIBUTES	{PaletteHelpAbout, TextBoxHelpAbout}
;
DLGTEMPLATE	DS_MODAL+WS_MODAL, 8,\
		-1, -1, 200, 122,\
		<About MiniApp>
;
DLGITEMTEMPLATE	BS_DEFPUSHBUTTON+WS_CONTROL+WS_GROUP,\
		60, 74, 80, 36,\
		IDOK, BUTTON,\
		<&OK>
;
DLGITEMTEMPLATE	ES_CENTER+WS_CONTROL+WS_BORDER+WS_DISABLED,\
		12, 12, 176, 52,\
		-1, EDIT,\
		<>
;
DLGITEMTEMPLATE	ES_CENTER+WS_CONTROL+WS_BORDER+WS_DISABLED,\
		16, 16, 168, 44,\
		-1, EDIT,\
		<>
;
DLGITEMTEMPLATE	SS_CENTER+WS_CONTROL,\
		22, 22, 160, 32,\
		IDC_HELP_ABOUT_INFO, STATIC,\
		<MiniApp.asm/n\
		Win32 Miniature Application V1.00/n\
		03-14-1996 Sven B. Schreiber/n\
		sbs@psbs.franken.de>
;
DLGITEMTEMPLATE	ES_CENTER+WS_CONTROL+WS_BORDER+WS_DISABLED,\
		21, 83, 18, 18,\
		-1, EDIT,\
		<>
;
DLGITEMTEMPLATE	SS_ICON+WS_CONTROL,\
		22, 84, 16, 16,\
		-1, STATIC,\
		-1, DEFAULT_ICON
;
DLGITEMTEMPLATE	ES_CENTER+WS_CONTROL+WS_BORDER+WS_DISABLED,\
		161, 83, 18, 18,\
		-1, EDIT,\
		<>
;
DLGITEMTEMPLATE	SS_ICON+WS_CONTROL,\
		162, 84, 16, 16,\
		-1, STATIC,\
		-1, DEFAULT_ICON
;
TextBoxHelpAbout	DWORD	IDC_HELP_ABOUT_INFO
			DWORD	NULL
;
;==============================================================================
;
;	DIALOG PALETTES
;
;------------------------------------------------------------------------------
;
PaletteStandardDlg	DIALOGPALETTE {RGB_BLACK, RGB_SOLIDLTGRAY,\
				       RGB_BLACK, RGB_SOLIDLTGRAY,\
				       RGB_RED,   RGB_WHITE,\
				       RGB_RED,   RGB_WHITE,\
				       RGB_BLACK, RGB_WHITE}
;
PaletteStatusDlg	DIALOGPALETTE {RGB_WHITE, RGB_BLUE,\
				       RGB_WHITE, RGB_BLUE,\
				       RGB_RED,   RGB_WHITE,\
				       RGB_RED,   RGB_WHITE,\
				       RGB_BLACK, RGB_WHITE}
;
PaletteHelpAbout	DIALOGPALETTE {RGB_BLACK,  RGB_SOLIDLTGRAY,\
				       RGB_BLACK,  RGB_SOLIDLTGRAY,\
				       RGB_DKBLUE, RGB_SOLIDLTGRAY,\
				       RGB_DKBLUE, RGB_SOLIDLTGRAY,\
				       RGB_BLACK,  RGB_WHITE}
;
;==============================================================================
;
;	MAIN MENU
;
;------------------------------------------------------------------------------
;
tMainMenu		equ	$
;
hMainMenu		HMENU	NULL			;main menu handle
;
hFileMenu		HMENU	NULL			;file menu handle
			DWORD	MF_ENABLED
			STRING	<&File/0/1>
;
			DWORD	IDM_FILE_EXIT
			DWORD	MF_ENABLED + MF_UNCHECKED
			STRING	<E&xit/0/0>
;
hHelpMenu		HMENU	NULL			;help menu handle
			DWORD	MF_ENABLED
			STRING	<&Help/0/1>
;
			DWORD	IDM_HELP_HOWTO
			DWORD	MF_ENABLED + MF_UNCHECKED
			STRING	<&How to Use Help/0/1>
;
			DWORD	0	;separator
			DWORD	0
			STRING	</0/1>
;
			DWORD	IDM_HELP_ABOUT
			DWORD	MF_ENABLED + MF_UNCHECKED
			STRING	<&About MiniApp/0/0>
;
			DWORD	-1			;end
;
;==============================================================================
;
;	MESSAGES
;
;------------------------------------------------------------------------------
;
sDialogDirOverflow:	STRING	<A dialog directory overflow occurred. The >
			STRING	<next dialog window will use the default >
			STRING	<system colors./0>
;
;==============================================================================
;
;	MISCELLANEOUS
;
;------------------------------------------------------------------------------
;
sMainClass:		STRING	  <MiniApp/0>
sMainCaption:		STRING	  <Win32 Miniature Application/0>
sExtDataFile:		STRING	  <.ini/0>
sExtHelpFile:		STRING	  <.hlp/0>
sNull:			STRING	  </0>
;
;------------------------------------------------------------------------------
;
hStatusBar		HWND	  NULL
dStatusBarParts		DWORD	  1, -1
;
RectMainWnd		RECT	  {-1, -1, 640, 480}
;
MainWnd			WNDPARAMETERS {NULL,\
				       SYSTEM_FIXED_FONT,\
				       RGB_BLACK, RGB_SOLIDLTGRAY, OPAQUE}
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
sDataFile		CHAR MAX_PATH dup (?)
sHelpFile		CHAR MAX_PATH dup (?)
;
;------------------------------------------------------------------------------
;
hInst			HINSTANCE ?	
WndClass		WNDCLASS {}
Msg			MSG {}
Rect			RECT {}
PaintStruct		PAINTSTRUCT {}
;
;------------------------------------------------------------------------------
;
DialogDirectory		DIALOGRECORD MAX_DIALOGS dup ({})
;
;==============================================================================
;
EndUData
;
;==============================================================================
;
EndImage

