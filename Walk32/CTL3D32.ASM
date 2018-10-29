;
;	________________________________________________________________
;
;	                          CTL3D32.asm
;	                     CTL3D32 Stub DLL V1.00
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
; Recommended MASM command line: ml /I. /Zm /c /Cp /Ta CTL3D32.asm
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
; Remarks
; -------
;
; Copy this DLL to the Windows 95 system directory if you want to run Windows
; NT applications using 3D effects under Windows 95. This DLL exports stubs for
; the CTL3D32 functions Ctl3dRegister, Ctl3dAutoSubclass, and Ctl3dUnregister.
; The stubs simply return TRUE to signal success to the client, thus allowing
; it to start up without error. Windows 95 will add 3D effects to the dialogs
; automatically. If you are using this DLL under Windows NT, all 3D effects
; will disappear, yielding a "flat" dialog style.
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
;	EXPORTED FUNCTIONS
;
;==============================================================================
;
public	Ctl3dRegister
public	Ctl3dAutoSubclass
public	Ctl3dUnregister
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
	mov	eax,hInstDLL			;make hInstDLL global
	mov	hInst,eax
	mov	eax,TRUE			;initialization ok
	ret
;
;==============================================================================
;
;	DLL SERVICES
;
;==============================================================================
;
Ctl3dRegister:
Ctl3dAutoSubclass:
Ctl3dUnregister:
	mov	eax,TRUE			;report success
	ret	4
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
sMainCaption:		STRING	<CTL3D32 Stub DLL/0>
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
;
;------------------------------------------------------------------------------
;
hInst			HINSTANCE ?	
;
;==============================================================================
;
EndUData
;
;==============================================================================
;
EndImage

