;
;	________________________________________________________________
;
;	                          W32Link.ASM
;	                   Win32 PE File Linker V1.00
;	        03-16-1996 Sven B. Schreiber sbs@psbs.franken.de
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
; Recommended MASM command line: ml /I. /Zm /c /Cp /Ta W32Link.asm
;
;==============================================================================
;
; Important Notes
; ---------------
;
; W32Link is Public Domain Software and is distributed with the ASM source
; code included. This software package may be distributed freely on any media
; including bulletin board systems and Internet hosts, provided that all files
; are included and no fee is charged for the software. Although all code and
; documentation belongs to the Public Domain, I strongly recommend that all
; changes be documented properly, including the name of the author, the date,
; and what parts have been changed in which way. Feel free to contact me at
; sbs@psbs.franken.de, 100557.177@compuserve.com, or sbs_msn@msn.com.
;
; DISCLAIMER
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
; Version History
; ---------------
;
; 03-16-1996  V1.00  SBS  Original Version
;
;==============================================================================
;
;	SWITCHES
;
;==============================================================================
;
CONSOLE			equ	0		;0 = gui, 1 = console
UNICODE			equ	0		;0 = ansi, 1 = unicode
DLL			equ	0		;0 = application, 1 = dll
;
IMPORT			equ	"NT"		;NT = Win NT, 95 = Win 95
;
;------------------------------------------------------------------------------
;
DETAILS			equ	0		;0 = no details, 1 = verbose
SILENT			equ	0		;0 = output enabled, 1 = silent
;
;==============================================================================
;
;	INTERNAL DEFINITIONS
;
;==============================================================================
;
APP_EXTENSION		textequ	<".exe",0>	;application file extension
DLL_EXTENSION		textequ	<".dll",0>	;dll file extension
;
;------------------------------------------------------------------------------
;
			if	CONSOLE
DEFAULT_SUBSYS		equ	PE_SUBSYS_WINDOWS_CUI
			else
DEFAULT_SUBSYS		equ	PE_SUBSYS_WINDOWS_GUI
			endif
;
;------------------------------------------------------------------------------
;
			if	UNICODE
DEFAULT_API		equ	'W'		;unicode api variant
			else
DEFAULT_API		equ	'A'		;ansi api variant
			endif
;
;------------------------------------------------------------------------------
;
			if	DLL
DEFAULT_BASE		equ	DLL_BASE
DEFAULT_EXTENSION	textequ	DLL_EXTENSION
DEFAULT_ATTRIBUTES	equ	PE_DEFAULT_ATTRIBUTES + PE_DLL
			else
DEFAULT_BASE		equ	APP_BASE
DEFAULT_EXTENSION	textequ	APP_EXTENSION
DEFAULT_ATTRIBUTES	equ	PE_DEFAULT_ATTRIBUTES
			endif
;
;------------------------------------------------------------------------------
;
DEFAULT_IMPORT		=	0
_IMPORT_		=	IMPORT
;
			while	_IMPORT_
DEFAULT_IMPORT		=	(DEFAULT_IMPORT * 256) + (_IMPORT_ mod 256)
_IMPORT_		=	_IMPORT_ / 256
			endm
;
;==============================================================================
;
;	GENERAL CONSTANTS
;
;==============================================================================
;
PARAGRAPH		equ	    0010h	;paragraph size
FILE_PAGE		equ	    0200h	;file page size
MEMORY_PAGE		equ	    1000h	;memory page size
APP_BASE		equ	00400000h	;application base address
DLL_BASE		equ	10000000h	;dll base address
OUTPUT_BLOCK		equ	    8000h	;output block size
PATH_LENGTH		equ	     260	;maximum path length
SNL			equ	       8	;section name length
;
;------------------------------------------------------------------------------
;
PAGE_FILL		equ	       0	;page fill byte
LINKER_VERSION_H	equ	       2	;linker major version
LINKER_VERSION_L	equ	      55	;linker minor version
OS_VERSION_H		equ	       1	;os major version
OS_VERSION_L		equ	      00	;os minor version
IMAGE_VERSION_H		equ	       0	;image major version
IMAGE_VERSION_L		equ	      00	;image minor version
SUBSYS_VERSION_H	equ	       4	;subsystem major version
SUBSYS_VERSION_L	equ	      00	;subsystem minor version
;
;------------------------------------------------------------------------------
;
RT_CURSOR		equ	   1		;cursor resource id
RT_BITMAP		equ	   2		;bitmap resource id
RT_ICON			equ	   3		;icon resource id
RT_MENU			equ	   4		;menu resource id
RT_DIALOG		equ	   5		;dialog resource id
RT_STRING		equ	   6		;string resource id
RT_FONTDIR		equ	   7		;font directory resource id
RT_FONT			equ	   8		;font resource id
RT_ACCELERATOR		equ	   9		;accelerator resource id
RT_RCDATA		equ	  10		;rc data resource id
RT_MESSAGETABLE		equ	  11		;message table resource id
RT_GROUP_CURSOR		equ	  12		;group cursor resource id
RT_GROUP_ICON		equ	  14		;group icon resource id
RT_VERSION		equ	  16		;version resource id
RT_DLGINCLUDE		equ	  17		;dialog include resource id
RT_PLUGPLAY		equ	  19		;pnp resource id
RT_VXD			equ	  20		;vxd resource id
;
;------------------------------------------------------------------------------
;
LANG_GERMAN		equ	07h		;primary language: german
LANG_ENGLISH		equ	09h		;primary language: english
;
ENGLISH_US		equ	01h		;english / usa
ENGLISH_UK		equ	02h		;english / uk
ENGLISH_AUS		equ	03h		;english / australian
ENGLISH_CAN		equ	04h		;english / canadian
ENGLISH_NZ		equ	05h		;english / new zealand
ENGLISH_EIRE		equ	06h		;english / irish
ENGLISH_SAFRICA		equ	07h		;english / south africa
ENGLISH_JAMAICA		equ	08h		;english / jamaica
ENGLISH_CARRIBEAN	equ	09h		;english / carribean
;
GERMAN			equ	01h		;german
GERMAN_SWISS		equ	02h		;german / swiss
GERMAN_AUSTRIAN		equ	03h		;german / austrian
GERMAN_LUXEMBOURG	equ	04h		;german / luxembourg
GERMAN_LIECHTENSTEIN	equ	05h		;german / liechtenstein
;
LANGUAGE_ID		equ	LANG_ENGLISH + (ENGLISH_US * 0400h)
;
;------------------------------------------------------------------------------
;
DATA_INIT		equ	0		;data initialization
DATA_NONE		equ	1		;no data
DATA_LEDATA		equ	2		;logical enumerated data
DATA_LIDATA16		equ	3		;logical iterated data (16-bit)
DATA_LIDATA32		equ	4		;logical iterated data (32-bit)
;
;------------------------------------------------------------------------------
;
SEG_ALIGNMENT		equ	11100000b	;segment alignment mask
SEG_COMBINATION		equ	00011100b	;segment combination mask
SEG_USE			equ	00000001b	;segment use mask
;
SEG_AT			equ	00000000b	;absolute alignment
SEG_BYTE		equ	00100000b	;byte alignment
SEG_WORD		equ	01000000b	;word alignment
SEG_PARA		equ	01100000b	;paragraph alignment
SEG_PAGE		equ	10000000b	;page alignment
SEG_DWORD		equ	10100000b	;dword alignment
;
SEG_PRIVATE		equ	00000000b	;private segment
SEG_MEMORY		equ	00000100b	;memory segment
SEG_PUBLIC2		equ	00001000b	;public segment
SEG_PUBLIC4		equ	00010000b	;public segment
SEG_STACK		equ	00010100b	;stack segment
SEG_COMMON		equ	00011000b	;common segment
SEG_PUBLIC7		equ	00011100b	;public segment
;
SEG_USE32		equ	00000001b	;32-bit segment
SEG_BIG			equ	00000010b	;big segment
;
;------------------------------------------------------------------------------
;
FIXUP_SUBRECORD		equ	10000000b	;fixup subrecord type
FIXUP_MODE		equ	01000000b	;fixup mode
FIXUP_LOCATION		equ	00111100b	;fixup location
FIXUP_OFFSET		equ	03FFh		;fixup data record offset
;
FIXUP_THREAD		equ	00000000b	;thread subrecord
FIXUP_FIXUP		equ	10000000b	;fixup subrecord
;
FIXUP_SELF_RELATIVE	equ	00000000b	;self-relative mode
FIXUP_SEG_RELATIVE	equ	01000000b	;segment-relative mode
;
FIXUP_LOW_BYTE		equ	00000000b	;low-order byte
FIXUP_OFFSET_16		equ	00000100b	;16-bit offset
FIXUP_BASE_16		equ	00001000b	;16-bit base
FIXUP_POINTER_16_16	equ	00001100b	;32-bit long pointer 16:16
FIXUP_HIGH_BYTE		equ	00010000b	;16-bit high-order byte
FIXUP_OFFSET_16_LDRES	equ	00010100b	;16-bit offset, loader-resolved
FIXUP_OFFSET_32		equ	00100100b	;32-bit offset
FIXUP_POINTER_16_32	equ	00101100b	;48-bit pointer 16:32
FIXUP_OFFSET_32_LDRES	equ	00110100b	;32-bit offset, loader-resolved
;
;------------------------------------------------------------------------------
;
FIXDATA_THREADS		equ	10001000b	;fix data thread flags
FIXDATA_F_METHOD	equ	01110000b	;fix data frame method
FIXDATA_T_METHOD	equ	00000111b	;fix data target method
FIXDATA_NO_DISP		equ	00000100b	;fix data no-displacement flag
;
FIXDATA_NO_THREADS	equ	00000000b	;no thread references
FIXDATA_T_THREAD	equ	00001000b	;target thread reference
FIXDATA_F_THREAD	equ	10000000b	;frame thread reference
FIXDATA_FT_THREADS	equ	10001000b	;frame and target thread refs
;
FIXDATA_F0		equ	00000000b	;frame method f0
FIXDATA_F1		equ	00010000b	;frame method f1
FIXDATA_F2		equ	00100000b	;frame method f2
FIXDATA_F3		equ	00110000b	;frame method f3
FIXDATA_F4		equ	01000000b	;frame method f4
FIXDATA_F5		equ	01010000b	;frame method f5
FIXDATA_F6		equ	01100000b	;frame method f6
FIXDATA_F7		equ	01110000b	;frame method f7
;
FIXDATA_T0		equ	00000000b	;target method t0
FIXDATA_T1		equ	00000001b	;target method t1
FIXDATA_T2		equ	00000010b	;target method t2
FIXDATA_T3		equ	00000011b	;target method t3
FIXDATA_T4		equ	00000100b	;target method t4
FIXDATA_T5		equ	00000101b	;target method t5
FIXDATA_T6		equ	00000110b	;target method t6
FIXDATA_T7		equ	00000111b	;target method t7
;
;------------------------------------------------------------------------------
;
MODTYPE_MAIN		equ	10000000b	;main module flag
MODTYPE_START		equ	01000000b	;start address flag
MODTYPE_SEGMENT		equ	00100000b	;segment bit (not used)
MODTYPE_X		equ	00000001b	;relocatable start address flag
;
MODTYPE_LIB_MODULE	equ	00000000b	;library module
MODTYPE_MAIN_MODULE	equ	10000000b	;main module
;
MODTYPE_NO_ENTRY_POINT	equ	00000000b	;no entry point specified
MODTYPE_ENTRY_POINT	equ	01000000b	;entry point specified
;
MODTYPE_SEGMENT_0	equ	00000000b	;segment bit not set
MODTYPE_SEGMENT_1	equ	00100000b	;segment bit set
;
MODTYPE_ABSOLUTE	equ	00000000b	;absolute entry point
MODTYPE_RELOCATABLE	equ	00000001b	;relocatable entry point
;
;------------------------------------------------------------------------------
;
ENVIRONMENT		equ	002Ch		;environment pointer
COMMAND_TAIL		equ	0081h		;command tail address
;
;------------------------------------------------------------------------------
;
OPTION_ESCAPE		equ	'/'		;command option escape char
EXPORT_ESCAPE		equ	'@'		;export escape character
FORWARD_ESCAPE		equ	'@'		;forward escape character
FORWARD_SEPARATOR	equ	'.'		;forward reference separator
;
;------------------------------------------------------------------------------
;
DOS			equ	21h		;dos api
;
DOS_DISPLAY		equ	09h		;display string
DOS_GETDRIVE		equ	19h		;get current drive
DOS_GETDATE		equ	2Ah		;get system date
DOS_GETTIME		equ	2Ch		;get system time
DOS_CREATE		equ	3Ch		;create file
DOS_OPEN		equ	3Dh		;open file
DOS_CLOSE		equ	3Eh		;close file
DOS_READ		equ	3Fh		;read file
DOS_WRITE		equ	40h		;write file
DOS_MOVEPOINTER		equ	42h		;move file pointer
DOS_GETDIRECTORY	equ	47h		;get current directory
DOS_ALLOCATE		equ	48h		;allocate memory block
DOS_REALLOCATE		equ	4Ah		;reallocate memory block
DOS_TERMINATE		equ	4Ch		;terminate program
DOS_GETPSP		equ	51h		;get current psp address
;
;------------------------------------------------------------------------------
;
OF_READ			equ	0000h		;read only mode
OF_WRITE		equ	0001h		;write only mode
OF_READWRITE		equ	0002h		;read/write mode
OF_SHARE_COMPAT		equ	0000h		;compatibility mode
OF_SHARE_EXCLUSIVE	equ	0010h		;deny read/write access if open
OF_SHARE_DENY_WRITE	equ	0020h		;deny write access if open
OF_SHARE_DENY_READ	equ	0030h		;deny read access if open
OF_SHARE_DENY_NONE	equ	0040h		;don't deny read/write access
;
;------------------------------------------------------------------------------
;
STDIN			equ	00		;standard input
STDOUT			equ	01		;standard output
STDERR			equ	02		;standard error output
STDAUX			equ	03		;standard comm output
STDPRN			equ	04		;standard printer output
;
;------------------------------------------------------------------------------
;
SECONDS_PER_MINUTE	equ	60			;seconds per minute
SECONDS_PER_HOUR	equ	60*SECONDS_PER_MINUTE	;seconds per hour
;
SECONDS_PER_DAY_LOW	equ	5180h			;seconds per day
SECONDS_PER_DAY_HIGH	equ	0001h
;
SECONDS_PER_YEAR_LOW	equ	3380h			;seconds per year
SECONDS_PER_YEAR_HIGH	equ	01E1h
;
;------------------------------------------------------------------------------
;
RET_NORMAL_END		equ	00		;program terminated normally
RET_INVALID_COMMAND	equ	01		;invalid command line
RET_MEMORY_ERROR	equ	02		;memory allocation error
RET_OUT_OF_MEMORY	equ	03		;not enough memory available
RET_INIT_FAILURE	equ	04		;program initialization failure
RET_ICON_NOT_LOADED	equ	05		;unable to load icon
RET_FILE_NOT_FOUND	equ	06		;input file not found
RET_FILE_NOT_SAVED	equ	07		;output file not saved
RET_FILE_IO_ERROR	equ	08		;file i/o error
RET_NO_OMF_FILE		equ	09		;input file format invalid
RET_END_OF_FILE		equ	10		;unexpected end of input file
RET_INVALID_DATA	equ	11		;invalid input file data
;
;------------------------------------------------------------------------------
;
LF			equ	0Ah		;linefeed
CR			equ	0Dh		;carriage return
EOF			equ	1Ah		;end of file
;
;==============================================================================
;
;	GENERAL STRUCTURES
;
;==============================================================================
;
MCB			struct
mcbTag			BYTE	0		;tag field
mcbOwner		WORD	0		;memory block owner
mcbSize			WORD	0		;memory block size
mcbReserved		BYTE	3 dup (0)	;(reserved)
mcbProcess		BYTE	8 dup (0)	;process name
MCB			ends
MCB_			equ	1+2+2+3+8
;
;------------------------------------------------------------------------------
;
ICONDIR			struct
icReserved		WORD	0		;(reserved)
icType			WORD	0		;resource type
icCount			WORD	0		;number of directory entries
ICONDIR			ends
ICONDIR_		equ	2+2+2
;
;------------------------------------------------------------------------------
;
ICONDIRENTRY		struct
ieWidth			BYTE	0		;icon width
ieHeight		BYTE	0		;icon height
ieColorCount		BYTE	0		;number of colors
ieReserved		BYTE	0		;(reserved)
iePlanes		WORD	0		;number of color planes
ieBitCount		WORD	0		;number of color bits
ieBytesInRes		DWORD	0		;size of the resource
ieImageOffset		DWORD	0		;icon image offset
ICONDIRENTRY		ends
ICONDIRENTRY_		equ	1+1+1+1+2+2+4+4
;
;------------------------------------------------------------------------------
;
WIN32_INDEX		struct
wiModule		WORD	0		;module name pointer
wiSymbol		WORD	0		;symbol pointer
wiOrdinal		WORD	0		;ordinal number
WIN32_INDEX		ends
WIN32_INDEX_		equ	2+2+2
;
;------------------------------------------------------------------------------
;
LNAMES			struct
lnSymbol		WORD	0		;name pointer
LNAMES			ends
LNAMES_			equ	2
;
;------------------------------------------------------------------------------
;
LNAMES_INDEX		struct
liNext			WORD	0		;next free offset
liData			LNAMES	0040h dup ({})	;data space
LNAMES_INDEX		ends
LI_DATA_		equ	0040h*LNAMES_
LNAMES_INDEX_		equ	2+LI_DATA_
;
;------------------------------------------------------------------------------
;
PUBDEF			struct
pdSymbol		WORD	0		;public symbol pointer
pdAddress		DWORD	0		;public address
PUBDEF			ends
PUBDEF_			equ	2+4
;
;------------------------------------------------------------------------------
;
PUBDEF_INDEX		struct
piNext			WORD	0		;next free offset
piData			PUBDEF	0080h dup ({})	;data space
PUBDEF_INDEX		ends
PI_DATA_		equ	0080h*PUBDEF_
PUBDEF_INDEX_		equ	2+PI_DATA_
;
;------------------------------------------------------------------------------
;
EXTDEF			struct
edModule		WORD	0		;external module name pointer
edUserSymbol		WORD	0		;external user symbol pointer
edSystemSymbol		WORD	0		;external system symbol pointer
edLength		WORD	0		;external system symbol length
edOrdinal		WORD	0		;external ordinal number
edAddress		DWORD	0		;external address
EXTDEF			ends
EXTDEF_			equ	2+2+2+2+2+4
;
;------------------------------------------------------------------------------
;
EXTDEF_INDEX		struct
eiNext			WORD	0		;next free offset
eiData			EXTDEF	0400h dup ({})	;data space
EXTDEF_INDEX		ends
EI_DATA_		equ	0400h*EXTDEF_
EXTDEF_INDEX_		equ	2+EI_DATA_
;
;------------------------------------------------------------------------------
;
MODDEF			struct
mdModule		WORD	0		;module name pointer
mdLength		WORD	0		;module name length
mdCount			WORD	0		;reference count
MODDEF			ends
MODDEF_			equ	2+2+2
;
;------------------------------------------------------------------------------
;
MODDEF_INDEX		struct
miNext			WORD	0		;next free offset
miData			MODDEF	0040h dup ({})	;data space
MODDEF_INDEX		ends
MI_DATA_		equ	0040h*MODDEF_
MODDEF_INDEX_		equ	2+MI_DATA_
;
;------------------------------------------------------------------------------
;
SEGDEF_DATA		struct
sdNumber		WORD	0		;segment number
sdAttributes		BYTE	0		;segment attributes
sdSymbol		WORD	0		;segment name pointer
sdClass			WORD	0		;segment class pointer
sdLength		DWORD	0		;segment length
sdFrame			WORD	0		;absolute frame
sdOffset		WORD	0		;absolute offset
SEGDEF_DATA		ends
SEGDEF_DATA_		equ	2+1+2+2+4+2+2
;
;------------------------------------------------------------------------------
;
SYMBOL_TABLE		struct
stNext			WORD	0		;next free offset
stCount			WORD	0		;number of available bytes
stData			BYTE	7800h dup (0)	;data space
SYMBOL_TABLE		ends
SYMBOL_TABLE_		equ	2+2+7800h
;
;------------------------------------------------------------------------------
;
SECTION_DATA		struct
scFileBytes		DWORD	0		;number of file bytes
scMemoryBytes		DWORD	0		;number of memory bytes
scSectionName		BYTE	SNL dup (0)	;section name
SECTION_DATA		ends
SECTION_DATA_		equ	4+4+SNL
;
;------------------------------------------------------------------------------
;
FIXUP_BASE_RELOC	struct
brMemoryOffset		DWORD	0		;destination offset
FIXUP_BASE_RELOC	ends
FIXUP_BASE_RELOC_	equ	4
;
;------------------------------------------------------------------------------
;
FIXUP_EXTERNAL		struct
exFileOffset		DWORD	0		;destination offset
exExternal		WORD	0		;extdef offset
FIXUP_EXTERNAL		ends
FIXUP_EXTERNAL_		equ	4+2
;
;==============================================================================
;
;	PE CONSTANTS
;
;==============================================================================
;
PE_MACHINE_UNKNOWN	equ	0000h		;unknown machine
PE_MACHINE_I386		equ	014ch		;intel 386+ and compatible
PE_MACHINE_R3000B	equ	0160h		;mips (big endian)
PE_MACHINE_R3000	equ	0162h		;mips (little endian)
PE_MACHINE_R4000	equ	0166h		;mips (little endian)
PE_MACHINE_R10000	equ	0168h		;mips (little endian)
PE_MACHINE_ALPHA	equ	0184h		;alpha axp
PE_MACHINE_POWERPC	equ	01F0h		;power pc (little endian)
;
;------------------------------------------------------------------------------
;
PE_RELOCS_STRIPPED	equ	0001h		;relocation info stripped
PE_EXECUTABLE_IMAGE	equ	0002h		;file is executable
PE_LINE_NUMS_STRIPPED	equ	0004h		;line numbers stripped
PE_LOCAL_SYMS_STRIPPED	equ	0008h		;local symbols stripped
PE_16BIT_MACHINE	equ	0040h		;16-bit word machine
PE_BYTES_REVERSED_LO	equ	0080h		;little endian
PE_32BIT_MACHINE	equ	0100h		;32-bit word machine
PE_DEBUG_STRIPPED	equ	0200h		;debugging info stripped
PE_SYSTEM		equ	1000h		;system file
PE_DLL			equ	2000h		;file is a dll
PE_BYTES_REVERSED_HI	equ	8000h		;big endian
;
PE_DEFAULT_ATTRIBUTES	equ	PE_EXECUTABLE_IMAGE+\
				PE_32BIT_MACHINE+\
				PE_LINE_NUMS_STRIPPED+\
				PE_LOCAL_SYMS_STRIPPED+\
				PE_DEBUG_STRIPPED
;
;------------------------------------------------------------------------------
;
PE_SUBSYS_UNKNOWN	equ	0		;unknown subsystem
PE_SUBSYS_NATIVE	equ	1		;no subsystem required
PE_SUBSYS_WINDOWS_GUI	equ	2		;win graphical user interface
PE_SUBSYS_WINDOWS_CUI	equ	3		;win character user interface
PE_SUBSYS_OS2_CUI	equ	5		;os/2 character user interface
PE_SUBSYS_POSIX_CUI	equ	7		;posix character user interface
;
;------------------------------------------------------------------------------
;
PE_CODE			equ	00000020h	;code section
PE_INITIALIZED_DATA	equ	00000040h	;initialized data section
PE_UNINITIALIZED_DATA	equ	00000080h	;uninitialized data section
PE_DISCARDABLE		equ	02000000h	;discardable section
PE_NOT_CACHED		equ	04000000h	;non-cachable section
PE_NOT_PAGED		equ	08000000h	;non-pageable section
PE_SHARED		equ	10000000h	;shareable section
PE_EXECUTE		equ	20000000h	;executable section
PE_READ			equ	40000000h	;readable section
PE_WRITE		equ	80000000h	;writeable section
;
;------------------------------------------------------------------------------
;
PE_TEXT			equ	060000020h	;.text section flags
PE_BSS			equ	0C0000080h	;.bss section flags
PE_DATA			equ	0C0000040h	;.data section flags
PE_LINK			equ	0C0000040h	;.link section flags
PE_RELOC		equ	042000040h	;.reloc section flags
PE_RSRC			equ	040000040h	;.rsrc section flags
;
;------------------------------------------------------------------------------
;
PE_BASED_ABSOLUTE	equ	0		;fixup is skipped
PE_BASED_HIGH		equ	1		;add high 16 bits of delta
PE_BASED_LOW		equ	2		;add low 16 bits of delta
PE_BASED_HIGHLOW	equ	3		;add 32-bit delta
PE_BASED_HIGHADJ	equ	4		;apply full 32-bit value
PE_BASED_MIPS_JMPADDR	equ	5		;fixup mips jmp instruction
;
;------------------------------------------------------------------------------
;
PE_RSRC_IS_ID		equ	0000h		;resource identified by id
PE_RSRC_IS_STRING	equ	8000h		;resource identified by string
PE_RSRC_IS_DATA		equ	0000h		;resource entry points to data
PE_RSRC_IS_DIR		equ	8000h		;resource entry points to dir
;
;------------------------------------------------------------------------------
;
PE_REL_MASK_OFFSET	equ	00FFFh		;base relocation offset mask
PE_REL_MASK_PAGE	equ	0F000h		;base relocation type mask
;
PE_REL_ABSOLUTE		equ	00000h		;no relocation (skip fixup)
PE_REL_HIGH		equ	01000h		;add upper 16 bits of delta
PE_REL_LOW		equ	02000h		;add lower 16 bits of delta
PE_REL_HIGHLOW		equ	03000h		;add 32-bit delta
PE_REL_HIGHADJ		equ	04000h		;32-bit fixup
PE_REL_MIPS_JMPADDR	equ	05000h		;fixup mips jump instruction
;
;==============================================================================
;
;	PE STRUCTURES
;
;==============================================================================
;
PE_SECTION_HEADER	struct
shName			BYTE	SNL dup (0)	;section name
shLoadSize		DWORD	0		;section size in memory
shLoadAddress		DWORD	0		;section address in memory
shRawSize		DWORD	0		;section size in file
shRawAddress		DWORD	0		;section address in file
shRelocations		DWORD	0		;address of relocation entries
shLineNumbers		DWORD	0		;address of line number entries
shNumRelocations	WORD	0		;number of relocation entries
shNumLineNumbers	WORD	0		;number of line number entries
shAttributes		DWORD	0		;section attributes
PE_SECTION_HEADER	ends
PE_SECTION_HEADER_	equ	SNL+4+4+4+4+4+4+2+2+4
;
;------------------------------------------------------------------------------
;
PE_DATADIR		struct
ddAddress		DWORD	0		;section address
ddSize			DWORD	0		;section size
PE_DATADIR		ends
PE_DATADIR_		equ	4+4
;
;------------------------------------------------------------------------------
;
PE_IMPORT_DIR		struct
idLookupTable		DWORD	0		;pointer to import lookup table
idTimeDate		DWORD	0		;time/date stamp
idForwarderChain	DWORD	0		;pointer to forwarder chain
idModuleName		DWORD	0		;pointer to module name
idAddressTable		DWORD	0		;pointer to import addr table
PE_IMPORT_DIR		ends
PE_IMPORT_DIR_		equ	4+4+4+4+4
;
;------------------------------------------------------------------------------
;
PE_EXPORT_DIR		struct
epExportFlags		DWORD	0		;export flags (reserved)
epTimeDate		DWORD	0		;time/date stamp
epMajorVersion		WORD	0		;major version number
epMinorVersion		WORD	0		;minor version number
epModuleName		DWORD	0		;pointer to module name
epOrdinalBase		DWORD	0		;starting ordinal number
epNumberOfEntries	DWORD	0		;number of table entries
epNumberOfNames		DWORD	0		;number of named exports
epAddressTable		DWORD	0		;pointer to address table
epNamePointerTable	DWORD	0		;pointer to name pointer table
epOrdinalTable		DWORD	0		;pointer to ordinal table
PE_EXPORT_DIR		ends
PE_EXPORT_DIR_		equ	4+4+2+2+4+4+4+4+4+4+4
;
;------------------------------------------------------------------------------
;
PE_RSRC_DIR		struct
rdCharacteristics	DWORD	0		;characteristics
rdTimeDate		DWORD	0		;time/date stamp
rdMajorVersion		WORD	0		;major version
rdMinorVersion		WORD	0		;minor version
rdNumberOfNamedEntries	WORD	0		;number of named entries
rdNumberOfIdEntries	WORD	0		;number of id entries
PE_RSRC_DIR		ends
PE_RSRC_DIR_		equ	4+4+2+2+2+2
;
;------------------------------------------------------------------------------
;
PE_RSRC_DIR_ENTRY	struct
rdirIdOrPointer		WORD	0		;resource id or string pointer
rdirIdOrPointerFlag	WORD	0
rdirDataOrSubdir	WORD	0		;data or subdirectory offset
rdirDataOrSubdirFlag	WORD	0
PE_RSRC_DIR_ENTRY	ends
PE_RSRC_DIR_ENTRY_	equ	4+4
;
;------------------------------------------------------------------------------
;
PE_RSRC_DATA_ENTRY	struct
rdataAddress		DWORD	0		;resource data address
rdataSize		DWORD	0		;resource data size
rdataCodePage		DWORD	0		;code page
rdataReserved		DWORD	0		;(reserved)
PE_RSRC_DATA_ENTRY	ends
PE_RSRC_DATA_ENTRY_	equ	4+4+4+4
;
;------------------------------------------------------------------------------
;
PE_RSRC_DIR_STRING_U	struct
rdsuLength		WORD	0		;length of name string
rdsuNameString		WORD	0		;name string (unicode)
PE_RSRC_DIR_STRING_U	ends
PE_RSRC_DIR_STRING_U_	equ	2+2
;
;------------------------------------------------------------------------------
;
PE_FIXUP_BLOCK		struct
fbPage			DWORD	0		;base page
fbSize			DWORD	0		;block size
PE_FIXUP_BLOCK		ends
PE_FIXUP_BLOCK_		equ	4+4
;
;==============================================================================
;
;	CODE SEGMENT
;
;==============================================================================
;
_text	segment	public 'CODE'
	assume	cs:_text,ds:_data
;
;------------------------------------------------------------------------------
;
	WORD	CodeSegment_
	BYTE	" Code Segment "
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
Main:
	mov	ah,DOS_GETPSP			;load base segment address
	int	DOS
	mov	es,bx
	mov	ax,_data			;load data segment address
	mov	ds,ax
	sub	ax,bx				;compute psp/code/stack size
	mov	bx,DataSegment_			;compute data segment size
	dec	bx
	mov	cl,4
	shr	bx,cl
	inc	bx
	add	bx,ax				;add segment sizes
	mov	ah,DOS_REALLOCATE		;set program memory block size
	int	DOS
	mov	si,offset sMemoryError
	mov	al,RET_MEMORY_ERROR
	jb	Main1
	mov	si,offset sBanner		;display banner
	call	InfoString
	call	GetTimeDate			;get time/date stamp
	mov	word ptr dTimeDate,di
	mov	word ptr dTimeDate+2,si
	call	ParseCommandLine		;parse command line
	mov	si,offset sInvalidCommand
	mov	al,RET_INVALID_COMMAND
	jb	Main1
	call	GetFileNames			;get file names
	mov	si,offset sInitFailure
	mov	al,RET_INIT_FAILURE
	jb	Main1
	call	AllocateBuffers			;allocate buffers
	mov	si,offset sOutOfMemory
	mov	al,RET_OUT_OF_MEMORY
	jb	Main1
	call	Execute				;execute program
Main1:
	cmp	si,0				;final message?
	jz	Main2
	push	ax
	call	InfoString			;display message
	pop	ax
Main2:
	mov	ah,DOS_TERMINATE		;terminate program
	int	DOS
;
;==============================================================================
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
ParseCommandLine:
	mov	di,FileParameter		;load file name buffer address
	mov	cx,FileParameter_		;load file name buffer size
	mov	si,COMMAND_TAIL			;evaluate command tail
ParseCommandLine1:
	inc	si				;skip initial spaces
	cmp	byte ptr es:[si-1],' '
	jz	ParseCommandLine1
	cmp	byte ptr es:[si-1],OPTION_ESCAPE ;command option?
	jnz	ParseCommandLine4
	cmp	byte ptr es:[si],0		;end of command tail?
	jz	ParseCommandLine6
	mov	bx,CommandOptions		;load command option table
	mov	al,es:[si]			;load option id
	inc	si
	cmp	al,'a'				;convert to upper case
	jb	ParseCommandLine2
	cmp	al,'z'
	ja	ParseCommandLine2
	add	al,'A'-'a'
ParseCommandLine2:
	cmp	byte ptr [bx],0			;end of table?
	jz	ParseCommandLine6
	cmp	byte ptr [bx],al		;option id found?
	jz	ParseCommandLine3
	add	bx,1+2				;next entry
	jmp	ParseCommandLine2
ParseCommandLine3:
	push	di
	push	cx
	call	[bx+1]				;call option handler
	pop	cx
	pop	di
	jmp	ParseCommandLine1
ParseCommandLine4:
	dec	si				;set pointer to file name
	mov	dx,di				;save file name buffer address
	mov	bx,di				;set end marker
ParseCommandLine5:
	cmp	cx,1				;buffer full?
	jna	ParseCommandLine7
	mov	al,es:[si]			;copy character
	inc	si
	mov	[di],al
	inc	di
	dec	cx
	cmp	al,CR				;end?
	jz	ParseCommandLine7
	cmp	al,' '				;look for trailing spaces
	jz	ParseCommandLine5
	mov	bx,di				;advance end marker
	jmp	ParseCommandLine5
ParseCommandLine6:
	push	di
	mov	si,offset sInvalidOption	;display error message
	call	InfoString
	pop	di
	mov	dx,di				;save file name buffer address
	mov	bx,di				;set end marker
ParseCommandLine7:
	mov	byte ptr [bx],0			;terminate string
	sub	bx,dx				;nothing specified?
	cmp	bx,1
	ret
;
;==============================================================================
;
;	>	si  -  command tail
;
;	<	si  -  remaining command tail
;
;------------------------------------------------------------------------------
;
OptionDetails:
	mov	bx,offset bVerboseMode		;toggle verbose mode flag
	cmp	byte ptr [bx],1
	sbb	al,al
	neg	al
	mov	[bx],al
	mov	cl,bVerboseModeCount		;load flag count
OptionDetails1:
	inc	bx				;copy verbose mode flag
	mov	[bx],al
	dec	cl				;next flag
	jnz	OptionDetails1
	cmp	al,1				;details on -> silent off			;
	sbb	al,al
	and	bSilentMode,al
	ret
;
;==============================================================================
;
;	>	si  -  command tail
;
;	<	si  -  remaining command tail
;
;------------------------------------------------------------------------------
;
OptionSilent:
	mov	bx,offset bSilentMode		;toggle silent mode flag
	cmp	byte ptr [bx],1
	sbb	al,al
	neg	al
	mov	[bx],al
	ret
;
;==============================================================================
;
;	>	si  -  command tail
;
;	<	si  -  remaining command tail
;
;------------------------------------------------------------------------------
;
OptionTable:
	mov	bDumpWin32Symbols,1		;set win32 symbol table flag
	mov	bSilentMode,0			;silent mode off
	ret
;
;==============================================================================
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
GetFileNames:
	mov	di,ProgramFile			;get program file path
	mov	cx,ProgramFile_
	call	GetProgramFile
	jb	GetFileNames2
	mov	si,FileParameter		;get full input file path
	mov	di,InputFile
	mov	cx,InputFile_
	call	GetTrueName
	mov	si,InputFile			;test input file path
	call	TestFile
	jnb	GetFileNames1
	mov	si,InputFile			;extension specified?
	call	TestFileExtension
	jnb	GetFileNames1
	mov	bx,offset sInputExtension	;try default extension
	mov	si,InputFile
	mov	di,InputFile
	mov	cx,InputFile_
	call	GetDataFile
	mov	si,InputFile			;test input file path again
	call	TestFile
	jnb	GetFileNames1
	mov	si,FileParameter		;restore input file path
	mov	di,InputFile
	mov	cx,InputFile_
	call	GetTrueName
GetFileNames1:
	mov	bx,offset sIconExtension	;get icon file path
	mov	si,InputFile
	mov	di,IconFile
	mov	cx,IconFile_
	call	GetDataFile
	jb	GetFileNames2
	mov	si,IconFile			;test icon file path
	call	TestFile
	jnb	GetFileNames2
	mov	bx,offset sIconExtension	;get icon file path
	mov	si,ProgramFile
	mov	di,IconFile
	mov	cx,IconFile_
	call	GetDataFile
	jb	GetFileNames2
	mov	si,IconFile			;test icon file path
	call	TestFile
	jnb	GetFileNames2
	mov	byte ptr IconFile,0		;no icon file available
	clc					;ok
GetFileNames2:
	ret
;
;==============================================================================
;
;	>	di  -  buffer
;		cx  -  buffer size
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
GetProgramFile:
	mov	bx,es				;save psp segment
	mov	dx,es:ENVIRONMENT		;set pointer to environment mcb
	dec	dx
	mov	es,dx
	mov	si,0000h
	cmp	es:[si.mcbTag],'M'		;test tag field
	jnz	GetProgramFile3
	cmp	es:[si.mcbOwner],bx		;test owner
	jnz	GetProgramFile3
	mov	dx,es:[si.mcbSize]		;load memory block size
	cmp	dx,0				;empty block?
	jz	GetProgramFile3
	cmp	dx,1000h			;block >= 64k?
	jnb	GetProgramFile3
	mov	si,0014h			;start searching
GetProgramFile1:
	mov	ax,es:[si-2]			;look for 00 00 01 00
	dec	ax
	or	ax,es:[si-4]
	jz	GetProgramFile2
	inc	si				;next byte
	test	si,0FFF0h			;new paragraph?
	jnz	GetProgramFile1
	dec	dx				;count paragraphs
	jnz	GetProgramFile1
	jmp	GetProgramFile3			;unexpected end
GetProgramFile2:
	mov	al,es:[si]			;copy character
	inc	si
	mov	[di],al
	inc	di
	dec	cx				;count characters
	cmp	al,0				;end of string?
	clc					;ok
	jz	GetProgramFile4
	jcxz	GetProgramFile3			;buffer overflow
	test	si,0FFF0h			;new paragraph?
	jnz	GetProgramFile2
	dec	dx				;count paragraphs
	jnz	GetProgramFile2
GetProgramFile3:
	stc					;error
GetProgramFile4:
	mov	es,bx				;restore psp segment
	ret
;
;==============================================================================
;
;	>	bx  -  extension
;		si  -  reference path
;		di  -  buffer
;		cx  -  buffer size
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
GetDataFile:
	mov	ax,si				;save reference path
	mov	dx,si				;set marker
GetDataFile1:
	cmp	byte ptr [si],0			;end of string?
	jz	GetDataFile4
	cmp	byte ptr [si],':'		;drive separator?
	jz	GetDataFile2
	cmp	byte ptr [si],'\'		;directory separator?
	jz	GetDataFile2
	cmp	byte ptr [si],'.'		;extension separator?
	jnz	GetDataFile3
GetDataFile2:
	mov	dx,si				;save separator position
GetDataFile3:
	inc	si				;next character
	jmp	GetDataFile1
GetDataFile4:
	xchg	si,dx				;marker on extension separator?
	cmp	byte ptr [si],'.'
	jz	GetDataFile5
	mov	si,dx				;set marker to end position
GetDataFile5:
	mov	dx,si				;compute prefix length
	sub	dx,ax
	mov	si,bx				;get length of new extension
GetDataFile6:
	inc	si
	cmp	byte ptr [si-1],0
	jnz	GetDataFile6
	sub	si,bx
	add	si,dx				;compute total length
	jb	GetDataFile9
	cmp	cx,si
	jb	GetDataFile9
	mov	si,ax
GetDataFile7:
	sub	dx,1				;end of prefix?
	jb	GetDataFile8
	mov	al,[si]				;copy character
	inc	si
	mov	[di],al
	inc	di
	jmp	GetDataFile7
GetDataFile8:
	mov	al,[bx]				;copy extension
	inc	bx
	mov	[di],al
	inc	di
	add	al,-1				;end?
	jb	GetDataFile8
GetDataFile9:
	ret
;
;==============================================================================
;
;	>	si  -  path
;		di  -  buffer
;		cx  -  buffer size
;
;------------------------------------------------------------------------------
;
GetTrueName:
	push	di
	mov	al,0				;use current directory
	cmp	byte ptr [si],0			;empty string?
	jz	GetTrueName1
	cmp	byte ptr [si+1],0		;single character?
	jz	GetTrueName1
	cmp	word ptr [si],'\\'		;unc name?
	jz	GetTrueName4
	cmp	byte ptr [si+1],':'		;no drive specified?
	jnz	GetTrueName1
	cmp	byte ptr [si+2],'\'		;full path?
	jz	GetTrueName4
	mov	al,[si]				;use specified drive
	add	si,2
GetTrueName1:
	push	si
	push	di
	push	cx
	mov	di,DirBuffer			;get drive and directory
	call	GetDirectory
	pop	cx
	pop	di
	pop	si
	mov	bx,DirBuffer			;copy drive and directory
GetTrueName2:
	mov	al,[bx]
	inc	bx
	cmp	byte ptr [si],'\'		;copy drive only?
	jnz	GetTrueName3
	cmp	al,'\'
	jz	GetTrueName4
GetTrueName3:
	mov	[di],al
	inc	di
	cmp	al,0
	loopnz	GetTrueName2
	dec	di				;skip string terminator
	inc	cx
GetTrueName4:
	mov	al,[si]				;copy specified path
	inc	si
	mov	[di],al
	inc	di
	cmp	al,0
	loopnz	GetTrueName4
	mov	byte ptr [di-1],0		;terminate string
	pop	di
	jmp	NormalizePath			;normalize path
;
;==============================================================================
;
;	>	al  -  drive (0 = current drive)
;		di  -  buffer
;
;------------------------------------------------------------------------------
;
GetDirectory:
	cmp	al,0				;current directory?
	jnz	GetDirectory1
	push	di
	mov	ah,DOS_GETDRIVE			;get current drive
	int	DOS
	pop	di
	add	al,'A'
GetDirectory1:
	cmp	al,'a'				;convert to upper case
	jb	GetDirectory2
	cmp	al,'z'
	ja	GetDirectory2
	add	al,'A'-'a'
GetDirectory2:
	mov	[di],al				;save drive
	mov	ax,'\:'
	mov	[di+1],ax
	push	di
	lea	si,[di+3]			;get current directory
	mov	dl,[di]
	sub	dl,'A'-1
	mov	ah,DOS_GETDIRECTORY
	int	DOS
	pop	di
GetDirectory3:
	inc	di				;skip to string end
	cmp	byte ptr [di-1],0
	jnz	GetDirectory3
	cmp	byte ptr [di-2],'\'
	jz	GetDirectory4
	mov	byte ptr [di-1],'\'		;append directory separator
	mov	byte ptr [di],0			;terminate string
GetDirectory4:
	ret
;
;==============================================================================
;
;	>	di  -  path
;
;------------------------------------------------------------------------------
;
NormalizePath:
	mov	dx,di				;save base address
	mov	si,di				;copy pointer
NormalizePath1:
	mov	al,[si]				;load character
	inc	si
	mov	[di],al				;copy character
	inc	di
	cmp	al,0				;end of string?
	jz	NormalizePath8
	cmp	al,'\'				;directory separator?
	jnz	NormalizePath1
NormalizePath2:
	mov	al,[si]				;load next character
	cmp	al,0				;delete trainling "\"
	jz	NormalizePath6
	cmp	al,'.'				;possibly "\." or "\.." ?
	jnz	NormalizePath1
	mov	al,[si+1]			;load another character
	cmp	al,0				;delete trailing "\."
	jz	NormalizePath6
	add	si,2				;skip "\."
	cmp	al,'\'
	jz	NormalizePath2
	sub	si,2
	cmp	al,'.'				;possibly "\.." ?
	jnz	NormalizePath1
	mov	al,[si+2]			;load another character
	cmp	al,0				;trailing "\.." ?
	jz	NormalizePath3
	cmp	al,'\'				;"\..\" ?
	jnz	NormalizePath1
NormalizePath3:
	add	si,3				;skip "\.."
	mov	bx,di				;find preceding "\"
NormalizePath4:
	dec	bx
	cmp	bx,dx				;back at the beginning?
	jna	NormalizePath5
	cmp	byte ptr [bx-1],'\'		;"\" found?
	jnz	NormalizePath4
	mov	di,bx				;delete last name
NormalizePath5:
	cmp	al,0				;end of string?
	jnz	NormalizePath2
NormalizePath6:
	mov	cx,di				;compute number of characters
	sub	cx,dx
	cmp	cx,3				;root?
	jnz	NormalizePath7
	cmp	byte ptr [di-2],':'
	jnz	NormalizePath7
	inc	di				;don't delete root indicator
NormalizePath7:
	dec	di				;terminate string
	mov	byte ptr [di],0
NormalizePath8:
	ret
;
;==============================================================================
;
;	>	si  -  path
;
;	<	 c  -  set if no extension
;
;------------------------------------------------------------------------------
;
TestFileExtension:
	mov	bx,si				;set marker
TestFileExtension1:
	cmp	byte ptr [si],0			;end of string?
	jz	TestFileExtension4
	cmp	byte ptr [si],':'		;drive separator?
	jz	TestFileExtension2
	cmp	byte ptr [si],'\'		;directory separator?
	jz	TestFileExtension2
	cmp	byte ptr [si],'.'		;extension separator?
	jnz	TestFileExtension3
TestFileExtension2:
	mov	bx,si				;save separator position
TestFileExtension3:
	inc	si				;next character
	jmp	TestFileExtension1
TestFileExtension4:
	mov	al,[bx]				;extension separator found?
	sub	al,'.'
	add	al,-1
	ret
;
;==============================================================================
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
AllocateBuffers:
	mov	bx,1000h			;allocate win32 symbol buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	wWin32Symbols,ax
	jb	AllocateBuffers1
	mov	bx,1000h			;allocate record buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	wRecordBuffer,ax
	jb	AllocateBuffers1
	mov	bx,1000h			;allocate output buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	wOutputBuffer,ax
	jb	AllocateBuffers1
	mov	bx,1000h			;allocate fixup buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	wFixupBuffer,ax
	jb	AllocateBuffers1
	mov	bx,InputParameters_+FileBuffer_	;allocate input backup buffer
	dec	bx
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	inc	bx
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	wInputBackup,ax
AllocateBuffers1:
	ret
;
;==============================================================================
;
;	<	si  -  message (0 if no message)
;		al  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
Execute:
	cmp	byte ptr IconFile,0		;icon file specified?
	jz	Execute1
	mov	bx,offset sIconFile		;display icon file name
	mov	si,IconFile
	call	InfoQuotedMessage
Execute1:
	mov	bx,offset sInputFile		;display input file name
	mov	si,InputFile
	call	InfoQuotedMessage
	mov	si,IconFile			;load icon
	mov	cx,wIconIndex
	call	LoadIcon
	mov	si,offset sIconNotLoaded	;icon not loaded
	mov	al,RET_ICON_NOT_LOADED
	jb	Execute3
	mov	si,InputFile			;open input file
	call	OpenInput
	mov	si,offset sFileNotFound		;input file not found
	mov	al,RET_FILE_NOT_FOUND
	jb	Execute3
	call	TestFileType			;validate input file format
	jb	Execute2
	call	ProcessRecords			;process input file records
	pushf
	push	si
	push	ax
	call	MemoryStatistics		;display memory statistics
	call	CloseOutput			;close output file
	sbb	dx,dx				;evaluate carry
	pop	ax
	pop	si
	popf
	jb	Execute2
	add	dx,1				;output file saved?
	mov	si,offset sFileNotSaved
	mov	al,RET_FILE_NOT_SAVED
Execute2:
	pushf
	push	si
	push	ax
	call	CloseInput			;close input file
	pop	ax
	pop	si
	popf
	jb	Execute3			;error
	mov	si,offset sNormalEnd		;ok
	mov	al,RET_NORMAL_END
Execute3:
	ret
;
;==============================================================================
;
;	>	si  -  path
;		cx  -  icon index
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
LoadIcon:
	cmp	byte ptr [si],0			;icon not specified?
	clc					;ok
	jz	LoadIcon4
	push	cx
	call	OpenInput			;open icon file
	pop	cx
	jb	LoadIcon4
	push	cx
	mov	di,IconDir			;load icon directory
	mov	cx,ICONDIR_
	call	ReadInputBlock
	pop	cx
	jb	LoadIcon2
	cmp	IconDir.icType,1		;test icon type
	jnz	LoadIcon2
	cmp	cx,IconDir.icCount		;test icon index
	jnb	LoadIcon2
LoadIcon1:
	push	cx
	mov	di,IconDirEntry			;load icon directory entry
	mov	cx,ICONDIRENTRY_
	call	ReadInputBlock
	pop	cx
	jb	LoadIcon2
	sub	cx,1				;count icon directory entries
	jnb	LoadIcon1
	cmp	IconDirEntry.ieWidth,ICON_WIDTH		;test icon width
	jnz	LoadIcon2
	cmp	IconDirEntry.ieHeight,ICON_HEIGHT	;test icon height
	jnz	LoadIcon2
	cmp	IconDirEntry.ieColorCount,ICON_COLOR_COUNT ;test color count
	jnz	LoadIcon2
	mov	ax,word ptr IconDirEntry.ieBytesInRes	;test resource size
	mov	dx,word ptr IconDirEntry.ieBytesInRes+2
	sub	ax,rsIcon_
	sbb	dx,0
	or	ax,dx
	jnz	LoadIcon2
	mov	ax,word ptr IconDirEntry.ieImageOffset	;set pointer to image
	mov	dx,word ptr IconDirEntry.ieImageOffset+2
	call	SetInputPointer
	jb	LoadIcon2
	mov	di,rsIcon			;load icon image
	mov	cx,rsIcon_
	call	ReadInputBlock
	jnb	LoadIcon3			;ok
LoadIcon2:
	stc					;error
LoadIcon3:
	pushf
	call	CloseInput			;close icon file
	popf
LoadIcon4:
	ret
;
;==============================================================================
;
;	<	si  -  message (0 if no message)
;		al  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
TestFileType:
	call	ReadInputByte			;read record type
	jb	TestFileType4
TestFileType1:
	cmp	al,THEADR			;translator header?
	jz	TestFileType2
	cmp	al,LHEADR			;library module header?
	jnz	TestFileType3
TestFileType2:
	call	ReadInputWord			;read record length
	jb	TestFileType4
	push	ax
	call	ReadInputByte			;read name string length
	mov	dl,al
	mov	dh,0
	pop	ax
	jb	TestFileType4
	add	dx,1+1				;length byte + checksum byte
	cmp	dx,ax				;matching record length?
	jnz	TestFileType3
	mov	ax,0
	mov	dx,0
	call	SetInputPointer			;rewind file
	jb	TestFileType4
	mov	si,offset sNormalEnd		;ok
	mov	al,RET_NORMAL_END
	clc
	jmp	TestFileType5
TestFileType3:
	mov	si,offset sNoOmfFile		;not an omf file
	mov	al,RET_NO_OMF_FILE
	stc
	jmp	TestFileType5
TestFileType4:
	mov	si,offset sFileIoError		;file i/o error
	mov	al,RET_FILE_IO_ERROR
	stc
TestFileType5:
	ret
;
;==============================================================================
;
;	<	si  -  message (0 if no message)
;		al  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
ProcessRecords:
	push	es
	mov	es,wRecordBuffer		;address record buffer
	mov	bInsertLine,1
	call	ResetModuleData			;reset module data
ProcessRecords1:
	call	GetInputPointer			;get record offset
	mov	word ptr dRecordOffset,ax
	mov	word ptr dRecordOffset+2,dx
	call	ReadInputByte			;read next record type
	mov	bRecordType,al
	mov	si,offset sEndOfFile		;unexpected end of file
	mov	al,RET_END_OF_FILE
	jb	ProcessRecords10
	call	ReadInputWord			;read record length
	mov	wRecordLength,ax
	mov	si,offset sEndOfFile		;unexpected end of file
	mov	al,RET_END_OF_FILE
	jb	ProcessRecords10
	call	ReadInputRecord			;read record data
	mov	bRecordCheck,al
	mov	si,offset sEndOfFile		;unexpected end of file
	mov	al,RET_END_OF_FILE
	jb	ProcessRecords10
	mov	al,bRecordType			;identify record type
	mov	bx,RecordTypes
ProcessRecords2:
	mov	dl,[bx]				;load record type
	inc	bx
	mov	dh,[bx]				;load 32-bit flag
	inc	bx
	mov	si,bx				;save short name address
ProcessRecords3:
	inc	bx				;skip short name
	cmp	byte ptr [bx-1],0
	jnz	ProcessRecords3
	mov	di,bx				;save description address
ProcessRecords4:
	inc	bx				;skip description
	cmp	byte ptr [bx-1],0
	jnz	ProcessRecords4
	add	bx,2				;skip record handler
	mov	cx,offset sNull
	cmp	dl,0				;end of table?
	jz	ProcessRecords5
	sub	dl,al				;entry found?
	jz	ProcessRecords5
	add	dl,dh				;32-bit variant?
	jnz	ProcessRecords2
	mov	cx,offset s32Bit		;select 32-bit comment
ProcessRecords5:
	push	[bx-2]				;save record handler
	push	di
	push	cx
	push	si
	mov	al,bRecordSpacing
	or	bInsertLine,al
	mov	si,offset sRecordCaption	;begin record caption
	call	OutputString
	push	si
	mov	ax,word ptr dRecordOffset	;insert record offset
	mov	dx,word ptr dRecordOffset+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;continue record caption
	push	si
	mov	al,bRecordType			;insert record type
	call	DumpHexByte
	pop	si
	call	OutputString			;continue record caption
	pop	dx
	push	si
	mov	si,dx				;insert short name
	call	OutputString
	pop	si
	call	OutputString			;continue record caption
	pop	cx
	push	si
	mov	si,cx				;insert 32-bit comment if any
	call	OutputString
	pop	si
	pop	dx
	push	si
	mov	si,dx				;insert description
	call	OutputString
	mov	al,bRecordType			;no checksum in library records
	cmp	al,LibHdr
	jz	ProcessRecords6
	cmp	al,LibEnd
	jz	ProcessRecords6
	cmp	bRecordCheck,0			;checksum ok?
	jz	ProcessRecords6
	mov	si,offset sChecksumError	;insert error message
	call	OutputString
ProcessRecords6:
	pop	si
	pop	cx
	push	cx
	push	si
	mov	si,offset sRecordIgnored	;ignore record?
	jcxz	ProcessRecords7
	inc	cx				;accept record?
	jnz	ProcessRecords8
	mov	si,offset sRecordNotSupported	;record type not supported
ProcessRecords7:
	call	OutputString			;display message
ProcessRecords8:
	pop	si
	call	OutputString			;end record caption
	pop	cx
	not	cx				;record not supported?
	stc
	jcxz	ProcessRecords9
	not	cx				;record handler available?
	clc
	jcxz	ProcessRecords9
	call	cx				;call record handler
ProcessRecords9:
	mov	si,offset sInvalidData		;invalid data
	mov	al,RET_INVALID_DATA
	jb	ProcessRecords10
	mov	al,bRecordType			;module end?
	and	al,11111110b
	cmp	al,MODEND
	jnz	ProcessRecords1			;next record
	mov	si,0				;ok
	mov	al,RET_NORMAL_END
	clc
ProcessRecords10:
	mov	bInsertLine,0
	pop	es
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
ResetModuleData:
	mov	LNAMES_Index.liNext,0			;clear name index
	mov	PUBDEF_Index.piNext,0			;clear public index
	mov	EXTDEF_Index.eiNext,0			;clear external index
	mov	MODDEF_Index.miNext,0			;clear module index
	mov	MainSegment.sdNumber,0			;clear segment number
	mov	SymbolTable.stNext,SymbolTable+stData	;clear symbol table
	mov	SymbolTable.stCount,SYMBOL_TABLE_-stData
	mov	wWin32Index,0				;clear win32 sym table
	mov	wWin32Names,0
	mov	wFixupBaseReloc,0			;clear base reloc table
	mov	wFixupExternal,0			;clear external table
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
MemoryStatistics:
	cmp	bMemoryStatistics,0		;memory statistics enabled?
	jz	MemoryStatistics1
	mov	si,offset sMemoryStatistics	;begin memory statistics
	call	OutputString
	push	si
	mov	ax,wWin32Index			;evaluate win32 symbol table
	mov	dx,0
	cmp	ax,1
	adc	dx,0
	sub	ax,wWin32Names
	sbb	dx,0
	shr	dx,1
	rcr	ax,1
	neg	ax
	mov	bx,8000h
	add	ax,bx
	call	DisplayPercent
	pop	si
	call	OutputString
	push	si
	mov	ax,SymbolTable.stCount		;evaluate internal symbol table
	neg	ax
	mov	bx,SYMBOL_TABLE_-stData
	add	ax,bx
	call	DisplayPercent
	pop	si
	call	OutputString
	push	si
	mov	ax,LNAMES_Index.liNext		;evaluate name index
	mov	bx,LI_DATA_
	call	DisplayPercent
	pop	si
	call	OutputString
	push	si
	mov	ax,EXTDEF_Index.eiNext		;evaluate external index
	mov	bx,EI_DATA_
	call	DisplayPercent
	pop	si
	call	OutputString
	push	si
	mov	ax,PUBDEF_Index.piNext		;evaluate public index
	mov	bx,PI_DATA_
	call	DisplayPercent
	pop	si
	call	OutputString
	push	si
	mov	ax,MODDEF_Index.miNext		;evaluate module index
	mov	bx,MI_DATA_
	call	DisplayPercent
	pop	si
	call	OutputString
	push	si
	mov	ax,wFixupExternal		;evaluate fixup table
	mov	dx,0
	cmp	ax,1
	adc	dx,0
	sub	ax,wFixupBaseReloc
	sbb	dx,0
	shr	dx,1
	rcr	ax,1
	neg	ax
	mov	bx,8000h
	add	ax,bx
	call	DisplayPercent
	pop	si
	call	OutputString			;end memory statistics
MemoryStatistics1:
	ret
;
;==============================================================================
;
;	OMF RECORD MANAGEMENT
;
;==============================================================================
;
;	>	si  -  record offset
;		di  -  buffer
;		cx  -  buffer size
;
;	<	si  -  next record offset
;		di  -  next buffer address
;		cx  -  remaining buffer size
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordString:
	mov	bx,wRecordLength		;record offset ok?
	sub	bx,si
	jb	GetRecordString3
	sub	bx,1+1				;end of record?
	jb	GetRecordString3
	mov	dl,es:[si]			;load string length
	mov	dh,0
	cmp	bx,dx				;string length ok?
	jb	GetRecordString3
	inc	si				;load source pointer
	mov	bx,si
	add	si,dx				;compute next record offset
	dec	cx				;reserve terminator space
	jz	GetRecordString2
GetRecordString1:
	cmp	bx,si				;end of string?
	jnb	GetRecordString2
	mov	al,es:[bx]			;copy character
	inc	bx
	mov	[di],al
	inc	di
	loop	GetRecordString1		;next character
GetRecordString2:
	inc	cx				;release terminator space
	clc					;ok
GetRecordString3:
	mov	byte ptr [di],0			;terminate string
	inc	di				;next buffer address
	dec	cx				;remaining length
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;		dx  -  number of bytes
;		di  -  buffer
;		cx  -  buffer size
;
;	<	si  -  next record offset
;		di  -  next buffer address
;		cx  -  remaining buffer size
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordData:
	mov	bx,wRecordLength		;record offset ok?
	sub	bx,si
	jb	GetRecordData3
	sub	bx,1				;end of record?
	jb	GetRecordData3
	cmp	bx,dx				;data block length ok?
	jb	GetRecordData3
	mov	bx,si
	add	si,dx				;compute next record offset
	jcxz	GetRecordData2			;end of buffer
GetRecordData1:
	cmp	bx,si				;end of data block?
	jnb	GetRecordData2
	mov	al,es:[bx]			;copy data byte
	inc	bx
	mov	[di],al
	inc	di
	loop	GetRecordData1			;next data byte
GetRecordData2:
	clc					;ok
GetRecordData3:
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;
;	<	si  -  next record offset
;		ax  -  index
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordIndex:
	mov	ax,0				;load dummy index
	mov	cx,wRecordLength		;record offset ok?
	sub	cx,si
	jb	GetRecordIndex2
	sub	cx,1+1				;end of record?
	jb	GetRecordIndex2
	mov	dl,es:[si]			;load index byte
	mov	dh,0
	rol	dl,1				;1-byte index?
	shr	dl,1
	jnb	GetRecordIndex1			;ok
	jcxz	GetRecordIndex2			;low byte missing (c)
	inc	si
	mov	dh,dl				;2-byte index
	mov	dl,es:[si]
	clc					;ok
GetRecordIndex1:
	inc	si
	mov	ax,dx				;load index
GetRecordIndex2:
	ret
;
;==============================================================================
;
;	>	   si  -  record offset
;
;	<	   si  -  next record offset
;		dx:ax  -  displacement
;		    c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordDisplacement:
	test	bRecordType,00000001b		;32-bit segment?
	jnz	GetRecordDisplacement1
	jmp	GetRecordWord			;get 16-bit displacement
GetRecordDisplacement1:
	jmp	GetRecordDouble			;get 32-bit displacement
;
;==============================================================================
;
;	>	   si  -  record offset
;
;	<	   si  -  next record offset
;		dx:ax  -  data dword
;		    c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordDouble:
	mov	ax,0				;load dummy data
	mov	dx,0
	mov	cx,wRecordLength		;record offset ok?
	sub	cx,si
	jb	GetRecordDouble1
	sub	cx,4+1				;end of record?
	jb	GetRecordDouble1
	mov	ax,es:[si]			;load data dword
	mov	dx,es:[si+2]
	add	si,4
	clc					;ok
GetRecordDouble1:
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;
;	<	si  -  next record offset
;		ax  -  data word
;		dx  -  0
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordWord:
	mov	ax,0				;load dummy data
	mov	dx,0
	mov	cx,wRecordLength		;record offset ok?
	sub	cx,si
	jb	GetRecordWord1
	sub	cx,2+1				;end of record?
	jb	GetRecordWord1
	mov	ax,es:[si]			;load data word
	add	si,2
	clc					;ok
GetRecordWord1:
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;
;	<	si  -  next record offset
;		al  -  data byte
;		ah  -  0
;		dx  -  0
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordByte:
	mov	ax,0				;load dummy data
	mov	dx,0
	mov	cx,wRecordLength		;record offset ok?
	sub	cx,si
	jb	GetRecordByte1
	sub	cx,1+1				;end of record?
	jb	GetRecordByte1
	mov	al,es:[si]			;load data byte
	inc	si
	clc					;ok
GetRecordByte1:
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;
;	<	si  -  next record offset
;		cx  -  symbol index
;		dx  -  symbol pointer
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
GetRecordSymbol:
	call	GetRecordIndex			;get symbol index
	mov	cx,ax
	mov	dx,offset sNull
	jb	GetRecordSymbol1
	sub	ax,1				;index specified?
	cmc
	jnb	GetRecordSymbol1
	cmp	ax,LNAMES_Index.liNext		;index defined?
	cmc
	jb	GetRecordSymbol1
	mov	dx,LNAMES_			;get symbol pointer
	mul	dx
	mov	bx,ax
	mov	dx,[LNAMES_Index.liData.lnSymbol+bx]
GetRecordSymbol1:
	ret
;
;==============================================================================
;
;	>	bx  -  text table
;		al  -  bit array
;		ah  -  bit mask
;
;	<	si  -  text
;
;------------------------------------------------------------------------------
;
SelectBitText:
	mov	cl,0				;clear selection count
	mov	ch,8				;load bit count
SelectBitText1:
	shl	ax,1				;evaluate next bit
	jnb	SelectBitText2
	ror	ah,1				;copy selection bit
	rol	ah,1
	rcl	cl,1
SelectBitText2:
	dec	ch				;next bit
	jnz	SelectBitText1
SelectBitText3:
	sub	cl,1				;text found?
	jb	SelectBitText5
SelectBitText4:
	inc	bx				;skip text
	cmp	byte ptr [bx-1],0
	jnz	SelectBitText4
	jmp	SelectBitText3			;try again
SelectBitText5:
	mov	si,bx
	ret
;
;==============================================================================
;
;	>	   si  -  record offset
;
;	<	   si  -  next record offset
;		dx:ax  -  number of bytes
;		    c  -  set if error
;
;------------------------------------------------------------------------------
;
CountIteratedData:
	mov	cx,0				;clear destination
	mov	bx,0
CountIteratedData1:
	test	bRecordType,00000001b		;32-bit segment?
	mov	dx,GetRecordWord
	jz	CountIteratedData2
	mov	dx,GetRecordDouble
CountIteratedData2:
	push	bx
	push	cx
	call	dx				;get repeat count
	pop	cx
	pop	bx
	cmc					;end of record
	jnb	CountIteratedData3
	push	bx
	push	cx
	push	dx
	push	ax
	call	CountDataBlockBytes		;get number of bytes in block
	sbb	di,di				;ok?
	mov	cx,ax
	mov	bx,dx
	pop	ax
	pop	dx
	push	si
	push	di
	call	Multiply			;apply repeat count
	pop	di
	sbb	di,0				;ok?
	add	di,-1
	pop	si
	pop	cx
	pop	bx
	jb	CountIteratedData3		;overflow
	add	cx,ax				;accumulate number of bytes
	adc	bx,dx
	jnb	CountIteratedData1		;next data block
CountIteratedData3:
	mov	ax,cx				;load number of bytes
	mov	dx,bx
	ret
;
;==============================================================================
;
;	>	   si  -  record offset
;
;	<	   si  -  next record offset
;		dx:ax  -  number of bytes
;		    c  -  set if error
;
;------------------------------------------------------------------------------
;
CountDataBlockBytes:
	sub	wDataRecursion,1		;count recursions
	jb	CountDataBlockBytes5		;error
	call	GetRecordWord			;get data block count
	mov	di,ax
	jb	CountDataBlockBytes5		;error
	cmp	di,0				;immediate data?
	jz	CountDataBlockBytes3
	mov	cx,0				;clear destination
	mov	bx,0
CountDataBlockBytes1:
	test	bRecordType,00000001b		;32-bit segment?
	mov	dx,GetRecordWord
	jz	CountDataBlockBytes2
	mov	dx,GetRecordDouble
CountDataBlockBytes2:
	push	di
	push	bx
	push	cx
	call	dx				;get repeat count
	pop	cx
	pop	bx
	pop	di
	jb	CountDataBlockBytes5		;error
	push	di
	push	bx
	push	cx
	push	dx
	push	ax
	call	CountDataBlockBytes		;get number of bytes in block
	sbb	di,di				;ok?
	mov	cx,ax
	mov	bx,dx
	pop	ax
	pop	dx
	push	si
	push	di
	call	Multiply			;apply repeat count
	pop	di
	sbb	di,0				;ok?
	add	di,-1
	pop	si
	pop	cx
	pop	bx
	pop	di
	jb	CountDataBlockBytes5		;overflow
	add	cx,ax				;accumulate number of bytes
	adc	bx,dx
	jb	CountDataBlockBytes5		;overflow
	dec	di				;count data blocks
	jnz	CountDataBlockBytes1
	mov	ax,cx				;load number of bytes
	mov	dx,bx
	jmp	CountDataBlockBytes4		;ok
CountDataBlockBytes3:
	call	GetRecordByte			;get data byte count
	jb	CountDataBlockBytes5		;error
	mov	cx,wRecordLength		;compute bytes in record
	sub	cx,si
	dec	cx				;data complete?
	cmp	cx,ax
	jb	CountDataBlockBytes5		;error
	add	si,ax				;skip data
CountDataBlockBytes4:
	clc					;ok
CountDataBlockBytes5:
	inc	wDataRecursion			;recursion done
	ret
;
;==============================================================================
;
;	RECORD HANDLERS
;
;==============================================================================
;
LHEADR_Handler:
THEADR_Handler:
	mov	si,0				;load first record offset
	mov	di,SourceFile			;get source file name
	mov	cx,SourceFile_
	call	GetRecordString
	jb	THEADR_Handler2
	cmp	bDumpSource,0			;source file name dump enabled?
	jz	THEADR_Handler1
	mov	bx,offset sDumpSourceFileName	;dump source file name
	mov	si,SourceFile
	call	OutputQuotedMessage
THEADR_Handler1:
	mov	bDataType,DATA_INIT		;reset data type
	call	SkipFileHeaders			;skip pe file headers
	jnb	THEADR_Handler2
	mov	si,offset sWriteError		;display error message
	call	OutputString
	stc					;error
THEADR_Handler2:
	ret
;
;==============================================================================
;
LLNAMES_Handler:
LNAMES_Handler:
	mov	si,0				;load first record offset
LNAMES_Handler1:
	cmp	LNAMES_Index.liNext,LI_DATA_	;end of name index?
	cmc
	jb	LNAMES_Handler2
	mov	di,SymbolTable.stNext		;read next name
	mov	cx,SymbolTable.stCount
	call	GetRecordString
	cmc					;no more names
	jnb	LNAMES_Handler2
	cmp	cx,1				;end of symbol table?
	jb	LNAMES_Handler2
	xchg	SymbolTable.stNext,di		;save symbol control data
	mov	SymbolTable.stCount,cx
	mov	bx,LNAMES_Index.liNext		;add name
	mov	[LNAMES_Index.liData.lnSymbol+bx],di
	add	LNAMES_Index.liNext,LNAMES_	;next name
	jmp	LNAMES_Handler1
LNAMES_Handler2:
	ret
;
;==============================================================================
;
SEGDEF_Handler:
	cmp	MainSegment.sdNumber,0		;only one segment allowed
	mov	si,offset sTooManySegments
	stc
	jnz	SEGDEF_Handler8
	mov	si,0				;load first record offset
	call	GetRecordByte			;get segment attributes
	jb	SEGDEF_Handler9
	mov	MainSegment.sdAttributes,al
	and 	al,SEG_ALIGNMENT		;absolute segment?
	cmp	al,SEG_AT
	mov	ax,0
	mov	dx,0
	jnz	SEGDEF_Handler1
	call	GetRecordWord			;get absolute frame
	mov	dx,ax
	jb	SEGDEF_Handler9
	push	dx
	call	GetRecordByte			;get absolute offset
	pop	dx
	jb	SEGDEF_Handler9
SEGDEF_Handler1:
	mov	MainSegment.sdFrame,dx		;save absolute address
	mov	MainSegment.sdOffset,ax
	call	GetRecordDisplacement		;get segment length
	jb	SEGDEF_Handler9
	mov	cl,bRecordType			;use big bit if 16-bit segment
	shr	cl,1
	sbb	cl,cl
	not	cl
	and	cl,MainSegment.sdAttributes
	and	cl,SEG_BIG
	add	cl,-1
	adc	dx,0
	mov	word ptr MainSegment.sdLength,ax
	mov	word ptr MainSegment.sdLength+2,dx
	call	GetRecordSymbol			;get segment number and name
	jb	SEGDEF_Handler9
	cmp	cx,1				;segment number ok?
	jb	SEGDEF_Handler9
	mov	MainSegment.sdNumber,1
	mov	MainSegment.sdSymbol,dx
	call	GetRecordSymbol			;get segment class
	jb	SEGDEF_Handler9
	mov	MainSegment.sdClass,dx
	mov	si,dx				;parse segment class string
	call	StringToNumber			;use linker defaults?
	or	ax,dx
	mov	bx,offset sNull
	jz	SEGDEF_Handler3
	call	StringToNumber			;set class style
	push	si
	mov	bx,ClassStyleTable
	call	SetClassStyle
	pop	si
	mov	bx,si
SEGDEF_Handler2:
	mov	si,bx				;set symbol file extension
	call	StringToNumber
	mov	bx,si
	mov	word ptr dSymbolExtension,ax
	mov	word ptr dSymbolExtension+2,dx
SEGDEF_Handler3:
	push	bx
	call	LoadWin32Symbols		;load win32 symbols
	pop	bx
	mov	si,offset sSymbolsNotLoaded
	jb	SEGDEF_Handler8
	cmp	byte ptr [bx],0			;more symbol files?
	jnz	SEGDEF_Handler2
	call	SortWin32Symbols		;sort win32 symbols
	cmp	bDumpWin32Symbols,0		;win32 symbol dump enabled?
	jz	SEGDEF_Handler4
	call	DumpWin32Symbols		;dump win32 symbols
SEGDEF_Handler4:
	call	CreateOutputFile		;create output file
	mov	si,offset sOutputFileNotCreated
	jb	SEGDEF_Handler8
	cmp	bDumpSegment,0			;segment dump enabled?
	jz	SEGDEF_Handler7
	mov	si,offset sDumpSegment		;start segment dump
	call	OutputString
	push	si
	mov	si,MainSegment.sdSymbol		;display segment name
	call	OutputString
	pop	si
	call	OutputString
	push	si
	mov	bx,SegAlignment			;display segment alignment
	mov	al,MainSegment.sdAttributes
	mov	ah,SEG_ALIGNMENT
	call	SelectBitText
	call	OutputString
	mov	al,MainSegment.sdAttributes	;absolute segment?
	and 	al,SEG_ALIGNMENT
	cmp	al,SEG_AT
	jnz	SEGDEF_Handler5
	mov	ax,MainSegment.sdFrame		;display absolute address
	call	DumpHexWord
	mov	al,':'
	call	OutputChar
	mov	ax,MainSegment.sdOffset
	call	DumpHexWord
SEGDEF_Handler5:
	mov	bx,SegCombination		;display segment combination
	mov	al,MainSegment.sdAttributes
	mov	ah,SEG_COMBINATION
	call	SelectBitText
	call	OutputString
	mov	bx,SegUse			;display segment use
	mov	al,MainSegment.sdAttributes
	mov	ah,SEG_USE
	call	SelectBitText
	call	OutputString
	mov	si,MainSegment.sdClass		;segment class specified?
	cmp	byte ptr [si],0
	jz	SEGDEF_Handler6
	mov	al,' '				;display segment class
	call	OutputChar
	mov	al,''''
	call	OutputChar
	mov	si,MainSegment.sdClass
	call	OutputString
	mov	al,''''
	call	OutputChar
SEGDEF_Handler6:
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr MainSegment.sdLength ;display segment length
	mov	dx,word ptr MainSegment.sdLength+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;end segment dump
SEGDEF_Handler7:
	mov	al,bRecordType
	shr	al,1
	sbb	al,al
	not	al
	and	al,SEG_BIG
	not	al
	and	al,MainSegment.sdAttributes	;test segment attributes
	cmp	al,SEG_BYTE+SEG_PRIVATE+SEG_USE32
	clc					;ok
	jz	SEGDEF_Handler9
	mov	si,offset sInvalidSegment	;display error message
SEGDEF_Handler8:
	call	OutputString
	stc					;error
SEGDEF_Handler9:
	ret
;
;==============================================================================
;
LEXTDEF_Handler:
EXTDEF_Handler:
	mov	si,0				;load first record offset
EXTDEF_Handler1:
	mov	di,SymbolTable.stNext		;read next name
	mov	cx,SymbolTable.stCount
	call	GetRecordString
	cmc					;no more names
	jnb	EXTDEF_Handler7
	cmp	cx,1				;end of symbol table?
	jb	EXTDEF_Handler7
	push	di
	push	cx
	call	GetRecordIndex			;get type index
	pop	cx
	pop	di
	jb	EXTDEF_Handler7
	cmp	EXTDEF_Index.eiNext,EI_DATA_	;end of external index?
	cmc
	jb	EXTDEF_Handler7
	xchg	SymbolTable.stNext,di		;save symbol control data
	mov	SymbolTable.stCount,cx
	push	si
	push	di
	mov	si,di				;find win32 symbol
	call	FindWin32Symbol
	mov	cx,si
	pop	di
	pop	si
	jb	EXTDEF_Handler6
	mov	bx,0				;scan module index
EXTDEF_Handler2:
	cmp	bx,MODDEF_Index.miNext		;end of module data?
	jnb	EXTDEF_Handler3
	cmp	dx,[MODDEF_Index.miData.mdModule+bx] ;module already known?
	jz	EXTDEF_Handler4
	add	bx,MODDEF_			;next module entry
	jmp	EXTDEF_Handler2
EXTDEF_Handler3:
	cmp	bx,MI_DATA_			;end of module index?
	cmc
	jb	EXTDEF_Handler7
	mov	[MODDEF_Index.miData.mdModule+bx],dx ;save module name
	mov	[MODDEF_Index.miData.mdCount+bx],0   ;reset reference count
	add	MODDEF_Index.miNext,MODDEF_
EXTDEF_Handler4:
	inc	[MODDEF_Index.miData.mdCount+bx];count references
	mov	dx,bx				;save module pointer
	mov	bx,EXTDEF_Index.eiNext		;add external
	mov	[EXTDEF_Index.eiData.edModule+bx],dx
	mov	[EXTDEF_Index.eiData.edUserSymbol+bx],di
	mov	[EXTDEF_Index.eiData.edSystemSymbol+bx],cx
	mov	[EXTDEF_Index.eiData.edOrdinal+bx],ax
	mov	word ptr [EXTDEF_Index.eiData.edAddress+bx],0
	mov	word ptr [EXTDEF_Index.eiData.edAddress+2+bx],0
	push	si
	push	bx				;save system symbol length
	mov	si,[EXTDEF_Index.eiData.edSystemSymbol+bx]
	call	GetWin32StringLength
	pop	bx
	mov	[EXTDEF_Index.eiData.edLength+bx],cx
	mov	bx,[EXTDEF_Index.eiData.edModule+bx] ;save module name length
	push	bx
	mov	si,[MODDEF_Index.miData.mdModule+bx]
	call	GetWin32StringLength
	pop	bx
	mov	[MODDEF_Index.miData.mdLength+bx],cx
	cmp	bDumpExternal,0		;external dump enabled?
	jz	EXTDEF_Handler5
	mov	si,offset sDumpExternal		;start external dump
	call	OutputString
	push	si
	mov	bx,EXTDEF_Index.eiNext		;insert ordinal number
	mov	ax,[EXTDEF_Index.eiData.edOrdinal+bx]
	call	DumpHexWord
	pop	si
	call	OutputString
	push	si
	mov	bx,EXTDEF_Index.eiNext		;insert system symbol
	mov	si,[EXTDEF_Index.eiData.edSystemSymbol+bx]
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	CopyWin32String
	mov	si,StringBuffer
	call	OutputQuotedString
	pop	si
	call	OutputString
	push	si
	mov	bx,EXTDEF_Index.eiNext		;insert module name
	mov	bx,[EXTDEF_Index.eiData.edModule+bx]
	mov	si,[MODDEF_Index.miData.mdModule+bx]
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	CopyWin32String
	mov	si,StringBuffer
	call	OutputString
	pop	si
	call	OutputString			;end external dump
EXTDEF_Handler5:
	pop	si
	add	EXTDEF_Index.eiNext,EXTDEF_	;next entry
	jmp	EXTDEF_Handler1			;next name
EXTDEF_Handler6:
	mov	bx,offset sInvalidExternal	;display error message
	mov	si,di
	call	OutputQuotedMessage
	stc					;error
EXTDEF_Handler7:
	ret
;
;==============================================================================
;
LPUBDEF_Handler:
PUBDEF_Handler:
	mov	si,0				;load first record offset
	call	GetRecordIndex			;get base group index
	jb	PUBDEF_Handler3
	add	ax,-1				;test base group index
	jb	PUBDEF_Handler3
	call	GetRecordIndex			;get base segment index
	jb	PUBDEF_Handler3
	cmp	ax,MainSegment.sdNumber		;base segment index ok?
	stc
	jnz	PUBDEF_Handler3
PUBDEF_Handler1:
	mov	di,SymbolTable.stNext		;read next name
	mov	cx,SymbolTable.stCount
	call	GetRecordString
	cmc					;no more names
	jnb	PUBDEF_Handler3
	cmp	cx,1				;end of symbol table?
	jb	PUBDEF_Handler3
	push	di
	push	cx
	call	GetRecordDisplacement		;get public offset
	pop	cx
	pop	di
	jb	PUBDEF_Handler3
	push	dx
	push	ax
	push	di
	push	cx
	call	GetRecordIndex			;get type index
	pop	cx
	pop	di
	pop	ax
	pop	dx
	jb	PUBDEF_Handler3
	cmp	PUBDEF_Index.piNext,PI_DATA_	;end of public index?
	cmc
	jb	PUBDEF_Handler3
	xchg	SymbolTable.stNext,di		;save symbol control data
	mov	SymbolTable.stCount,cx
	mov	bx,PUBDEF_Index.piNext		;add public
	mov	[PUBDEF_Index.piData.pdSymbol+bx],di
	mov	word ptr [PUBDEF_Index.piData.pdAddress+bx],ax
	mov	word ptr [PUBDEF_Index.piData.pdAddress+2+bx],dx
	cmp	bDumpPublic,0			;public dump enabled?
	jz	PUBDEF_Handler2
	push	si
	mov	si,offset sDumpPublic		;start public dump
	call	OutputString
	push	si
	mov	bx,PUBDEF_Index.piNext		;insert public offset
	mov	ax,word ptr [PUBDEF_Index.piData.pdAddress+bx]
	mov	dx,word ptr [PUBDEF_Index.piData.pdAddress+2+bx]
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	bx,PUBDEF_Index.piNext		;insert public offset
	mov	si,[PUBDEF_Index.piData.pdSymbol+bx]
	call	OutputQuotedString
	pop	si
	call	OutputString			;end public dump
	pop	si
PUBDEF_Handler2:
	add	PUBDEF_Index.piNext,PUBDEF_	;next entry
	jmp	PUBDEF_Handler1
PUBDEF_Handler3:
	ret
;
;==============================================================================
;
LEDATA_Handler:
	call	WriteSectionData		;write previous data block
	jb	LEDATA_Handler2
	mov	si,0				;load first record offset
	call	GetRecordIndex			;get segment index
	jb	LEDATA_Handler3
	cmp	ax,MainSegment.sdNumber		;segment index ok?
	stc
	jnz	LEDATA_Handler3
	call	GetRecordDisplacement		;get data offset
	jb	LEDATA_Handler3
	mov	word ptr dDataOffset,ax
	mov	word ptr dDataOffset+2,dx
	mov	ax,wRecordLength		;compute data length
	stc
	sbb	ax,si
	jb	LEDATA_Handler3
	mov	wDataLength,ax
	cmp	bDumpData,0			;data dump enabled?
	jz	LEDATA_Handler1
	push	si
	mov	si,offset sDumpData		;begin data dump
	call	OutputString
	push	si
	mov	si,MainSegment.sdSymbol
	call	OutputQuotedString
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr dDataOffset		;insert data offset
	mov	dx,word ptr dDataOffset+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,wDataLength			;insert data length
	mov	dx,0
	call	DumpHexDouble
	pop	si
	call	OutputString			;end data dump
	pop	si
LEDATA_Handler1:
	mov	dx,wDataLength			;copy data block
	mov	di,DataBuffer
	mov	cx,DataBuffer_
	cmp	cx,dx
	jb	LEDATA_Handler3
	call	GetRecordData
	jb	LEDATA_Handler3
	cmp	bDataType,DATA_INIT		;data initialization?
	mov	bDataType,DATA_LEDATA		;set data type
	clc					;ok
	jnz	LEDATA_Handler3
	mov	ax,word ptr dDataOffset		;offset = 0?
	or	ax,word ptr dDataOffset+2
	add	ax,-1
	jb	LEDATA_Handler3
	cmp	wDataLength,2*SECTION_DATA_	;section ctrl blocks complete?
	jb	LEDATA_Handler3
	mov	si,DataBuffer			;copy text section ctrl block
	mov	di,TextSection
	mov	cx,SECTION_DATA_
	call	CopyStructure
	mov	di,DataSection			;copy data section ctrl block
	mov	cx,SECTION_DATA_
	call	CopyStructure
	call	InitSectionData			;initialize section data
	call	DumpSectionData			;dump section data
	clc					;ok
	jmp	LEDATA_Handler3
LEDATA_Handler2:
	mov	si,offset sWriteError		;display error message
	call	OutputString
	stc					;error
LEDATA_Handler3:
	ret
;
;==============================================================================
;
LIDATA_Handler:
	cmp	bDataType,DATA_INIT		;data initialization?
	stc
	jz	LIDATA_Handler4
	call	WriteSectionData		;write previous data block
	jb	LIDATA_Handler3
	mov	si,0				;load first record offset
	call	GetRecordIndex			;get segment index
	jb	LIDATA_Handler4
	cmp	ax,MainSegment.sdNumber		;segment index ok?
	stc
	jnz	LIDATA_Handler4
	call	GetRecordDisplacement		;get data offset
	jb	LIDATA_Handler4
	mov	word ptr dDataOffset,ax
	mov	word ptr dDataOffset+2,dx
	mov	ax,wRecordLength		;compute data length
	stc
	sbb	ax,si
	jb	LIDATA_Handler4
	mov	wDataLength,ax
	push	si
	call	CountIteratedData		;get number of bytes
	pop	si
	jb	LIDATA_Handler4
	mov	word ptr dDataLengthX,ax	;save expanded data length
	mov	word ptr dDataLengthX+2,dx
	cmp	bDumpData,0			;data dump enabled?
	jz	LIDATA_Handler1
	push	si
	mov	si,offset sDumpData		;begin data dump
	call	OutputString
	push	si
	mov	si,MainSegment.sdSymbol
	call	OutputQuotedString
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr dDataOffset		;insert data offset
	mov	dx,word ptr dDataOffset+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr dDataLengthX	;insert expanded data length
	mov	dx,word ptr dDataLengthX+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;end data dump
	pop	si
LIDATA_Handler1:
	mov	dx,wDataLength			;copy data block
	mov	di,DataBuffer
	mov	cx,DataBuffer_
	cmp	cx,dx
	jb	LIDATA_Handler4
	call	GetRecordData
	jb	LIDATA_Handler4
	test	bRecordType,00000001b		;16-bit or 32-bit record?
	mov	bDataType,DATA_LIDATA16
	jz	LIDATA_Handler2
	mov	bDataType,DATA_LIDATA32
LIDATA_Handler2:
	clc
	jmp	LIDATA_Handler4
LIDATA_Handler3:
	mov	si,offset sWriteError		;display error message
	call	OutputString
	stc					;error
LIDATA_Handler4:
	ret
;
;==============================================================================
;
FIXUPP_Handler:
	mov	bx,offset sNothingToFix		;prepare error message
	cmp	bDataType,DATA_INIT		;data initialization?
	jz	FIXUPP_Handler9
	cmp	bDataType,DATA_NONE		;no data in buffer?
	jz	FIXUPP_Handler9
	mov	bx,offset sCantFixupLidata	;prepare error message
	cmp	bDataType,DATA_LIDATA16		;logical iterated 16-bit data?
	jz	FIXUPP_Handler9
	cmp	bDataType,DATA_LIDATA32		;logical iterated 32-bit data?
	jz	FIXUPP_Handler9
	mov	si,0				;load first record offset
FIXUPP_Handler1:
	mov	wFixupSubrecord,si		;save subrecord offset
	call	GetRecordByte			;get subrecord header
	cmc					;no more subrecords
	jnb	FIXUPP_Handler11
	mov	ah,FIXUP_SUBRECORD		;accept fixup subrecords only
	mov	bx,FixupSubrecord
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXUP_FIXUP
	jnz	FIXUPP_Handler8
	mov	ah,FIXUP_MODE			;accept seg-relative mode only
	mov	bx,FixupMode
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXUP_SEG_RELATIVE
	jnz	FIXUPP_Handler8
	mov	ah,FIXUP_LOCATION		;accept 32-bit offset locs only
	mov	bx,FixupLocation
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXUP_OFFSET_32
	jnz	FIXUPP_Handler8
	mov	dh,al				;save msb of subrecord header
	push	dx
	call	GetRecordByte			;get lsb of subrecord header
	pop	dx
	mov	dl,al
	jb	FIXUPP_Handler10
	and	dx,FIXUP_OFFSET			;save data record offset
	mov	wFixupOffset,dx
	mov	bx,offset sInvalidFixupOffset	;test data record offset
	mov	cx,wDataLength
	sub	cx,dx
	jb	FIXUPP_Handler9
	cmp	cx,4
	jb	FIXUPP_Handler9
	mov	cx,0				;save data stream offset
	add	dx,word ptr dDataOffset
	adc	cx,word ptr dDataOffset+2
	mov	word ptr dFixupDataOffset,dx
	mov	word ptr dFixupDataOffset+2,cx
	call	GetRecordByte			;get fix data byte
	jb	FIXUPP_Handler10
	mov	ah,FIXDATA_THREADS		;reject thread references
	mov	bx,FixDataThreads
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXDATA_NO_THREADS
	jnz	FIXUPP_Handler8
	mov	ah,FIXDATA_F_METHOD		;test frame method
	mov	bx,FixDataFMethod
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXDATA_F0			;f0 -> read frame segment index
	jz	FIXUPP_Handler2
	cmp	dl,FIXDATA_F4			;f4 -> ok
	jz	FIXUPP_Handler3
	cmp	dl,FIXDATA_F5			;f5 -> ok
	jz	FIXUPP_Handler3
	jmp	FIXUPP_Handler8			;frame method not supported
FIXUPP_Handler2:
	push	ax
	call	GetRecordIndex			;get frame datum
	mov	wFixupFrame,ax
	pop	ax
	jb	FIXUPP_Handler10
FIXUPP_Handler3:
	mov	ah,FIXDATA_T_METHOD		;test target method
	mov	bx,FixDataTMethod
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXDATA_T0			;t0 -> base relocation
	jz	FIXUPP_Handler4
	cmp	dl,FIXDATA_T4			;t4 -> base relocation
	jz	FIXUPP_Handler4
	cmp	dl,FIXDATA_T6			;t6 -> external reference
	jz	FIXUPP_Handler4
	jmp	FIXUPP_Handler8			;target method not supported
FIXUPP_Handler4:
	push	ax
	call	GetRecordIndex			;get target datum
	mov	wFixupTarget,ax
	pop	ax
	jb	FIXUPP_Handler10
	mov	word ptr dFixupDisplacement,0	;set displacement to zero
	mov	word ptr dFixupDisplacement+2,0
	test	al,FIXDATA_NO_DISP		;no explicit displacement?
	jnz	FIXUPP_Handler5
	push	ax
	call	GetRecordDisplacement		;get displacement
	mov	word ptr dFixupDisplacement,ax
	mov	word ptr dFixupDisplacement+2,dx
	pop	ax
	jb	FIXUPP_Handler10
FIXUPP_Handler5:
	mov	dl,al				;test frame method
	and	dl,FIXDATA_F_METHOD
	cmp	dl,FIXDATA_F4			;f4 -> load main segment number
	mov	cx,MainSegment.sdNumber
	jnz	FIXUPP_Handler6
	cmp	dl,FIXDATA_F5			;f5 -> load target datum
	mov	cx,wFixupTarget
	jnz	FIXUPP_Handler6
	mov	cx,wFixupFrame			;else -> load frame datum
FIXUPP_Handler6:
	cmp	cx,MainSegment.sdNumber		;frame = main segment?
	jnz	FIXUPP_Handler10
	mov	wFixupFrame,cx			;save frame datum
	mov	dl,al				;test target method
	and	dl,FIXDATA_T_METHOD
	cmp	dl,FIXDATA_T6			;t6 -> external reference
	jz	FIXUPP_Handler7
	mov	ax,wFixupTarget			;target = main segment?
	cmp	ax,MainSegment.sdNumber
	jnz	FIXUPP_Handler10
	push	si
	call	FixupBaseReloc			;fixup base relocation
	pop	si
	jb	FIXUPP_Handler10
	jmp	FIXUPP_Handler1			;next subrecord
FIXUPP_Handler7:
	push	si
	call	FixupExternal			;fixup external
	pop	si
	jb	FIXUPP_Handler10
	jmp	FIXUPP_Handler1			;next subrecord
FIXUPP_Handler8:
	push	ax
	push	bx
	mov	si,offset sFixupNotSupported	;begin fixup error
	call	OutputString
	push	si
	mov	ax,word ptr dRecordOffset	;insert subrecord offset
	mov	dx,word ptr dRecordOffset+2
	add	ax,1+2
	adc	dx,0
	add	ax,wFixupSubrecord
	adc	dx,0
	call	DumpHexDouble
	pop	si
	call	OutputString			;continue fixup error
	pop	bx
	pop	ax
	push	si
	call	SelectBitText			;insert error type
	call	OutputString
	pop	si
	mov	bx,si				;end fixup error
FIXUPP_Handler9:
	mov	si,bx				;display error message
	call	OutputString
FIXUPP_Handler10:
	stc					;error
FIXUPP_Handler11:
	ret
;
;==============================================================================
;
MODEND_Handler:
	mov	bx,offset sNothingToWrite	;prepare error message
	cmp	bDataType,DATA_INIT		;data initialization?
	jz	MODEND_Handler8
	call	WriteSectionData		;write last data block
	jb	MODEND_Handler7
	mov	cx,FILE_PAGE			;go to next pe file page
	call	NextOutputPage
	jb	MODEND_Handler7
	mov	si,0				;load first record offset
	mov	wFixupSubrecord,si		;save subrecord offset
	call	GetRecordByte			;get module type
	jb	MODEND_Handler9
	mov	ah,MODTYPE_MAIN			;accept main modules only
	mov	bx,ModTypeMain
	mov	dl,al
	and	dl,ah
	cmp	dl,MODTYPE_MAIN_MODULE
	jnz	MODEND_Handler6
	mov	ah,MODTYPE_START		;explicit entry points only
	mov	bx,ModTypeStart
	mov	dl,al
	and	dl,ah
	cmp	dl,MODTYPE_ENTRY_POINT
	jnz	MODEND_Handler6
	mov	ah,MODTYPE_SEGMENT		;segment bit not supported
	mov	bx,ModTypeSegment
	mov	dl,al
	and	dl,ah
	cmp	dl,MODTYPE_SEGMENT_0
	jnz	MODEND_Handler6
	mov	ah,MODTYPE_X			;relocatable entry points only
	mov	bx,ModTypeX
	mov	dl,al
	and	dl,ah
	cmp	dl,MODTYPE_RELOCATABLE
	jnz	MODEND_Handler6
	call	GetRecordByte			;get fix data byte
	jb	MODEND_Handler9
	mov	ah,FIXDATA_THREADS		;reject thread references
	mov	bx,FixDataThreads
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXDATA_NO_THREADS
	jnz	MODEND_Handler6
	mov	ah,FIXDATA_F_METHOD		;test frame method
	mov	bx,FixDataFMethod
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXDATA_F0			;f0 -> read frame segment index
	jz	MODEND_Handler1
	cmp	dl,FIXDATA_F4			;f4 -> ok
	jz	MODEND_Handler2
	cmp	dl,FIXDATA_F5			;f5 -> ok
	jz	MODEND_Handler2
	jmp	MODEND_Handler6			;frame method not supported
MODEND_Handler1:
	push	ax
	call	GetRecordIndex			;get frame datum
	mov	wFixupFrame,ax
	pop	ax
	jb	MODEND_Handler9
MODEND_Handler2:
	mov	ah,FIXDATA_T_METHOD		;test target method
	mov	bx,FixDataTMethod
	mov	dl,al
	and	dl,ah
	cmp	dl,FIXDATA_T0			;t0 -> read target seg index
	jz	MODEND_Handler3
	cmp	dl,FIXDATA_T4			;t4 -> read target seg index
	jz	MODEND_Handler3
	jmp	MODEND_Handler6			;target method not supported
MODEND_Handler3:
	push	ax
	call	GetRecordIndex			;get target datum
	mov	wFixupTarget,ax
	pop	ax
	jb	MODEND_Handler9
	mov	word ptr dFixupDisplacement,0	;set displacement to zero
	mov	word ptr dFixupDisplacement+2,0
	test	al,FIXDATA_NO_DISP		;no explicit displacement?
	jnz	MODEND_Handler4
	push	ax
	call	GetRecordDisplacement		;get displacement
	mov	word ptr dFixupDisplacement,ax
	mov	word ptr dFixupDisplacement+2,dx
	pop	ax
	jb	MODEND_Handler9
MODEND_Handler4:
	mov	dl,al				;test frame method
	and	dl,FIXDATA_F_METHOD
	cmp	dl,FIXDATA_F4			;f4 -> load main segment number
	mov	cx,MainSegment.sdNumber
	jnz	MODEND_Handler5
	cmp	dl,FIXDATA_F5			;f5 -> load target datum
	mov	cx,wFixupTarget
	jnz	MODEND_Handler5
	mov	cx,wFixupFrame			;else -> load frame datum
MODEND_Handler5:
	cmp	cx,MainSegment.sdNumber		;frame = main segment?
	jnz	MODEND_Handler9
	mov	wFixupFrame,cx			;save frame datum
	mov	ax,wFixupTarget			;target = main segment?
	cmp	ax,MainSegment.sdNumber
	jnz	MODEND_Handler9
	call	FixupEntryPoint			;fixup module entry point
	call	SortBaseRelocs			;sort base relocations
	call	SortExternals			;sort externals
	call	SortExportSymbols		;sort export symbols
	call	WriteImports			;write pe file imports
	jb	MODEND_Handler7
	call	WriteExports			;write pe file exports
	jb	MODEND_Handler7
	call	WriteResources			;write pe file resources
	jb	MODEND_Handler7
	call	WriteBaseRelocs			;write pe file base relocations
	jb	MODEND_Handler7
	call	WriteExternals			;write pe file externals
	jb	MODEND_Handler7
	call	WriteFileHeaders		;write pe file headers
	jb	MODEND_Handler7
	clc					;ok
	jmp	MODEND_Handler10
MODEND_Handler6:
	push	ax
	push	bx
	mov	si,offset sFixupNotSupported	;begin fixup error
	call	OutputString
	push	si
	mov	ax,word ptr dRecordOffset	;insert subrecord offset
	mov	dx,word ptr dRecordOffset+2
	add	ax,1+2
	adc	dx,0
	add	ax,wFixupSubrecord
	adc	dx,0
	call	DumpHexDouble
	pop	si
	call	OutputString			;continue fixup error
	pop	bx
	pop	ax
	push	si
	call	SelectBitText			;insert error type
	call	OutputString
	pop	si
	mov	bx,si				;end fixup error
	jmp	MODEND_Handler8
MODEND_Handler7:
	mov	bx,offset sWriteError		;display write error message
MODEND_Handler8:
	mov	si,bx				;display error message
	call	OutputString
MODEND_Handler9:
	stc					;error
MODEND_Handler10:
	ret
;
;==============================================================================
;
;	FIXUP MANAGEMENT
;
;==============================================================================
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
FixupBaseReloc:
	push	es
	mov	es,wFixupBuffer			;use fixup buffer
	mov	ax,word ptr dFixupDataOffset	;get memory destination
	mov	dx,word ptr dFixupDataOffset+2
	call	MapMemoryOffset
	mov	si,offset sFixupBufferOverflow	;prepare error message
	mov	bx,wFixupBaseReloc		;allocate base reloc structure
	add	bx,FIXUP_BASE_RELOC_
	jb	FixupBaseReloc2			;buffer overflow
	mov	cx,wFixupExternal		;buffer overlap?
	mov	di,0
	cmp	cx,1
	adc	di,0
	sub	cx,bx
	sbb	di,0
	jb	FixupBaseReloc2
	xchg	bx,wFixupBaseReloc		;load/save base reloc structure
	mov	word ptr es:[bx.brMemoryOffset],ax ;save fixup pointer
	mov	word ptr es:[bx.brMemoryOffset+2],dx
	mov	bx,wFixupOffset			;apply displacement
	mov	ax,[bx+DataBuffer]
	mov	dx,[bx+DataBuffer+2]
	add	ax,word ptr dFixupDisplacement
	adc	dx,word ptr dFixupDisplacement+2
	call	MapMemoryOffset			;convert to memory offset
	add	ax,word ptr onImageBase		;add preferred load address
	adc	dx,word ptr onImageBase+2
	mov	bx,wFixupOffset			;save fixed address
	mov	[bx+DataBuffer],ax
	mov	[bx+DataBuffer+2],dx
	cmp	bDumpFixupBaseReloc,0		;fixup dump enabled?
	jz	FixupBaseReloc1
	mov	si,offset sDumpFixupBaseReloc	;begin fixup dump
	call	OutputString
	push	si
	mov	ax,word ptr dFixupDataOffset	;insert data stream offset
	mov	dx,word ptr dFixupDataOffset+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;continue fixup dump
	push	si
	mov	bx,wFixupOffset			;insert fixed address
	mov	ax,[bx+DataBuffer]
	mov	dx,[bx+DataBuffer+2]
	call	DumpHexDouble
	pop	si
	call	OutputString			;end fixup dump
FixupBaseReloc1:
	clc					;ok
	jmp	FixupBaseReloc3
FixupBaseReloc2:
	call	OutputString			;display error message
	stc					;error
FixupBaseReloc3:
	pop	es
	ret
;
;==============================================================================
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
FixupExternal:
	push	es
	mov	es,wFixupBuffer			;use fixup buffer
	mov	ax,word ptr dFixupDataOffset	;get memory destination
	mov	dx,word ptr dFixupDataOffset+2
	call	MapMemoryOffset
	mov	si,offset sFixupBufferOverflow	;prepare error message
	mov	bx,wFixupBaseReloc		;allocate base reloc structure
	add	bx,FIXUP_BASE_RELOC_
	jb	FixupExternal2			;buffer overflow
	mov	cx,wFixupExternal		;buffer overlap?
	mov	di,0
	cmp	cx,1
	adc	di,0
	sub	cx,bx
	sbb	di,0
	jb	FixupExternal2
	xchg	bx,wFixupBaseReloc		;load/save base reloc structure
	mov	word ptr es:[bx.brMemoryOffset],ax ;save fixup pointer
	mov	word ptr es:[bx.brMemoryOffset+2],dx
	mov	ax,word ptr dFixupDataOffset	;get file destination
	mov	dx,word ptr dFixupDataOffset+2
	call	MapFileOffset
	mov	si,offset sFixupBufferOverflow	;prepare error message
	mov	bx,wFixupExternal		;allocate external structure
	dec	bx
	sub	bx,FIXUP_EXTERNAL_
	inc	bx
	jb	FixupExternal2			;buffer overflow
	cmp	bx,wFixupBaseReloc
	jb	FixupExternal2
	mov	wFixupExternal,bx		;save external structure
	mov	word ptr es:[bx.exFileOffset],ax;save fixup pointer
	mov	word ptr es:[bx.exFileOffset+2],dx
	mov	si,offset sInvalidExternalRef	;prepare error message
	mov	ax,wFixupTarget			;invalid index?
	sub	ax,1
	jb	FixupExternal2
	mov	cx,EXTDEF_			;compute extdef offset
	mul	cx
	cmp	ax,EXTDEF_Index.eiNext		;extdef offset out of range?
	jnb	FixupExternal2
	mov	es:[bx.exExternal],ax		;save extdef offset
	mov	bx,ax
	cmp	bDumpFixupExternal,0		;fixup dump enabled?
	jz	FixupExternal1
	push	bx
	mov	si,offset sDumpFixupExternal	;begin fixup dump
	call	OutputString
	push	si
	mov	ax,word ptr dFixupDataOffset	;insert data stream offset
	mov	dx,word ptr dFixupDataOffset+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;continue fixup dump
	push	si
	mov	ax,wFixupTarget			;insert external index
	call	DumpHexWord
	pop	si
	call	OutputString			;continue fixup dump
	pop	bx
	push	si
	mov	si,[EXTDEF_Index.eiData.edSystemSymbol+bx] ;insert symbol
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	CopyWin32String
	mov	si,StringBuffer
	call	OutputQuotedString
	pop	si
	call	OutputString			;end fixup dump
FixupExternal1:
	clc					;ok
	jmp	FixupExternal3
FixupExternal2:
	call	OutputString			;display error message
	stc					;error
FixupExternal3:
	pop	es
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
FixupEntryPoint:
	mov	ax,word ptr dFixupDisplacement	;get entry point
	mov	dx,word ptr dFixupDisplacement+2
	call	MapMemoryOffset
	mov	word ptr osEntryPoint,ax	;set entry point in pe header
	mov	word ptr osEntryPoint+2,dx
	cmp	bDumpFixupEntryPoint,0		;fixup dump enabled?
	jz	FixupEntryPoint1
	mov	si,offset sDumpFixupEntryPoint	;begin entry point dump
	call	OutputString
	push	si
	mov	ax,word ptr osEntryPoint	;insert entry point
	mov	dx,word ptr osEntryPoint+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;end entry point dump
FixupEntryPoint1:
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
SortBaseRelocs:
	push	es
	mov	es,wFixupBuffer			;use fixup buffer
	mov	si,0				;load base offset
	mov	ax,wFixupBaseReloc		;compute number of entries
	mov	dx,0
	mov	cx,FIXUP_BASE_RELOC_
	div	cx
	mov	cx,ax
	cmp	cx,2				;sort data available?
	jb	SortBaseRelocs5
	mov	dx,cx				;initialize distance
SortBaseRelocs1:
	mov	ax,dx				;multiply distance by 3/4
	mov	bx,0
	shl	dx,1				;* 3
	rcl	bx,1
	add	dx,ax
	adc	bx,0
	shr	bx,1				;/ 4
	rcr	dx,1
	shr	bx,1
	rcr	dx,1
	sub	dx,1				;minimum = 1
	adc	dx,1
	push	si
	push	cx
	push	dx
	sub	cx,dx				;compute loop count
	mov	ax,FIXUP_BASE_RELOC_		;init 2nd sort pointer
	mul	dx
	mov	di,ax
	add	di,si
	mov	ah,0				;clear transposition flag
SortBaseRelocs2:
	mov	bx,word ptr es:[si.brMemoryOffset]	;load memory offset
	mov	dx,word ptr es:[si.brMemoryOffset+2]
	cmp	dx,word ptr es:[di.brMemoryOffset+2]	;incorrect order?
	ja	SortBaseRelocs3				;exchange entries
	jb	SortBaseRelocs4				;ok
	cmp	bx,word ptr es:[di.brMemoryOffset]	;incorrect order?
	jna	SortBaseRelocs4				;ok
SortBaseRelocs3:
	xchg	bx,word ptr es:[di.brMemoryOffset]	;exchange mem offsets
	xchg	dx,word ptr es:[di.brMemoryOffset+2]
	mov	word ptr es:[si.brMemoryOffset],bx
	mov	word ptr es:[si.brMemoryOffset+2],dx
	mov	ah,1				;set transposition flag
SortBaseRelocs4:
	add	si,FIXUP_BASE_RELOC_		;next entry pair
	add	di,FIXUP_BASE_RELOC_
	loop	SortBaseRelocs2
	pop	dx
	pop	cx
	pop	si
	cmp	dx,1				;minimum distance reached?
	ja	SortBaseRelocs1
	cmp	ah,0				;any transpositions?
	jnz	SortBaseRelocs1
SortBaseRelocs5:
	pop	es
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
SortExternals:
	push	es
	mov	es,wFixupBuffer			;use fixup buffer
	mov	si,wFixupExternal		;load base offset
	mov	ax,0				;compute number of entries
	sub	ax,si
	mov	dx,0
	mov	cx,FIXUP_EXTERNAL_
	div	cx
	mov	cx,ax
	cmp	cx,2				;sort data available?
	jb	SortExternals5
	mov	dx,cx				;initialize distance
SortExternals1:
	mov	ax,dx				;multiply distance by 3/4
	mov	bx,0
	shl	dx,1				;* 3
	rcl	bx,1
	add	dx,ax
	adc	bx,0
	shr	bx,1				;/ 4
	rcr	dx,1
	shr	bx,1
	rcr	dx,1
	sub	dx,1				;minimum = 1
	adc	dx,1
	push	si
	push	cx
	push	dx
	sub	cx,dx				;compute loop count
	mov	ax,FIXUP_EXTERNAL_		;init 2nd sort pointer
	mul	dx
	mov	di,ax
	add	di,si
	mov	ah,0				;clear transposition flag
SortExternals2:
	mov	bx,word ptr es:[si.exFileOffset]	;load file offset
	mov	dx,word ptr es:[si.exFileOffset+2]
	cmp	dx,word ptr es:[di.exFileOffset+2]	;incorrect order?
	ja	SortExternals3				;exchange entries
	jb	SortExternals4				;ok
	cmp	bx,word ptr es:[di.exFileOffset]	;incorrect order?
	jna	SortExternals4				;ok
SortExternals3:
	xchg	bx,word ptr es:[di.exFileOffset]	;exchange file offsets
	xchg	dx,word ptr es:[di.exFileOffset+2]
	mov	word ptr es:[si.exFileOffset],bx
	mov	word ptr es:[si.exFileOffset+2],dx
	mov	bx,es:[si.exExternal]		;exchange extdef offsets
	xchg	bx,es:[di.exExternal]
	mov	es:[si.exExternal],bx
	mov	ah,1				;set transposition flag
SortExternals4:
	add	si,FIXUP_EXTERNAL_		;next entry pair
	add	di,FIXUP_EXTERNAL_
	loop	SortExternals2
	pop	dx
	pop	cx
	pop	si
	cmp	dx,1				;minimum distance reached?
	ja	SortExternals1
	cmp	ah,0				;any transpositions?
	jnz	SortExternals1
SortExternals5:
	pop	es
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
SortExportSymbols:
	mov	ax,PUBDEF_Index.piNext		;compute number of entries
	mov	dx,0
	mov	cx,PUBDEF_
	div	cx
	cmp	ax,2				;sort data available?
	jb	SortExportSymbols12
	mov	cx,ax				;save number of entries
SortExportSymbols1:
	mov	dx,ax				;multiply distance by 3/4
	mov	bx,0
	shl	ax,1				;* 3
	rcl	bx,1
	add	ax,dx
	adc	bx,0
	shr	bx,1				;/ 4
	rcr	ax,1
	shr	bx,1
	rcr	ax,1
	sub	ax,1				;minimum = 1
	adc	ax,1
	push	ax
	push	cx
	sub	cx,ax				;compute loop count
	mov	dx,PUBDEF_			;compute entry offset
	mul	dx
	mov	bx,0				;init sort pointers
	mov	dx,ax
	mov	ah,0				;clear transposition flag
SortExportSymbols2:
	mov	al,EXPORT_ESCAPE		;scan symbol #1
	mov	si,[PUBDEF_Index.piData.pdSymbol+bx]
SortExportSymbols3:
	inc	si				;next character
	cmp	byte ptr [si-1],0		;end of symbol?
	jz	SortExportSymbols4
	cmp	byte ptr [si-1],al		;export escape?
	jz	SortExportSymbols5
	cmp	byte ptr [si-1],FORWARD_ESCAPE	;forward escape?
	jz	SortExportSymbols5
	mov	al,0				;suppress export escape matches
	jmp	SortExportSymbols3
SortExportSymbols4:
	mov	si,[PUBDEF_Index.piData.pdSymbol+bx] ;not a special symbol
SortExportSymbols5:
	xchg	dx,bx
	mov	al,EXPORT_ESCAPE		;scan symbol #2
	mov	di,[PUBDEF_Index.piData.pdSymbol+bx]
SortExportSymbols6:
	inc	di				;next character
	cmp	byte ptr [di-1],0		;end of symbol?
	jz	SortExportSymbols7
	cmp	byte ptr [di-1],al		;export escape?
	jz	SortExportSymbols8
	cmp	byte ptr [di-1],FORWARD_ESCAPE	;forward escape?
	jz	SortExportSymbols8
	mov	al,0				;suppress export escape matches
	jmp	SortExportSymbols6
SortExportSymbols7:
	mov	di,[PUBDEF_Index.piData.pdSymbol+bx] ;not a special symbol
SortExportSymbols8:
	xchg	dx,bx
SortExportSymbols9:
	mov	al,[si]				;compare characters
	cmp	al,[di]
	ja	SortExportSymbols10		;exchange entries
	jb	SortExportSymbols11		;ok
	or	al,[di]				;end of both symbols?
	jz	SortExportSymbols11		;ok
	inc	si				;next character
	inc	di
	jmp	SortExportSymbols9
SortExportSymbols10:
	mov	di,dx
	mov	si,[PUBDEF_Index.piData.pdSymbol+bx] ;exchange symbol pointers
	xchg	si,[PUBDEF_Index.piData.pdSymbol+di]
	mov	[PUBDEF_Index.piData.pdSymbol+bx],si
	mov	si,word ptr [PUBDEF_Index.piData.pdAddress+bx] ;exchg addresses
	xchg	si,word ptr [PUBDEF_Index.piData.pdAddress+di]
	mov	word ptr [PUBDEF_Index.piData.pdAddress+bx],si
	mov	si,word ptr [PUBDEF_Index.piData.pdAddress+2+bx]
	xchg	si,word ptr [PUBDEF_Index.piData.pdAddress+2+di]
	mov	word ptr [PUBDEF_Index.piData.pdAddress+2+bx],si
	mov	ah,1				;set transposition flag
SortExportSymbols11:
	add	bx,PUBDEF_			;next entry pair
	add	dx,PUBDEF_
	dec	cx
	jnz	SortExportSymbols2
	mov	dh,ah				;save transposition flag
	pop	cx
	pop	ax
	cmp	ax,1				;minimum distance reached?
	ja	SortExportSymbols1
	cmp	dh,0				;any transpositions?
	jnz	SortExportSymbols1
SortExportSymbols12:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  data offset
;
;	<	dx:ax  -  memory offset
;
;------------------------------------------------------------------------------
;
MapMemoryOffset:
	mov	di,ax				;offset above data section?
	mov	si,dx
	sub	di,word ptr dNextBegin
	sbb	si,word ptr dNextBegin+2
	jnb	MapMemoryOffset2
	mov	di,ax				;offset above text section?
	mov	si,dx
	sub	di,word ptr dDataBegin
	sbb	si,word ptr dDataBegin+2
	jnb	MapMemoryOffset1
	mov	di,ax				;offset below text section?
	mov	si,dx
	sub	di,word ptr dTextBegin
	sbb	si,word ptr dTextBegin+2
	mov	ax,0
	mov	dx,0
	jb	MapMemoryOffset4
	add	di,word ptr seTextHeader.shLoadAddress	;offset in .text
	adc	si,word ptr seTextHeader.shLoadAddress+2
	jmp	MapMemoryOffset3
MapMemoryOffset1:
	add	di,word ptr seDataHeader.shLoadAddress	;offset in .data
	adc	si,word ptr seDataHeader.shLoadAddress+2
	jmp	MapMemoryOffset3
MapMemoryOffset2:
	add	di,word ptr dNextLoadAddress	;offset in some other section
	adc	si,word ptr dNextLoadAddress+2
MapMemoryOffset3:
	mov	ax,di				;load memory offset
	mov	dx,si
MapMemoryOffset4:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  data offset
;
;	<	dx:ax  -  memory offset
;
;------------------------------------------------------------------------------
;
MapFileOffset:
	mov	di,ax				;offset above data section?
	mov	si,dx
	sub	di,word ptr dNextBegin
	sbb	si,word ptr dNextBegin+2
	jnb	MapFileOffset2
	mov	di,ax				;offset above text section?
	mov	si,dx
	sub	di,word ptr dDataBegin
	sbb	si,word ptr dDataBegin+2
	jnb	MapFileOffset1
	mov	di,ax				;offset below text section?
	mov	si,dx
	sub	di,word ptr dTextBegin
	sbb	si,word ptr dTextBegin+2
	mov	ax,0
	mov	dx,0
	jb	MapFileOffset4
	add	di,word ptr seTextHeader.shRawAddress	;offset in text section
	adc	si,word ptr seTextHeader.shRawAddress+2
	jmp	MapFileOffset3
MapFileOffset1:
	add	di,word ptr seDataHeader.shRawAddress	;offset in data section
	adc	si,word ptr seDataHeader.shRawAddress+2
	jmp	MapFileOffset3
MapFileOffset2:
	add	di,word ptr dNextRawAddress	;offset in some other section
	adc	si,word ptr dNextRawAddress+2
MapFileOffset3:
	mov	ax,di				;load file offset
	mov	dx,si
MapFileOffset4:
	ret
;
;==============================================================================
;
;	PE CONSTRUCTION
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
SkipFileHeaders:
	mov	ax,HEADERS_FILE_		;reserve file header space
	mov	dx,0
	jmp	SetOutputPointer
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteFileHeaders:
	mov	ax,word ptr dTimeDate		;set time/date stamp
	mov	dx,word ptr dTimeDate+2
	mov	word ptr peTimeDate,ax
	mov	word ptr peTimeDate+2,dx
	mov	ax,word ptr seRelocHeader.shLoadAddress	;set image size
	mov	dx,word ptr seRelocHeader.shLoadAddress+2
	add	ax,word ptr seRelocHeader.shLoadSize
	adc	dx,word ptr seRelocHeader.shLoadSize+2
	mov	cx,MEMORY_PAGE
	call	GetNextPage
	mov	word ptr onImageSize,ax
	mov	word ptr onImageSize+2,dx
	mov	ax,0				;rewind output file
	mov	dx,0
	call	SetOutputPointer
	jb	WriteFileHeaders1
	mov	si,IMAGE_BASE			;write file headers
	mov	cx,HEADERS_RAW_
	call	WriteOutputBlock
WriteFileHeaders1:
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
InitSectionData:
	mov	ax,2*SECTION_DATA_		;set code section offset
	mov	dx,0
	mov	word ptr dTextBegin,ax
	mov	word ptr dTextBegin+2,dx
	mov	ax,word ptr dTextBegin		;set code section end
	mov	dx,word ptr dTextBegin+2
	add	ax,word ptr TextSection.scFileBytes
	adc	dx,word ptr TextSection.scFileBytes+2
	mov	word ptr dTextEnd,ax
	mov	word ptr dTextEnd+2,dx
	mov	ax,word ptr dTextBegin		;set data section offset
	mov	dx,word ptr dTextBegin+2
	add	ax,word ptr TextSection.scMemoryBytes
	adc	dx,word ptr TextSection.scMemoryBytes+2
	mov	word ptr dDataBegin,ax
	mov	word ptr dDataBegin+2,dx
	mov	ax,word ptr dDataBegin		;set data section end
	mov	dx,word ptr dDataBegin+2
	add	ax,word ptr DataSection.scFileBytes
	adc	dx,word ptr DataSection.scFileBytes+2
	mov	word ptr dDataEnd,ax
	mov	word ptr dDataEnd+2,dx
	mov	ax,word ptr dDataBegin		;set next section offset
	mov	dx,word ptr dDataBegin+2
	add	ax,word ptr DataSection.scMemoryBytes
	adc	dx,word ptr DataSection.scMemoryBytes+2
	mov	word ptr dNextBegin,ax
	mov	word ptr dNextBegin+2,dx
	mov	ax,HEADERS_MEMORY_		;set memory section parameters
	mov	dx,0
	mov	word ptr seTextHeader.shLoadAddress,ax
	mov	word ptr seTextHeader.shLoadAddress+2,dx
	mov	word ptr osTextAddress,ax
	mov	word ptr osTextAddress+2,dx
	mov	di,word ptr TextSection.scMemoryBytes
	mov	si,word ptr TextSection.scMemoryBytes+2
	mov	word ptr seTextHeader.shLoadSize,di
	mov	word ptr seTextHeader.shLoadSize+2,si
	add	ax,di
	adc	dx,si
	mov	cx,MEMORY_PAGE
	call	GetNextPage
	mov	word ptr seDataHeader.shLoadAddress,ax
	mov	word ptr seDataHeader.shLoadAddress+2,dx
	mov	word ptr osDataAddress,ax
	mov	word ptr osDataAddress+2,dx
	mov	di,word ptr DataSection.scMemoryBytes
	mov	si,word ptr DataSection.scMemoryBytes+2
	mov	word ptr seDataHeader.shLoadSize,di
	mov	word ptr seDataHeader.shLoadSize+2,si
	add	ax,di
	adc	dx,si
	mov	cx,MEMORY_PAGE
	call	GetNextPage
	mov	word ptr dNextLoadAddress,ax
	mov	word ptr dNextLoadAddress+2,dx
	mov	ax,HEADERS_FILE_		;set file section parameters
	mov	dx,0
	mov	word ptr seTextHeader.shRawAddress,ax
	mov	word ptr seTextHeader.shRawAddress+2,dx
	mov	ax,word ptr TextSection.scFileBytes
	mov	dx,word ptr TextSection.scFileBytes+2
	mov	cx,FILE_PAGE
	call	GetNextPage
	mov	word ptr seTextHeader.shRawSize,ax
	mov	word ptr seTextHeader.shRawSize+2,dx
	mov	word ptr osTextTotal,ax
	mov	word ptr osTextTotal+2,dx
	add	ax,word ptr seTextHeader.shRawAddress
	adc	dx,word ptr seTextHeader.shRawAddress+2
	mov	word ptr seDataHeader.shRawAddress,ax
	mov	word ptr seDataHeader.shRawAddress+2,dx
	mov	ax,word ptr DataSection.scFileBytes
	mov	dx,word ptr DataSection.scFileBytes+2
	mov	cx,FILE_PAGE
	call	GetNextPage
	mov	word ptr seDataHeader.shRawSize,ax
	mov	word ptr seDataHeader.shRawSize+2,dx
	mov	word ptr osDataTotal,ax
	mov	word ptr osDataTotal+2,dx
	add	ax,word ptr seDataHeader.shRawAddress
	adc	dx,word ptr seDataHeader.shRawAddress+2
	mov	word ptr dNextRawAddress,ax
	mov	word ptr dNextRawAddress+2,dx
	lea	si,TextSection.scSectionName	;copy text section name
	lea	di,seTextHeader.shName
	mov	cx,SNL
	call	CopyStructure
	lea	si,DataSection.scSectionName	;copy data section name
	lea	di,seDataHeader.shName
	mov	cx,SNL
	jmp	CopyStructure
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
DumpSectionData:
	cmp	bDumpSection,0			;section dump enabled?
	jz	DumpSectionData1
	mov	si,offset sDumpTextSection	;begin text section dump
	call	OutputString
	push	si
	mov	ax,word ptr seTextHeader.shLoadAddress	;insert addr in memory
	mov	dx,word ptr seTextHeader.shLoadAddress+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr seTextHeader.shLoadSize	;insert size in memory
	mov	dx,word ptr seTextHeader.shLoadSize+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr seTextHeader.shRawAddress	;insert addr in file
	mov	dx,word ptr seTextHeader.shRawAddress+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr seTextHeader.shRawSize	;insert size in file
	mov	dx,word ptr seTextHeader.shRawSize+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	lea	si,seTextHeader.shName		;insert section name
	call	DisplaySectionName
	pop	si
	call	OutputString			;end text section dump
	mov	si,offset sDumpDataSection	;begin data section dump
	call	OutputString
	push	si
	mov	ax,word ptr seDataHeader.shLoadAddress	;insert addr in memory
	mov	dx,word ptr seDataHeader.shLoadAddress+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr seDataHeader.shLoadSize	;insert size in memory
	mov	dx,word ptr seDataHeader.shLoadSize+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr seDataHeader.shRawAddress	;insert addr in file
	mov	dx,word ptr seDataHeader.shRawAddress+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	mov	ax,word ptr seDataHeader.shRawSize	;insert size in file
	mov	dx,word ptr seDataHeader.shRawSize+2
	call	DumpHexDouble
	pop	si
	call	OutputString
	push	si
	lea	si,seDataHeader.shName		;insert section name
	call	DisplaySectionName
	pop	si
	call	OutputString			;end data section dump
DumpSectionData1:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteSectionData:
	mov	al,bDataType			;load data type
	cmp	al,DATA_INIT			;data initialization?
	jz	WriteSectionData2
	mov	bDataType,DATA_NONE		;clear data type
	cmp	al,DATA_LEDATA			;logical enumerated data?
	mov	dx,WriteSectionLedataBlock
	jz	WriteSectionData1
	cmp	al,DATA_LIDATA16		;logical iterated 16-bit data?
	mov	dx,WriteSectionLidata16Block
	jz	WriteSectionData1
	cmp	al,DATA_LIDATA32		;logical iterated 32-bit data?
	mov	dx,WriteSectionLidata32Block
	jnz	WriteSectionData2
WriteSectionData1:
	call	dx				;write section data
	jmp	WriteSectionData3
WriteSectionData2:
	mov	ax,0				;ok
	clc
WriteSectionData3:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteSectionLedataBlock:
	mov	ax,wOutputOffset		;set expected target offset
	mov	dx,wOutputSegment
	mov	word ptr dDataTarget,ax
	mov	word ptr dDataTarget+2,dx
	mov	cx,wDataLength			;load data block length
	jcxz	WriteSectionLedataBlock2
	mov	di,0				;init data block index
WriteSectionLedataBlock1:
	push	di
	push	cx
	mov	al,byte ptr [di+DataBuffer]	;load data byte
	mov	si,0				;data block index -> 32-bit
	add	di,word ptr dDataOffset		;compute data offset
	adc	si,word ptr dDataOffset+2
	call	WriteSectionByte		;write data byte
	pop	cx
	pop	di
	jb	WriteSectionLedataBlock3	;error
	inc	di				;next data byte
	loop	WriteSectionLedataBlock1
WriteSectionLedataBlock2:
	mov	ax,0				;ok
	clc
WriteSectionLedataBlock3:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteSectionLidata16Block:
	mov	si,0				;reset data block offset
WriteSectionLidata16Block1:
	cmp	si,wDataLength			;end of data?
	jnb	WriteSectionLidata16Block3
	mov	bx,word ptr [si+DataBuffer]	;load repeat count
	add	si,2
WriteSectionLidata16Block2:
	push	si
	call	WriteSectionLidata16Bytes	;write data block
	mov	di,si
	pop	si
	jb	WriteSectionLidata16Block4
	cmp	bx,0				;test repeat count
	jnz	WriteSectionLidata16Block2	;repeat data block
	mov	si,di				;next data block
	jmp	WriteSectionLidata16Block1
WriteSectionLidata16Block3:
	mov	ax,0				;ok
	clc
WriteSectionLidata16Block4:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteSectionLidata32Block:
	mov	si,0				;reset data block offset
WriteSectionLidata32Block1:
	cmp	si,wDataLength			;end of data?
	jnb	WriteSectionLidata32Block3
	mov	bx,word ptr [si+DataBuffer]	;load repeat count
	mov	dx,word ptr [si+DataBuffer+2]
	add	si,4
WriteSectionLidata32Block2:
	push	si
	call	WriteSectionLidata32Bytes	;write data block
	mov	di,si
	pop	si
	jb	WriteSectionLidata32Block4
	mov	ax,bx				;test repeat count
	or	ax,dx
	jnz	WriteSectionLidata32Block2	;repeat data block
	mov	si,di				;next data block
	jmp	WriteSectionLidata32Block1
WriteSectionLidata32Block3:
	mov	ax,0				;ok
	clc
WriteSectionLidata32Block4:
	ret
;
;==============================================================================
;
;	>	si  -  data block offset
;		bx  -  repeat count
;
;	<	si  -  next data block offset
;		bx  -  modified repeat count
;		ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteSectionLidata16Bytes:
	push	bx
	sub	wDataRecursion,1		;count recursions
	mov	ax,-1
	jb	WriteSectionLidata16Bytes7	;recursion stack overflow
	mov	cx,word ptr [si+DataBuffer]	;load data block count
	add	si,2
	jcxz	WriteSectionLidata16Bytes3	;recursion base
WriteSectionLidata16Bytes1:
	mov	bx,word ptr [si+DataBuffer]	;load repeat count
	add	si,2
WriteSectionLidata16Bytes2:
	push	cx
	push	si
	call	WriteSectionLidata16Bytes	;write data block
	mov	di,si
	pop	si
	pop	cx
	jb	WriteSectionLidata16Bytes7	;error
	cmp	bx,0				;test repeat count
	jnz	WriteSectionLidata16Bytes2	;repeat data block
	mov	si,di				;next data block
	loop	WriteSectionLidata16Bytes1
	jmp	WriteSectionLidata16Bytes6	;ok
WriteSectionLidata16Bytes3:
	mov	cl,byte ptr [si+DataBuffer]	;load data byte count
	mov	ch,0
	inc	si
	jcxz	WriteSectionLidata16Bytes6
WriteSectionLidata16Bytes4:
	mov	al,byte ptr [si+DataBuffer]	;copy data byte
	inc	si
	pop	bx
	push	bx
	cmp	bx,0				;repeat count = 0?
	jz	WriteSectionLidata16Bytes5
	push	cx
	push	si
	mov	di,word ptr dDataOffset		;write data byte
	mov	si,word ptr dDataOffset+2
	call	WriteSectionByte
	pop	si
	pop	cx
	jb	WriteSectionLidata16Bytes7	;error
	add	word ptr dDataOffset,1		;next data offset
	adc	word ptr dDataOffset+2,0
WriteSectionLidata16Bytes5:
	loop	WriteSectionLidata16Bytes4	;next data byte
WriteSectionLidata16Bytes6:
	mov	ax,0				;ok
	clc
WriteSectionLidata16Bytes7:
	inc	wDataRecursion			;recursion done
	pop	bx
	pushf
	mov	cx,bx				;repeat count = 0?
	add	cx,-1
	sbb	bx,0				;decrement if not 0
	popf
	ret
;
;==============================================================================
;
;	>	   si  -  data block offset
;		dx:bx  -  repeat count
;
;	<	   si  -  next data block offset
;		dx:bx  -  modified repeat count
;		   ax  -  return code
;		    c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteSectionLidata32Bytes:
	push	dx
	push	bx
	sub	wDataRecursion,1		;count recursions
	mov	ax,-1
	jb	WriteSectionLidata32Bytes7	;recursion stack overflow
	mov	cx,word ptr [si+DataBuffer]	;load data block count
	add	si,2
	jcxz	WriteSectionLidata32Bytes3	;recursion base
WriteSectionLidata32Bytes1:
	mov	bx,word ptr [si+DataBuffer]	;load repeat count
	mov	dx,word ptr [si+DataBuffer+2]
	add	si,4
WriteSectionLidata32Bytes2:
	push	cx
	push	si
	call	WriteSectionLidata32Bytes	;write data block
	mov	di,si
	pop	si
	pop	cx
	jb	WriteSectionLidata32Bytes7	;error
	mov	ax,bx				;test repeat count
	or	ax,dx
	jnz	WriteSectionLidata32Bytes2	;repeat data block
	mov	si,di				;next data block
	loop	WriteSectionLidata32Bytes1
	jmp	WriteSectionLidata32Bytes6	;ok
WriteSectionLidata32Bytes3:
	mov	cl,byte ptr [si+DataBuffer]	;load data byte count
	mov	ch,0
	inc	si
	jcxz	WriteSectionLidata32Bytes6
WriteSectionLidata32Bytes4:
	mov	al,byte ptr [si+DataBuffer]	;copy data byte
	inc	si
	pop	bx
	pop	dx
	push	dx
	push	bx
	or	bx,dx				;repeat count = 0?
	jz	WriteSectionLidata32Bytes5
	push	cx
	push	si
	mov	di,word ptr dDataOffset		;write data byte
	mov	si,word ptr dDataOffset+2
	call	WriteSectionByte
	pop	si
	pop	cx
	jb	WriteSectionLidata32Bytes7	;error
	add	word ptr dDataOffset,1		;next data offset
	adc	word ptr dDataOffset+2,0
WriteSectionLidata32Bytes5:
	loop	WriteSectionLidata32Bytes4	;next data byte
WriteSectionLidata32Bytes6:
	mov	ax,0				;ok
	clc
WriteSectionLidata32Bytes7:
	inc	wDataRecursion			;recursion done
	pop	bx
	pop	dx
	pushf
	mov	cx,bx				;repeat count = 0?
	or	cx,dx
	add	cx,-1
	sbb	bx,0				;decrement if not 0
	sbb	dx,0
	popf
	ret
;
;==============================================================================
;
;	>	   al  -  data byte
;		si:di  -  data offset
;
;	<	   ax  -  return code
;		    c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteSectionByte:
	mov	bDataByte,al			;save data byte
	mov	dx,di				;offset above data section?
	mov	cx,si
	sub	dx,word ptr dDataEnd
	sbb	cx,word ptr dDataEnd+2
	jnb	WriteSectionByte4
	mov	dx,di				;offset above text section?
	mov	cx,si
	sub	dx,word ptr dTextEnd
	sbb	cx,word ptr dTextEnd+2
	jnb	WriteSectionByte1
	sub	di,word ptr dTextBegin		;offset below text section?
	sbb	si,word ptr dTextBegin+2
	jb	WriteSectionByte4
	add	di,word ptr seTextHeader.shRawAddress	;compute target address
	adc	si,word ptr seTextHeader.shRawAddress+2
	jmp	WriteSectionByte2
WriteSectionByte1:
	sub	di,word ptr dDataBegin		;offset below data section?
	sbb	si,word ptr dDataBegin+2
	jb	WriteSectionByte4
	add	di,word ptr seDataHeader.shRawAddress	;compute target address
	adc	si,word ptr seDataHeader.shRawAddress+2
WriteSectionByte2:
	mov	ax,di				;load target address
	mov	dx,si
	sub	di,word ptr dDataTarget		;expected target address?
	sbb	si,word ptr dDataTarget+2
	or	si,di
	jz	WriteSectionByte3
	mov	word ptr dDataTarget,ax		;set output file pointer
	mov	word ptr dDataTarget+2,dx
	call	SetOutputPointer
	jb	WriteSectionByte5
WriteSectionByte3:
	add	word ptr dDataTarget,1		;next expected target offset
	adc	word ptr dDataTarget+2,0
	mov	si,offset bDataByte		;write data byte
	mov	cx,1
	call	WriteOutputBlock
	jb	WriteSectionByte5
WriteSectionByte4:
	mov	ax,0				;ok
	clc
WriteSectionByte5:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteImports:
	mov	ax,word ptr seDataHeader.shLoadAddress	;set sec addr in memory
	mov	dx,word ptr seDataHeader.shLoadAddress+2
	add	ax,word ptr seDataHeader.shLoadSize
	adc	dx,word ptr seDataHeader.shLoadSize+2
	mov	cx,MEMORY_PAGE
	call	GetNextPage
	mov	word ptr seLinkHeader.shLoadAddress,ax
	mov	word ptr seLinkHeader.shLoadAddress+2,dx
	mov	word ptr odImport.ddAddress,ax		;update data directory
	mov	word ptr odImport.ddAddress+2,dx
	mov	ax,word ptr seDataHeader.shRawAddress	;set sec addr in file
	mov	dx,word ptr seDataHeader.shRawAddress+2
	add	ax,word ptr seDataHeader.shRawSize
	adc	dx,word ptr seDataHeader.shRawSize+2
	mov	word ptr seLinkHeader.shRawAddress,ax
	mov	word ptr seLinkHeader.shRawAddress+2,dx
	call	WriteImportDirectory		;write import directory
	jb	WriteImports1
	call	WriteImportTable		;write import lookup table
	jb	WriteImports1
	call	WriteImportTable		;write import address table
	jb	WriteImports1
	call	WriteImportModuleNames		;write import module names
	jb	WriteImports1
	call	WriteImportSymbols		;write import symbol list
	jb	WriteImports1
	mov	ax,wOutputOffset		;set section size in memory
	mov	dx,wOutputSegment
	sub	ax,word ptr seLinkHeader.shRawAddress
	sbb	dx,word ptr seLinkHeader.shRawAddress+2
	mov	word ptr seLinkHeader.shLoadSize,ax
	mov	word ptr seLinkHeader.shLoadSize+2,dx
	mov	word ptr odImport.ddSize,ax	;update data directory
	mov	word ptr odImport.ddSize+2,dx
	mov	cx,PARAGRAPH			;set section size in file
	call	GetNextPage
	mov	word ptr seLinkHeader.shRawSize,ax
	mov	word ptr seLinkHeader.shRawSize+2,dx
	mov	cx,PARAGRAPH			;go to next pe file paragraph
	call	NextOutputPage
WriteImports1:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteImportDirectory:
	mov	di,ImportDir			;load import directory entry
	mov	word ptr [di.idTimeDate],0	;clear time/date stamp
	mov	word ptr [di.idTimeDate+2],0
	mov	word ptr [di.idForwarderChain],0;no forwarder chain
	mov	word ptr [di.idForwarderChain+2],0
	mov	ax,MODDEF_Index.miNext		;compute number of modules
	mov	dx,0
	mov	cx,MODDEF_
	div	cx
	mov	si,ax				;save number of modules
	inc	ax				;reserve terminator slot
	mov	cx,PE_IMPORT_DIR_		;compute import directory size
	mul	cx
	add	ax,word ptr seLinkHeader.shLoadAddress ;add section offset
	adc	dx,word ptr seLinkHeader.shLoadAddress+2
	mov	word ptr [di.idLookupTable],ax	;set lookup table offset
	mov	word ptr [di.idLookupTable+2],dx
	mov	word ptr [di.idAddressTable],ax	;prepare address table offset
	mov	word ptr [di.idAddressTable+2],dx
	mov	ax,EXTDEF_Index.eiNext		;compute number of externals
	mov	dx,0
	mov	cx,EXTDEF_
	div	cx
	add	ax,si				;reserve terminator slots
	mov	cx,4				;compute lookup table size
	mul	cx
	add	word ptr [di.idAddressTable],ax	;finish address table offset
	adc	word ptr [di.idAddressTable+2],dx
	add	ax,word ptr [di.idAddressTable]	;compute module name offset
	adc	dx,word ptr [di.idAddressTable+2]
	mov	word ptr [di.idModuleName],ax	;set module name offset
	mov	word ptr [di.idModuleName+2],dx
	mov	bx,0				;scan module index
WriteImportDirectory1:
	cmp	bx,MODDEF_Index.miNext		;end of module data?
	jnb	WriteImportDirectory2
	push	bx
	mov	si,ImportDir			;write import directory entry
	mov	cx,PE_IMPORT_DIR_
	call	WriteOutputBlock
	pop	bx
	jb	WriteImportDirectory3
	mov	di,ImportDir			;load import directory entry
	mov	cx,[MODDEF_Index.miData.mdLength+bx] ;get module name length
	inc	cx				;count terminator
	ror	cx,1				;make even
	rol	cx,1
	adc	word ptr [di.idModuleName],cx	;set next module name offset
	adc	word ptr [di.idModuleName+2],0
	mov	ax,[MODDEF_Index.miData.mdCount+bx] ;get reference count
	inc	ax
	mov	cx,4				;compute lookup subtable size
	mul	cx
	add	word ptr [di.idLookupTable],ax	;set next lookup table offset
	adc	word ptr [di.idLookupTable+2],dx
	add	word ptr [di.idAddressTable],ax	;set next address table offset
	adc	word ptr [di.idAddressTable+2],dx
	add	bx,MODDEF_			;next module
	jmp	WriteImportDirectory1
WriteImportDirectory2:
	mov	di,ImportDir			;load import directory entry
	mov	ax,word ptr [di.idModuleName]	;save symbol list offset
	mov	dx,word ptr [di.idModuleName+2]
	mov	word ptr dImportSymbols,ax
	mov	word ptr dImportSymbols+2,dx
	mov	word ptr [di.idModuleName],0	;clear module name offset
	mov	word ptr [di.idModuleName+2],0
	mov	word ptr [di.idLookupTable],0	;clear lookup table offset
	mov	word ptr [di.idLookupTable+2],0
	mov	word ptr [di.idAddressTable],0	;clear address table offset
	mov	word ptr [di.idAddressTable+2],0
	mov	si,ImportDir			;write terminating entry
	mov	cx,PE_IMPORT_DIR_
	call	WriteOutputBlock
WriteImportDirectory3:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteImportTable:
	push	word ptr dImportSymbols+2	;save symbol list offset
	push	word ptr dImportSymbols
	mov	bx,0				;scan module index
WriteImportTable1:
	cmp	bx,MODDEF_Index.miNext		;end of module data?
	jnb	WriteImportTable5
	mov	si,0				;scan external index
WriteImportTable2:
	cmp	si,EXTDEF_Index.eiNext		;end of external data?
	jnb	WriteImportTable4
	cmp	bx,[EXTDEF_Index.eiData.edModule+si] ;test module pointer
	jnz	WriteImportTable3
	mov	ax,wOutputOffset		;compute table entry offset
	mov	dx,wOutputSegment
	sub	ax,word ptr seLinkHeader.shRawAddress
	sbb	dx,word ptr seLinkHeader.shRawAddress+2
	add	ax,word ptr seLinkHeader.shLoadAddress
	adc	dx,word ptr seLinkHeader.shLoadAddress+2
	add	ax,word ptr onImageBase		;add preferred load address
	adc	dx,word ptr onImageBase+2
	mov	word ptr [EXTDEF_Index.eiData.edAddress+si],ax ;save address
	mov	word ptr [EXTDEF_Index.eiData.edAddress+2+si],dx
	push	bx
	push	si
	mov	si,offset dImportSymbols	;write symbol pointer
	mov	cx,4
	call	WriteOutputBlock
	pop	si
	pop	bx
	jb	WriteImportTable5
	mov	cx,[EXTDEF_Index.eiData.edLength+si] ;get symbol length
	add	cx,2+1				;count ordinal + terminator
	ror	cx,1				;make even
	rol	cx,1
	adc	word ptr dImportSymbols,cx	;compute next symbol offset
	adc	word ptr dImportSymbols+2,0
WriteImportTable3:
	add	si,EXTDEF_			;next external
	jmp	WriteImportTable2
WriteImportTable4:
	push	bx
	mov	si,offset dNull			;write import table terminator
	mov	cx,4
	call	WriteOutputBlock
	pop	bx
	jb	WriteImportTable5
	add	bx,MODDEF_			;next module
	jmp	WriteImportTable1
WriteImportTable5:
	pop	word ptr dImportSymbols		;restore symbol list offset
	pop	word ptr dImportSymbols+2
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteImportModuleNames:
	mov	bx,0				;scan module index
WriteImportModuleNames1:
	cmp	bx,MODDEF_Index.miNext		;end of module data?
	jnb	WriteImportModuleNames3
	cmp	[MODDEF_Index.miData.mdLength+bx],StringBuffer_ ;length ok?
	mov	ax,-1
	cmc
	jb	WriteImportModuleNames3
	push	bx
	mov	si,[MODDEF_Index.miData.mdModule+bx] ;copy module name
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	CopyWin32String
	mov	si,StringBuffer			;write module name
	inc	cx
	push	cx
	call	WriteOutputBlock
	pop	cx
	pop	bx
	jb	WriteImportModuleNames3
	ror	cx,1				;even length?
	rol	cx,1
	jnb	WriteImportModuleNames2
	push	bx
	mov	si,offset sNull			;insert byte
	mov	cx,1
	call	WriteOutputBlock
	pop	bx
	jb	WriteImportModuleNames3
WriteImportModuleNames2:
	add	bx,MODDEF_			;next module
	jmp	WriteImportModuleNames1
WriteImportModuleNames3:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteImportSymbols:
	mov	bx,0				;scan module index
WriteImportSymbols1:
	cmp	bx,MODDEF_Index.miNext		;end of module data?
	jnb	WriteImportSymbols5
	mov	si,0				;scan external index
WriteImportSymbols2:
	cmp	si,EXTDEF_Index.eiNext		;end of external data?
	jnb	WriteImportSymbols4
	cmp	bx,[EXTDEF_Index.eiData.edModule+si] ;test module pointer
	jnz	WriteImportSymbols3
	cmp	[EXTDEF_Index.eiData.edLength+si],StringBuffer_ ;length ok?
	mov	ax,-1
	cmc
	jb	WriteImportSymbols5
	push	bx
	push	si
	lea	si,[EXTDEF_Index.eiData.edOrdinal+si] ;write ordinal number
	mov	cx,2
	call	WriteOutputBlock
	pop	si
	pop	bx
	jb	WriteImportSymbols5
	push	bx
	push	si
	mov	si,[EXTDEF_Index.eiData.edSystemSymbol+si] ;copy system symbol
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	CopyWin32String
	mov	si,StringBuffer			;write system symbol
	inc	cx
	push	cx
	call	WriteOutputBlock
	pop	cx
	pop	si
	pop	bx
	jb	WriteImportSymbols5
	ror	cx,1				;even length?
	rol	cx,1
	jnb	WriteImportSymbols3
	push	bx
	push	si
	mov	si,offset sNull			;insert byte
	mov	cx,1
	call	WriteOutputBlock
	pop	si
	pop	bx
	jb	WriteImportSymbols5
WriteImportSymbols3:
	add	si,EXTDEF_			;next external
	jmp	WriteImportSymbols2
WriteImportSymbols4:
	add	bx,MODDEF_			;next module
	jmp	WriteImportSymbols1
WriteImportSymbols5:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExports:
	cmp	PUBDEF_Index.piNext,0		;public index empty?
	jz	WriteExports1
	mov	ax,word ptr seLinkHeader.shLoadAddress	;get sec addr in memory
	mov	dx,word ptr seLinkHeader.shLoadAddress+2
	add	ax,word ptr seLinkHeader.shLoadSize
	adc	dx,word ptr seLinkHeader.shLoadSize+2
	mov	cx,PARAGRAPH
	call	GetNextPage
	mov	word ptr odExport.ddAddress,ax		;update data directory
	mov	word ptr odExport.ddAddress+2,dx
	call	WriteExportDirectory		;write export directory
	jb	WriteExports3
	call	WriteExportAddressTable		;write export address table
	jb	WriteExports3
	call	WriteExportNamePointerTable	;write export name ptr table
	jb	WriteExports3
	call	WriteExportOrdinalTable		;write export ordinal table
	jb	WriteExports3
	call	WriteExportModuleName		;write export module name
	jb	WriteExports3
	call	WriteExportSymbols		;write export symbols
	jb	WriteExports3
WriteExports1:
	mov	ax,wOutputOffset		;set section size in memory
	mov	dx,wOutputSegment
	sub	ax,word ptr seLinkHeader.shRawAddress
	sbb	dx,word ptr seLinkHeader.shRawAddress+2
	mov	word ptr seLinkHeader.shLoadSize,ax
	mov	word ptr seLinkHeader.shLoadSize+2,dx
	mov	cx,FILE_PAGE			;set section size in file
	call	GetNextPage
	mov	word ptr seLinkHeader.shRawSize,ax
	mov	word ptr seLinkHeader.shRawSize+2,dx
	add	word ptr osDataTotal,ax		;update data size total
	adc	word ptr osDataTotal+2,dx
	cmp	PUBDEF_Index.piNext,0		;public index empty?
	jz	WriteExports2
	mov	ax,word ptr seLinkHeader.shLoadAddress	;get sec size in memory
	mov	dx,word ptr seLinkHeader.shLoadAddress+2
	add	ax,word ptr seLinkHeader.shLoadSize
	adc	dx,word ptr seLinkHeader.shLoadSize+2
	sub	ax,word ptr odExport.ddAddress
	sbb	dx,word ptr odExport.ddAddress+2
	jb	WriteExports2
	mov	word ptr odExport.ddSize,ax	;update data directory
	mov	word ptr odExport.ddSize+2,dx
WriteExports2:
	mov	cx,FILE_PAGE			;go to next pe file page
	call	NextOutputPage
WriteExports3:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExportDirectory:
	mov	di,ExportDir			;load export directory entry
	mov	word ptr [di.epExportFlags],0	;clear export flags
	mov	word ptr [di.epExportFlags+2],0
	mov	ax,word ptr dTimeDate		;set time/date stamp
	mov	dx,word ptr dTimeDate+2
	mov	word ptr [di.epTimeDate],ax
	mov	word ptr [di.epTimeDate+2],dx
	mov	[di.epMajorVersion],0		;clear major version number
	mov	[di.epMinorVersion],0		;clear minor version number
	mov	word ptr [di.epOrdinalBase],1	;set ordinal base
	mov	word ptr [di.epOrdinalBase+2],0
	mov	ax,PUBDEF_Index.piNext		;compute number of entries
	mov	dx,0
	mov	cx,PUBDEF_
	div	cx
	mov	dx,0
	mov	word ptr [di.epNumberOfEntries],ax	;set number of entries
	mov	word ptr [di.epNumberOfEntries+2],dx
	mov	word ptr [di.epNumberOfNames],ax	;set number of names
	mov	word ptr [di.epNumberOfNames+2],dx
	mov	cx,word ptr odExport.ddAddress	;load section base addr
	mov	bx,word ptr odExport.ddAddress+2
	add	cx,PE_EXPORT_DIR_		;set addr table pointer
	adc	bx,0
	mov	word ptr [di.epAddressTable],cx
	mov	word ptr [di.epAddressTable+2],bx
	shl	ax,1				;dword tables follow
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
	add	cx,ax				;set name pointer table pointer
	adc	bx,dx
	mov	word ptr [di.epNamePointerTable],cx
	mov	word ptr [di.epNamePointerTable+2],bx
	add	cx,ax				;set ordinal table pointer
	adc	bx,dx
	mov	word ptr [di.epOrdinalTable],cx
	mov	word ptr [di.epOrdinalTable+2],bx
	shr	dx,1				;word table follows
	rcr	ax,1
	add	cx,ax				;set module name pointer
	adc	bx,dx
	mov	word ptr [di.epModuleName],cx
	mov	word ptr [di.epModuleName+2],bx
	mov	si,ExportDir			;write export directory
	mov	cx,PE_EXPORT_DIR_
	jmp	WriteOutputBlock
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExportAddressTable:
	call	GetExportNamePointer		;get 1st symbol address
	mov	word ptr dExportNamePointer,ax
	mov	word ptr dExportNamePointer+2,dx
	mov	bx,0				;scan public index
WriteExportAddressTable1:
	cmp	bx,PUBDEF_Index.piNext		;end of index?
	mov	ax,0				;ok
	jnb	WriteExportAddressTable7
	mov	di,[PUBDEF_Index.piData.pdSymbol+bx] ;get symbol pointer
	cmp	byte ptr [di],EXPORT_ESCAPE	;skip leading export escape chr
	jnz	WriteExportAddressTable2
	inc	di
WriteExportAddressTable2:
	mov	al,FORWARD_ESCAPE		;load forward escape char
	mov	ah,FORWARD_SEPARATOR		;load forward ref separator
	mov	si,di				;save symbol address
WriteExportAddressTable3:
	mov	cx,di				;set marker
WriteExportAddressTable4:
	inc	di				;seek forward escape char
	cmp	byte ptr [di-1],0
	jz	WriteExportAddressTable5
	cmp	byte ptr [di-1],al
	jnz	WriteExportAddressTable4
	mov	byte ptr [di-1],ah		;write forward ref separator
	mov	al,0				;suppress further matches
	jmp	WriteExportAddressTable3
WriteExportAddressTable5:
	mov	ax,word ptr dExportNamePointer	;load symbol address
	mov	dx,word ptr dExportNamePointer+2
	sub	di,si				;compute symbol length
	add	word ptr dExportNamePointer,di	;set next symbol address
	adc	word ptr dExportNamePointer+2,0
	sub	cx,si				;compute forward prefix length
	jnz	WriteExportAddressTable6
	push	bx
	mov	ax,word ptr [PUBDEF_Index.piData.pdAddress+bx] ;get exp address
	mov	dx,word ptr [PUBDEF_Index.piData.pdAddress+2+bx]
	call	MapMemoryOffset
	pop	bx
WriteExportAddressTable6:
	mov	word ptr dExportAddress,ax	;save export address
	mov	word ptr dExportAddress+2,dx
	push	bx
	mov	si,offset dExportAddress	;write export address
	mov	cx,4
	call	WriteOutputBlock
	pop	bx
	jb	WriteExportAddressTable7
	add	bx,PUBDEF_			;next public address
	jmp	WriteExportAddressTable1
WriteExportAddressTable7:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExportNamePointerTable:
	call	GetExportNamePointer		;get 1st symbol address
	mov	word ptr dExportNamePointer,ax
	mov	word ptr dExportNamePointer+2,dx
	mov	bx,0				;scan public index
WriteExportNamePointerTable1:
	cmp	bx,PUBDEF_Index.piNext		;end of index?
	mov	ax,0				;ok
	jnb	WriteExportNamePointerTable6
	mov	di,[PUBDEF_Index.piData.pdSymbol+bx] ;get symbol pointer
	cmp	byte ptr [di],EXPORT_ESCAPE	;skip leading export escape chr
	jnz	WriteExportNamePointerTable2
	inc	di
WriteExportNamePointerTable2:
	mov	al,FORWARD_SEPARATOR		;load forward ref separator
	mov	si,di				;save symbol address
WriteExportNamePointerTable3:
	mov	cx,di				;set marker
WriteExportNamePointerTable4:
	inc	di				;seek forward separator
	cmp	byte ptr [di-1],0
	jz	WriteExportNamePointerTable5
	cmp	byte ptr [di-1],al
	jnz	WriteExportNamePointerTable4
	mov	al,0				;suppress further matches
	jmp	WriteExportNamePointerTable3
WriteExportNamePointerTable5:
	sub	di,cx				;compute forward symbol length
	sub	cx,si				;compute forward prefix length
	add	word ptr dExportNamePointer,cx	;set symbol address
	adc	word ptr dExportNamePointer+2,0
	push	di
	push	bx
	mov	si,offset dExportNamePointer	;write symbol address
	mov	cx,4
	call	WriteOutputBlock
	pop	bx
	pop	di
	jb	WriteExportNamePointerTable6
	add	word ptr dExportNamePointer,di	;set next symbol address
	adc	word ptr dExportNamePointer+2,0
	add	bx,PUBDEF_
	jmp	WriteExportNamePointerTable1
WriteExportNamePointerTable6:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExportOrdinalTable:
	mov	wExportOrdinal,0		;reset ordinal number
	mov	bx,0				;scan public index
WriteExportOrdinalTable1:
	cmp	bx,PUBDEF_Index.piNext		;end of index?
	mov	ax,0				;ok
	jnb	WriteExportOrdinalTable2
	push	bx
	mov	si,offset wExportOrdinal	;write ordinal number
	mov	cx,2
	call	WriteOutputBlock
	pop	bx
	jb	WriteExportOrdinalTable2
	inc	wExportOrdinal			;next ordinal number
	add	bx,PUBDEF_
	jmp	WriteExportOrdinalTable1
WriteExportOrdinalTable2:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExportModuleName:
	call	GetExportModuleName		;get export module name
	jmp	WriteOutputBlock		;write module name
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExportSymbols:
	mov	bx,0				;scan public index
WriteExportSymbols1:
	cmp	bx,PUBDEF_Index.piNext		;end of index?
	mov	ax,0				;ok
	jnb	WriteExportSymbols4
	mov	di,[PUBDEF_Index.piData.pdSymbol+bx] ;get symbol pointer
	cmp	byte ptr [di],EXPORT_ESCAPE	;skip leading export escape chr
	jnz	WriteExportSymbols2
	inc	di
WriteExportSymbols2:
	mov	si,di				;save symbol address
WriteExportSymbols3:
	inc	di				;seek end of symbol
	cmp	byte ptr [di-1],0
	jnz	WriteExportSymbols3
	sub	di,si				;compute symbol length
	mov	cx,di
	push	bx
	call	WriteOutputBlock		;write symbol
	pop	bx
	jb	WriteExportSymbols4
	add	bx,PUBDEF_			;next symbol
	jmp	WriteExportSymbols1
WriteExportSymbols4:
	ret
;
;==============================================================================
;
;	<	si  -  module name
;		cx  -  module name length
;
;------------------------------------------------------------------------------
;
GetExportModuleName:
	mov	di,OutputFile			;scan output file path
GetExportModuleName1:
	mov	si,di				;set marker
GetExportModuleName2:
	mov	al,[di]				;load character
	inc	di
	cmp	al,0				;end?
	jz	GetExportModuleName3
	cmp	al,':'				;drive separator?
	jz	GetExportModuleName1
	cmp	al,'\'				;directory separator?
	jz	GetExportModuleName1
	jmp	GetExportModuleName2
GetExportModuleName3:
	sub	di,si				;compute module name length
	mov	cx,di
	ret
;
;==============================================================================
;
;	<	dx:ax  -  1st symbol address
;
;------------------------------------------------------------------------------
;
GetExportNamePointer:
	call	GetExportModuleName		;get export module name
	mov	ax,cx				;load export module name length
	mov	dx,0
	add	ax,word ptr ExportDir.epModuleName ;compute 1st symbol address
	adc	dx,word ptr ExportDir.epModuleName+2
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteResources:
	call	SetRsrcTimeDate			;set resource time/date stamps
	mov	ax,word ptr seLinkHeader.shLoadAddress	;set sec addr in memory
	mov	dx,word ptr seLinkHeader.shLoadAddress+2
	add	ax,word ptr seLinkHeader.shLoadSize
	adc	dx,word ptr seLinkHeader.shLoadSize+2
	mov	cx,MEMORY_PAGE
	call	GetNextPage
	mov	word ptr seRsrcHeader.shLoadAddress,ax
	mov	word ptr seRsrcHeader.shLoadAddress+2,dx
	mov	word ptr odResource.ddAddress,ax	;update data directory
	mov	word ptr odResource.ddAddress+2,dx
	add	word ptr rsDataIcon.rdataAddress,ax	;update data entries
	adc	word ptr rsDataIcon.rdataAddress+2,dx
	add	word ptr rsDataGroupIcon.rdataAddress,ax
	adc	word ptr rsDataGroupIcon.rdataAddress+2,dx
	mov	ax,word ptr seLinkHeader.shRawAddress	;set sec addr in file
	mov	dx,word ptr seLinkHeader.shRawAddress+2
	add	ax,word ptr seLinkHeader.shRawSize
	adc	dx,word ptr seLinkHeader.shRawSize+2
	mov	word ptr seRsrcHeader.shRawAddress,ax
	mov	word ptr seRsrcHeader.shRawAddress+2,dx
	mov	si,RSRC_SECTION			;write .rsrc section
	mov	cx,RSRC_SECTION_
	call	WriteOutputBlock
	jb	WriteResources1
	mov	ax,wOutputOffset		;set section size in memory
	mov	dx,wOutputSegment
	sub	ax,word ptr seRsrcHeader.shRawAddress
	sbb	dx,word ptr seRsrcHeader.shRawAddress+2
	mov	word ptr seRsrcHeader.shLoadSize,ax
	mov	word ptr seRsrcHeader.shLoadSize+2,dx
	mov	word ptr odResource.ddSize,ax	;update data directory
	mov	word ptr odResource.ddSize+2,dx
	mov	cx,FILE_PAGE			;set section size in file
	call	GetNextPage
	mov	word ptr seRsrcHeader.shRawSize,ax
	mov	word ptr seRsrcHeader.shRawSize+2,dx
	add	word ptr osDataTotal,ax		;update data size total
	adc	word ptr osDataTotal+2,dx
	mov	cx,FILE_PAGE			;go to next pe file page
	call	NextOutputPage
WriteResources1:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteBaseRelocs:
	push	es
	mov	es,wFixupBuffer			;use fixup buffer
	mov	ax,word ptr seRsrcHeader.shLoadAddress	;set sec addr in memory
	mov	dx,word ptr seRsrcHeader.shLoadAddress+2
	add	ax,word ptr seRsrcHeader.shLoadSize
	adc	dx,word ptr seRsrcHeader.shLoadSize+2
	mov	cx,MEMORY_PAGE
	call	GetNextPage
	mov	word ptr seRelocHeader.shLoadAddress,ax
	mov	word ptr seRelocHeader.shLoadAddress+2,dx
	mov	word ptr odBaseReloc.ddAddress,ax	;update data directory
	mov	word ptr odBaseReloc.ddAddress+2,dx
	mov	ax,word ptr seRsrcHeader.shRawAddress	;set sec addr in file
	mov	dx,word ptr seRsrcHeader.shRawAddress+2
	add	ax,word ptr seRsrcHeader.shRawSize
	adc	dx,word ptr seRsrcHeader.shRawSize+2
	mov	word ptr seRelocHeader.shRawAddress,ax
	mov	word ptr seRelocHeader.shRawAddress+2,dx
	mov	bx,0				;evaluate base relocations
WriteBaseRelocs1:
	cmp	bx,wFixupBaseReloc		;no more entries?
	jz	WriteBaseRelocs6
	mov	si,bx				;load search pointer
	mov	ax,word ptr es:[si.brMemoryOffset] ;get destination page
	mov	dx,word ptr es:[si.brMemoryOffset+2]
	and	ax,PE_REL_MASK_PAGE
	mov	word ptr FixupBlock.fbPage,ax
	mov	word ptr FixupBlock.fbPage+2,dx
	mov	cx,0				;clear count
WriteBaseRelocs2:
	inc	cx				;count entries
	add	si,FIXUP_BASE_RELOC_		;next entry
	cmp	si,wFixupBaseReloc		;no more entries?
	jz	WriteBaseRelocs3
	mov	ax,word ptr es:[si.brMemoryOffset] ;same destination page?
	mov	dx,word ptr es:[si.brMemoryOffset+2]
	and	ax,PE_REL_MASK_PAGE
	sub	ax,word ptr FixupBlock.fbPage
	sbb	dx,word ptr FixupBlock.fbPage+2
	or	ax,dx
	jz	WriteBaseRelocs2		;seek end of page block
WriteBaseRelocs3:
	ror	cx,1				;round up to even number
	rol	cx,1
	adc	cx,0
	mov	dx,0
	adc	dx,0
	shl	cx,1				;compute fixup block size
	rcl	dx,1
	add	cx,PE_FIXUP_BLOCK_
	adc	dx,0
	mov	word ptr FixupBlock.fbSize,cx
	mov	word ptr FixupBlock.fbSize+2,dx
	push	bx
	push	si
	mov	si,offset FixupBlock		;write fixup block header
	mov	cx,PE_FIXUP_BLOCK_
	call	WriteOutputBlock
	pop	si
	pop	bx
	jb	WriteBaseRelocs7
WriteBaseRelocs4:
	cmp	bx,si				;no more entries?
	jz	WriteBaseRelocs1		;next fixup block
	mov	ax,word ptr es:[bx.brMemoryOffset] ;load fixup destination
	add	bx,FIXUP_BASE_RELOC_
	and	ax,PE_REL_MASK_OFFSET		;extract offset
	or	ax,PE_REL_HIGHLOW		;add fixup type
	mov	word ptr dFixupBlockEntries,ax	;save entry #1
	cmp	bx,si				;no more entries?
	mov	ax,PE_REL_ABSOLUTE		;pad fixup block
	jz	WriteBaseRelocs5
	mov	ax,word ptr es:[bx.brMemoryOffset] ;load fixup destination
	add	bx,FIXUP_BASE_RELOC_
	and	ax,PE_REL_MASK_OFFSET		;extract offset
	or	ax,PE_REL_HIGHLOW		;add fixup type
WriteBaseRelocs5:
	mov	word ptr dFixupBlockEntries+2,ax;save entry #2
	push	bx
	push	si
	mov	si,offset dFixupBlockEntries	;write 2 fixup block entries
	mov	cx,4
	call	WriteOutputBlock
	pop	si
	pop	bx
	jb	WriteBaseRelocs7
	jmp	WriteBaseRelocs4		;next fixup block entry
WriteBaseRelocs6:
	mov	ax,wOutputOffset		;set section size in memory
	mov	dx,wOutputSegment
	sub	ax,word ptr seRelocHeader.shRawAddress
	sbb	dx,word ptr seRelocHeader.shRawAddress+2
	mov	word ptr seRelocHeader.shLoadSize,ax
	mov	word ptr seRelocHeader.shLoadSize+2,dx
	mov	word ptr odBaseReloc.ddSize,ax	;update data directory
	mov	word ptr odBaseReloc.ddSize+2,dx
	mov	cx,FILE_PAGE			;set section size in file
	call	GetNextPage
	mov	word ptr seRelocHeader.shRawSize,ax
	mov	word ptr seRelocHeader.shRawSize+2,dx
	add	word ptr osDataTotal,ax		;update data size total
	adc	word ptr osDataTotal+2,dx
	mov	cx,FILE_PAGE			;go to next pe file page
	call	NextOutputPage
WriteBaseRelocs7:
	pop	es
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteExternals:
	push	es
	mov	es,wFixupBuffer			;use fixup buffer
	mov	bx,wFixupExternal		;evaluate externals
WriteExternals1:
	cmp	bx,0
	jz	WriteExternals2
	push	bx
	mov	ax,word ptr es:[bx.exFileOffset];go to fixup destination
	mov	dx,word ptr es:[bx.exFileOffset+2]
	call	SetOutputPointer
	pop	bx
	jb	WriteExternals3
	push	bx
	mov	bx,es:[bx.exExternal]		;write external address
	lea	si,[EXTDEF_Index.eiData.edAddress+bx]
	mov	cx,4
	call	WriteOutputBlock
	pop	bx
	jb	WriteExternals3
	add	bx,FIXUP_EXTERNAL_		;next external
	jmp	WriteExternals1
WriteExternals2:
	mov	ax,0				;ok
	clc
WriteExternals3:
	pop	es
	ret
;
;==============================================================================
;
;	WIN32 SYMBOL MANAGEMENT
;
;==============================================================================
;
;	<	c  -  set if error
;
;------------------------------------------------------------------------------
;
LoadWin32Symbols:
	call	BackupInput			;backup input status
	mov	bx,offset sSymbolExtension	;get symbol file path
	mov	si,ProgramFile
	mov	di,SymbolFile
	mov	cx,SymbolFile_
	call	GetDataFile
	jb	LoadWin32Symbols14
	cmp	bDumpSymbolFileName,0		;symbol file name dump enabled?
	jz	LoadWin32Symbols1
	mov	bx,offset sDumpSymbolFileName	;display symbol file name
	mov	si,SymbolFile
	call	OutputQuotedMessage
LoadWin32Symbols1:
	mov	si,SymbolFile			;open symbol file
	call	OpenInput
	jb	LoadWin32Symbols14
	push	es
	mov	es,wWin32Symbols		;use symbol buffer
	mov	cx,-1				;section name undefined
LoadWin32Symbols2:
	push	cx
	call	ReadInputLine			;read line
	pop	cx
	cmc
	jnb	LoadWin32Symbols13		;end of file
	dec	si
	mov	bx,wWin32Index			;load index pointer
	mov	di,wWin32Names			;load name pointer
LoadWin32Symbols3:
	inc	si				;skip leading spaces
	cmp	byte ptr [si],' '
	jz	LoadWin32Symbols3
	cmp	byte ptr [si],0			;empty line?
	jz	LoadWin32Symbols12
	cmp	byte ptr [si],';'		;comment?
	jz	LoadWin32Symbols12
	cmp	byte ptr [si],'['		;section header?
	jnz	LoadWin32Symbols5
	inc	si
	mov	cx,di				;save section name pointer
LoadWin32Symbols4:
	mov	al,[si]				;copy section name
	inc	si
	mov	es:[di],al
	inc	di
	stc					;buffer overflow?
	jz	LoadWin32Symbols13
	cmp	al,1				;unexpected end of line?
	jb	LoadWin32Symbols13
	cmp	al,']'				;end of section header?
	jnz	LoadWin32Symbols4
	mov	byte ptr es:[di-1],0		;terminate string
	jmp	LoadWin32Symbols12		;next line
LoadWin32Symbols5:
	cmp	cx,-1				;section name defined?
	jz	LoadWin32Symbols12
	mov	dx,di				;save api name pointer
LoadWin32Symbols6:
	mov	al,[si]				;copy api name
	inc	si
	mov	es:[di],al
	inc	di
	stc					;buffer overflow?
	jz	LoadWin32Symbols13
	cmp	al,1				;unexpected end of line?
	jb	LoadWin32Symbols13
	cmp	al,' '				;end of api name?
	jz	LoadWin32Symbols7
	cmp	al,'='				;separator?
	jz	LoadWin32Symbols8
	jmp	LoadWin32Symbols6
LoadWin32Symbols7:
	inc	si				;skip trailing spaces
	cmp	byte ptr [si],' '
	jz	LoadWin32Symbols7
	cmp	byte ptr [si],'='		;separator?
	stc
	jnz	LoadWin32Symbols13
	inc	si				;skip separator
LoadWin32Symbols8:
	mov	byte ptr es:[di-1],0		;terminate string
	dec	bx				;allocate control block
	sub	bx,WIN32_INDEX_
	inc	bx
	jb	LoadWin32Symbols13
	cmp	bx,di				;buffer overflow?
	jb	LoadWin32Symbols13
	mov	es:[bx.wiModule],cx		;save section name pointer
	mov	es:[bx.wiSymbol],dx		;save api name pointer
	dec	si
LoadWin32Symbols9:
	inc	si				;skip leading spaces
	cmp	byte ptr [si],' '
	jz	LoadWin32Symbols9
	cmp	byte ptr [si],'0'		;at least one digit required
	jb	LoadWin32Symbols13
	cmp	byte ptr [si],'9'+1
	cmc
	jb	LoadWin32Symbols13
	mov	ax,0				;clear destination
LoadWin32Symbols10:
	cmp	byte ptr [si],0			;end of line?
	jz	LoadWin32Symbols11
	cmp	byte ptr [si],' '		;end of number?
	jz	LoadWin32Symbols11
	cmp	byte ptr [si],','		;end of field?
	jz	LoadWin32Symbols11
	cmp	byte ptr [si],';'		;comment?
	jz	LoadWin32Symbols11
	sub	byte ptr [si],'0'		;valid decimal digit?
	jb	LoadWin32Symbols13
	cmp	byte ptr [si],10
	cmc
	jb	LoadWin32Symbols13
	mov	dx,10				;last result * 10
	mul	dx
	add	dx,-1
	jb	LoadWin32Symbols13
	add	al,byte ptr [si]		;add new digit
	adc	ah,0
	jb	LoadWin32Symbols13
	inc	si				;next digit
	jmp	LoadWin32Symbols10
LoadWin32Symbols11:
	mov	es:[bx.wiOrdinal],ax		;save ordinal number
LoadWin32Symbols12:
	mov	wWin32Index,bx			;save index pointer
	mov	wWin32Names,di			;save name pointer
	jmp	LoadWin32Symbols2		;next line
LoadWin32Symbols13:
	pop	es
	pushf
	call	CloseInput			;close symbol file
	popf
LoadWin32Symbols14:
	pushf
	call	RestoreInput			;restore input status
	popf
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
SortWin32Symbols:
	push	es
	mov	es,wWin32Symbols		;use symbol buffer
	mov	ax,0				;compute number of entries
	sub	ax,wWin32Index
	mov	dx,0
	mov	cx,WIN32_INDEX_
	div	cx
	cmp	ax,2				;sort data available?
	jb	SortWin32Symbols6
	mov	cx,ax				;save number of entries
SortWin32Symbols1:
	mov	dx,ax				;multiply distance by 3/4
	mov	bx,0
	shl	ax,1				;* 3
	rcl	bx,1
	add	ax,dx
	adc	bx,0
	shr	bx,1				;/ 4
	rcr	ax,1
	shr	bx,1
	rcr	ax,1
	sub	ax,1				;minimum = 1
	adc	ax,1
	push	ax
	push	cx
	sub	cx,ax				;compute loop count
	mov	dx,WIN32_INDEX_			;compute entry offset
	mul	dx
	mov	bx,wWin32Index			;init sort pointers
	mov	dx,bx
	add	dx,ax
	mov	ah,0				;clear transposition flag
SortWin32Symbols2:
	mov	si,es:[bx.wiSymbol]		;compare symbols
	xchg	dx,bx
	mov	di,es:[bx.wiSymbol]
	xchg	dx,bx
SortWin32Symbols3:
	mov	al,es:[si]			;compare characters
	cmp	al,es:[di]
	ja	SortWin32Symbols4		;exchange entries
	jb	SortWin32Symbols5		;ok
	or	al,es:[di]			;end of both symbols?
	jz	SortWin32Symbols5		;ok
	inc	si				;next character
	inc	di
	jmp	SortWin32Symbols3
SortWin32Symbols4:
	mov	di,dx
	mov	si,es:[bx.wiModule]		;exchange module name pointers
	xchg	si,es:[di.wiModule]
	mov	es:[bx.wiModule],si
	mov	si,es:[bx.wiSymbol]		;exchange symbol pointers
	xchg	si,es:[di.wiSymbol]
	mov	es:[bx.wiSymbol],si
	mov	si,es:[bx.wiOrdinal]		;exchange ordinal numbers
	xchg	si,es:[di.wiOrdinal]
	mov	es:[bx.wiOrdinal],si
	mov	ah,1				;set transposition flag
SortWin32Symbols5:
	add	bx,WIN32_INDEX_			;next entry pair
	add	dx,WIN32_INDEX_
	loop	SortWin32Symbols2
	mov	dh,ah				;save transposition flag
	pop	cx
	pop	ax
	cmp	ax,1				;minimum distance reached?
	ja	SortWin32Symbols1
	cmp	dh,0				;any transpositions?
	jnz	SortWin32Symbols1
SortWin32Symbols6:
	pop	es
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
DumpWin32Symbols:
	mov	si,offset sDumpWin32Symbols	;display header
	call	OutputString
	mov	bx,wWin32Index			;load win32 index base
	cmp	bx,0				;no data?
	jz	DumpWin32Symbols2
DumpWin32Symbols1:
	push	es
	mov	es,wWin32Symbols		;use symbol buffer
	mov	si,es:[bx.wiSymbol]		;load symbol pointer
	mov	ax,es:[bx.wiOrdinal]		;load ordinal number
	mov	dx,es:[bx.wiModule]		;load module name pointer
	pop	es
	push	bx
	push	dx
	push	ax
	mov	di,StringBuffer			;copy symbol
	mov	cx,StringBuffer_
	call	CopyWin32String
	mov	si,StringBuffer			;display symbol
	call	OutputString
	mov	al,'='				;separator
	call	OutputChar
	pop	ax
	call	DumpHexWord			;display ordinal number
	mov	al,','				;separator
	call	OutputChar
	pop	dx
	mov	si,dx				;copy module name
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	CopyWin32String
	mov	si,StringBuffer			;display module name
	call	OutputQuotedString
	mov	si,offset sNewLine		;new line
	call	OutputString
	pop	bx
	add	bx,WIN32_INDEX_			;next entry
	jnb	DumpWin32Symbols1
DumpWin32Symbols2:
	mov	si,offset sNewLine		;new line
	jmp	OutputString
;
;==============================================================================
;
;	>	si  -  user symbol
;
;	<	dx  -  module name (relative to symbol buffer)
;		si  -  system symbol (relative to symbol buffer)
;		ax  -  ordinal number
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
FindWin32Symbol:
	push	es
	mov	es,wWin32Symbols		;use symbol buffer
	mov	bx,wWin32Index			;load win32 index base
	cmp	bx,1				;no data?
	jb	FindWin32Symbol8
	mov	cx,si				;save symbol address
	mov	dx,0				;reset marker
FindWin32Symbol1:
	mov	si,cx				;load test symbol pointer
	mov	di,es:[bx.wiSymbol]		;load sample symbol pointer
FindWin32Symbol2:
	mov	al,[si]				;load test symbol character
	inc	si
	mov	ah,es:[di]			;load sample symbol character
	inc	di
	cmp	al,0				;end of test symbol?
	jnz	FindWin32Symbol4
	cmp	ah,0				;end of sample symbol?
	jnz	FindWin32Symbol3
	mov	dx,bx				;set marker
FindWin32Symbol3:
	cmp	bApiSuffix,ah			;api suffix ok?
	jb	FindWin32Symbol6		;symbol not found
	ja	FindWin32Symbol5		;try next symbol
	cmp	byte ptr es:[di],0		;end of sample symbol?
	jz	FindWin32Symbol7		;ok
	jmp	FindWin32Symbol6
FindWin32Symbol4:
	cmp	al,ah				;compare characters
	jz	FindWin32Symbol2		;next character
	jb	FindWin32Symbol6		;symbol not found
FindWin32Symbol5:
	add	bx,WIN32_INDEX_			;next entry
	jb	FindWin32Symbol6
	jmp	FindWin32Symbol1
FindWin32Symbol6:
	mov	bx,dx				;load marker
	cmp	bx,1				;previous match?
	jb	FindWin32Symbol8		;symbol not found
FindWin32Symbol7:
	mov	dx,es:[bx.wiModule]		;load module name pointer
	mov	si,es:[bx.wiSymbol]		;load symbol pointer
	mov	ax,es:[bx.wiOrdinal]		;load ordinal number
	clc					;ok
FindWin32Symbol8:
	pop	es
	ret
;
;==============================================================================
;
;	>	si  -  string offset (relative to symbol buffer)
;		di  -  buffer
;		cx  -  buffer size
;
;	<	cx  -  string length
;
;------------------------------------------------------------------------------
;
CopyWin32String:
	push	es
	mov	es,wWin32Symbols		;use symbol buffer
	mov	dx,si				;save string offset
CopyWin32String1:
	mov	al,es:[si]			;load character
	inc	si
	jcxz	CopyWin32String2		;buffer full
	mov	[di],al				;save character
	inc	di
	dec	cx
CopyWin32String2:
	cmp	al,0				;end of string?
	jnz	CopyWin32String1		;next character
	mov	byte ptr [di-1],0		;terminate string
	mov	cx,si				;compute string length
	dec	cx
	sub	cx,dx
	pop	es
	ret
;
;==============================================================================
;
;	>	si  -  string offset (relative to symbol buffer)
;
;	<	cx  -  string length
;
;------------------------------------------------------------------------------
;
GetWin32StringLength:
	push	es
	mov	es,wWin32Symbols		;use symbol buffer
	mov	dx,si				;save string offset
GetWin32StringLength1:
	inc	si				;search for string terminator
	cmp	byte ptr es:[si-1],0
	jnz	GetWin32StringLength1
	mov	cx,si				;compute string length
	dec	cx
	sub	cx,dx
	pop	es
	ret
;
;==============================================================================
;
;	FILE INPUT
;
;==============================================================================
;
;	>	si  -  path
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
TestFile:
	call	OpenInput			;open file
	jb	TestFile1			;error
	push	ax
	call	CloseInput			;close file
	pop	ax
	clc					;ok
TestFile1:
	ret
;
;==============================================================================
;
;	>	si  -  path
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
OpenInput:
	mov	word ptr dInputBlockOffset,0	;clear data block offset
	mov	word ptr dInputBlockOffset+2,0
	mov	wInputBlockPointer,0		;clear data block pointer
	mov	wInputBlockEnd,0		;clear data block end pointer
	mov	dx,si				;open file
	mov	al,OF_READ+OF_SHARE_DENY_NONE
	mov	ah,DOS_OPEN
	int	DOS
	mov	hInput,ax			;save file handle
	jnb	OpenInput1			;ok
	mov	hInput,0			;clear file handle
OpenInput1:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
CloseInput:
	mov	word ptr dInputBlockOffset,0	;clear data block offset
	mov	word ptr dInputBlockOffset+2,0
	mov	wInputBlockPointer,0		;clear data block pointer
	mov	wInputBlockEnd,0		;clear data block end pointer
	mov	ax,hInput			;file opened?
	cmp	ax,1
	jb	CloseInput1			;error
	mov	bx,ax				;close file
	mov	ah,DOS_CLOSE
	int	DOS
	mov	hInput,0			;clear file handle
CloseInput1:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  file pointer
;
;	<	   ax  -  return code
;		    c  -  set if error
;
;------------------------------------------------------------------------------
;
SetInputPointer:
	mov	di,word ptr dInputBlockOffset	;load data block offset
	mov	si,word ptr dInputBlockOffset+2
	mov	cx,ax				;file pointer above buffer?
	mov	bx,dx
	sub	cx,di
	sbb	bx,si
	jnb	SetInputPointer1
	sub	di,wInputBlockEnd		;compute buffer start offset
	sbb	si,0
	add	di,FileBuffer
	adc	si,0
	mov	cx,ax				;file pointer below buffer?
	mov	bx,dx
	sub	cx,di
	sbb	bx,si
	jb	SetInputPointer1
	add	cx,FileBuffer			;set data block pointer only
	mov	wInputBlockPointer,cx
	mov	ax,-1				;ok
	clc
	jmp	SetInputPointer2
SetInputPointer1:
	mov	word ptr dInputBlockOffset,ax	;save data block offset
	mov	word ptr dInputBlockOffset+2,dx
	mov	wInputBlockPointer,0		;clear data block pointer
	mov	wInputBlockEnd,0		;clear data block end pointer
	mov	ax,hInput			;file opened?
	cmp	ax,1
	jb	SetInputPointer2		;error
	mov	bx,ax				;set file pointer
	mov	dx,word ptr dInputBlockOffset
	mov	cx,word ptr dInputBlockOffset+2
	mov	al,0
	mov	ah,DOS_MOVEPOINTER
	int	DOS
SetInputPointer2:
	ret
;
;==============================================================================
;
;	<	dx:ax  -  file pointer
;
;------------------------------------------------------------------------------
;
GetInputPointer:
	mov	ax,word ptr dInputBlockOffset	;load data block offset
	mov	dx,word ptr dInputBlockOffset+2
	sub	ax,wInputBlockEnd		;consider buffer pointer
	sbb	dx,0
	add	ax,wInputBlockPointer
	adc	dx,0
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
ReadInput:
	mov	wInputBlockPointer,FileBuffer	;init data block pointer
	mov	wInputBlockEnd,FileBuffer	;init data block end pointer
	mov	ax,hInput			;file opened?
	cmp	ax,1
	jb	ReadInput1			;error
	mov	bx,ax				;read data block
	mov	cx,FileBuffer_
	mov	dx,FileBuffer
	mov	ah,DOS_READ
	int	DOS
	jb	ReadInput1			;error
	add	word ptr dInputBlockOffset,ax	;compute data block offset
	adc	word ptr dInputBlockOffset+2,0
	add	wInputBlockEnd,ax		;set data block end pointer
	clc					;ok
ReadInput1:
	ret
;
;==============================================================================
;
;	>	di  -  buffer
;		cx  -  buffer size
;
;	<	 c  -  set if end of file
;
;------------------------------------------------------------------------------
;
ReadInputBlock:
	push	di
	push	cx
	call	ReadInputByte			;read byte from input file
	pop	cx
	pop	di
	jb	ReadInputBlock1			;end of file
	mov	[di],al				;save byte
	inc	di
	loop	ReadInputBlock			;count bytes
ReadInputBlock1:
	ret
;
;==============================================================================
;
;	<	al  -  0 if checksum ok
;		 c  -  set if end of file
;
;------------------------------------------------------------------------------
;
ReadInputRecord:
	mov	di,0				;load data offset
	mov	cx,wRecordLength		;load number of bytes
	mov	dl,bRecordType			;initialize checksum
	add	dl,cl
	add	dl,ch
	mov	al,0				;zero length record
	clc
	jcxz	ReadInputRecord2
ReadInputRecord1:
	call	ReadInputByte			;read byte from input file
	pushf
	add	dl,al				;compute checksum
	mov	es:[di],al			;save byte
	inc	di
	popf
	loop	ReadInputRecord1		;count bytes
ReadInputRecord2:
	pushf
	add	dl,-1				;evaluate checksum
	sbb	dl,dl
	and	al,dl
	popf
	ret
;
;==============================================================================
;
;	<	si  -  data
;		 c  -  set if end of file
;
;------------------------------------------------------------------------------
;
ReadInputLine:
	mov	di,LineBuffer			;load buffer address
	mov	cx,LineBuffer_			;load buffer length
	mov	si,di				;save buffer address
ReadInputLine1:
	call	ReadInputByte			;read character
	jb	ReadInputLine3			;end of file (c)
	cmp	al,EOF				;ascii eof character?
	stc
	jz	ReadInputLine3			;(c)
	cmp	al,LF				;end of line?
	jz	ReadInputLine3			;(nc)
	cmp	al,CR				;end of line?
	jz	ReadInputLine2
	dec	cx				;buffer space available?
	jz	ReadInputLine2
	mov	[di],al				;save character
	inc	di
	jmp	ReadInputLine1			;next character
ReadInputLine2:
	call	ReadInputByte			;search for end of line
	jb	ReadInputLine3			;end of file (c)
	cmp	al,LF				;end of line?
	jnz	ReadInputLine2			;nc if yes
ReadInputLine3:
	sbb	al,al				;evaluate cy (-1 = end of file)
	mov	byte ptr [di],0			;terminate line
	cmp	di,si				;blank line? (clear cy)
	jnz	ReadInputLine4			;nc = ok
	add	al,1				;c = end of file
ReadInputLine4:
	ret
;
;==============================================================================
;
;	<	ax  -  file word
;		 c  -  set if end of file
;
;	cx, si, di not changed
;
;------------------------------------------------------------------------------
;
ReadInputWord:
	call	ReadInputByte			;read low byte
	mov	dl,al
	call	ReadInputByte			;read high byte
	mov	dh,al
	mov	ax,dx				;load file word
	ret
;
;==============================================================================
;
;	<	al  -  file byte (0 if end of file)
;		 c  -  set if end of file
;
;	cx, dx, si, di not changed
;
;------------------------------------------------------------------------------
;
ReadInputByte:
	mov	bx,wInputBlockPointer		;load data block pointer
	cmp	wInputBlockEnd,bx		;end of data block?
	jz	ReadInputByte1			;load next data block
	mov	al,[bx]				;load file byte
	inc	wInputBlockPointer		;advance data block pointer
	ret					;nc = ok
ReadInputByte1:
	cmp	wInputBlockEnd,FileBuffer	;file buffer empty?
	stc
	jz	ReadInputByte2
	push	cx
	push	dx
	push	si
	push	di
	call	ReadInput			;load next data block
	pop	di
	pop	si
	pop	dx
	pop	cx
	jb	ReadInputByte2			;error
	cmp	wInputBlockEnd,FileBuffer+1	;end of file?
	jnb	ReadInputByte
ReadInputByte2:
	mov	al,0				;return 0 if end of file
	ret					;c = end of file
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
BackupInput:
	push	es
	mov	es,wInputBackup			;use input backup buffer
	mov	di,0
	mov	si,InputParameters		;backup parameter area
	mov	cx,InputParameters_
BackupInput1:
	mov	al,[si]
	inc	si
	mov	es:[di],al
	inc	di
	loop	BackupInput1
	mov	si,FileBuffer			;backup file buffer data
	mov	cx,FileBuffer_
BackupInput2:
	mov	al,[si]
	inc	si
	mov	es:[di],al
	inc	di
	loop	BackupInput2
	pop	es
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
RestoreInput:
	push	es
	mov	es,wInputBackup			;use input backup buffer
	mov	si,0
	mov	di,InputParameters		;restore parameter area
	mov	cx,InputParameters_
RestoreInput1:
	mov	al,es:[si]
	inc	si
	mov	[di],al
	inc	di
	loop	RestoreInput1
	mov	di,FileBuffer			;restore file buffer data
	mov	cx,FileBuffer_
RestoreInput2:
	mov	al,es:[si]
	inc	si
	mov	[di],al
	inc	di
	loop	RestoreInput2
	pop	es
	ret
;
;==============================================================================
;
;	FILE OUTPUT
;
;==============================================================================
;
;	<	c  -  set if error
;
;------------------------------------------------------------------------------
;
CreateOutputFile:
	mov	bx,offset sOutputExtension	;get output file path
	mov	si,InputFile
	mov	di,OutputFile
	mov	cx,OutputFile_
	call	GetDataFile
	jb	CreateOutputFile2
	cmp	bDumpOutputFileName,0		;output file name dump enabled?
	jz	CreateOutputFile1
	mov	bx,offset sDumpOutputFileName	;display output file name
	mov	si,OutputFile
	call	OutputQuotedMessage
CreateOutputFile1:
	mov	si,OutputFile			;create output file
	call	CreateOutput
CreateOutputFile2:
	ret
;
;==============================================================================
;
;	>	si  -  path
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
CreateOutput:
	mov	wOutputOffset,0			;clear output offset
	mov	wOutputSegment,0		;clear output segment number
	mov	word ptr dOutputSize,0		;reset output size
	mov	word ptr dOutputSize+2,0
	push	si
	mov	dx,si				;create file
	mov	cx,0
	mov	ah,DOS_CREATE
	int	DOS
	pop	si
	jb	CreateOutput1			;error
	push	si
	mov	bx,ax				;close file
	mov	ah,DOS_CLOSE
	int	DOS
	pop	si
	jb	CreateOutput1			;error
	mov	dx,si				;open file
	mov	al,OF_READWRITE+OF_SHARE_DENY_WRITE
	mov	ah,DOS_OPEN
	int	DOS
	mov	hOutput,ax			;save file handle
	jnb	CreateOutput2			;ok
CreateOutput1:
	mov	hOutput,0			;clear file handle
CreateOutput2:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
CloseOutput:
	cmp	hOutput,0			;output file open?
	mov	ax,0
	clc
	jz	CloseOutput1
	mov	dx,wOutputSegment		;commit current segment
	call	WriteOutputSegment
	pushf
	push	ax
	mov	bx,hOutput			;close file
	mov	ah,DOS_CLOSE
	int	DOS
	mov	hOutput,0			;clear file handle
	sbb	cx,cx				;evaluate carry
	mov	dx,ax				;save return code
	pop	ax
	popf
	jb	CloseOutput1			;error committing segment
	mov	ax,dx				;load return code
	add	cx,1				;error closing file?
CloseOutput1:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  file pointer
;
;	<	   ax  -  return code
;		    c  -  set if error
;
;------------------------------------------------------------------------------
;
SetOutputPointer:
	mov	di,word ptr dOutputSize		;pointer beyond end of file?
	mov	si,word ptr dOutputSize+2
	sub	di,ax
	sbb	si,dx
	jnb	SetOutputPointer1
	mov	ax,word ptr dOutputSize		;go to end of file
	mov	dx,word ptr dOutputSize+2
SetOutputPointer1:
	sbb	cx,cx				;evaluate carry
	mov	wOutputOffset,ax		;save new file pointer
	xchg	wOutputSegment,dx
	cmp	wOutputSegment,dx		;output segment changed?
	jz	SetOutputPointer2
	push	cx
	push	si
	push	di
	call	WriteOutputSegment		;swap out current segment
	pop	di
	pop	si
	pop	cx
	jb	SetOutputPointer6		;error
	mov	dx,wOutputSegment
	push	cx
	push	si
	push	di
	call	ReadOutputSegment		;swap in new segment
	pop	di
	pop	si
	pop	cx
	jb	SetOutputPointer6		;error
SetOutputPointer2:
	jcxz	SetOutputPointer5		;pointer not beyond end of file
SetOutputPointer3:
	inc	si				;count 64k blocks
	mov	cx,0
	jnz	SetOutputPointer4
	sub	cx,di				;last (partial) block
SetOutputPointer4:
	push	si
	push	di
	call	FillOutputBlock			;append fill data
	pop	di
	pop	si
	jb	SetOutputPointer6		;error
	cmp	si,0				;more 64k blocks?
	jnz	SetOutputPointer3
SetOutputPointer5:
	mov	ax,0				;load return code
	clc					;ok
SetOutputPointer6:
	ret
;
;==============================================================================
;
;	>	si  -  data block
;		cx  -  data block size (0 = 64k)
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteOutputBlock:
	push	es
	mov	es,wOutputBuffer		;destination = output buffer
	mov	di,wOutputOffset		;load current offset
WriteOutputBlock1:
	mov	al,[si]				;copy byte
	inc	si
	mov	es:[di],al
	inc	di
	jnz	WriteOutputBlock3
	mov	dx,wOutputSegment		;current = last segment?
	cmp	dx,word ptr dOutputSize+2
	jnz	WriteOutputBlock2
	mov	word ptr dOutputSize,0		;update file size
	inc	word ptr dOutputSize+2
WriteOutputBlock2:
	push	cx
	push	si
	push	di
	call	WriteOutputSegment		;swap out current segment
	pop	di
	pop	si
	pop	cx
	jb	WriteOutputBlock5		;error
	inc	wOutputSegment			;update segment number
	mov	dx,wOutputSegment
	push	cx
	push	si
	push	di
	call	ReadOutputSegment		;swap in next segment
	pop	di
	pop	si
	pop	cx
	jb	WriteOutputBlock5		;error
WriteOutputBlock3:
	loop	WriteOutputBlock1		;next byte
	mov	dx,wOutputSegment		;current = last segment?
	cmp	dx,word ptr dOutputSize+2
	jnz	WriteOutputBlock4
	cmp	di,word ptr dOutputSize		;file size increased?
	jna	WriteOutputBlock4
	mov	word ptr dOutputSize,di		;update file size
WriteOutputBlock4:
	mov	wOutputOffset,di		;update current offset
	mov	ax,0				;load return code
	clc					;ok
WriteOutputBlock5:
	pop	es
	ret
;
;==============================================================================
;
;	>	cx  -  data block size
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
FillOutputBlock:
	push	es
	mov	es,wOutputBuffer		;destination = output buffer
	mov	di,wOutputOffset		;load current offset
FillOutputBlock1:
	mov	byte ptr es:[di],PAGE_FILL	;write fill byte
	inc	di
	jnz	FillOutputBlock3
	mov	dx,wOutputSegment		;current = last segment?
	cmp	dx,word ptr dOutputSize+2
	jnz	FillOutputBlock2
	mov	word ptr dOutputSize,0		;update file size
	inc	word ptr dOutputSize+2
FillOutputBlock2:
	push	cx
	push	di
	call	WriteOutputSegment		;swap out current segment
	pop	di
	pop	cx
	jb	FillOutputBlock5		;error
	inc	wOutputSegment			;update segment number
	mov	dx,wOutputSegment
	push	cx
	push	di
	call	ReadOutputSegment		;swap in next segment
	pop	di
	pop	cx
	jb	FillOutputBlock5		;error
FillOutputBlock3:
	loop	FillOutputBlock1		;next byte
	mov	dx,wOutputSegment		;current = last segment?
	cmp	dx,word ptr dOutputSize+2
	jnz	FillOutputBlock4
	cmp	di,word ptr dOutputSize		;file size increased?
	jna	FillOutputBlock4
	mov	word ptr dOutputSize,di		;update file size
FillOutputBlock4:
	mov	wOutputOffset,di		;update current offset
	mov	ax,0				;load return code
	clc					;ok
FillOutputBlock5:
	pop	es
	ret
;
;==============================================================================
;
;	>	cx  -  page size
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
NextOutputPage:
	push	cx
	mov	ax,wOutputOffset		;compute offset in page
	mov	dx,wOutputSegment
	mov	bx,cx
	call	Divide
	pop	cx
	cmp	bx,0				;page complete?
	mov	ax,0
	clc
	jz	NextOutputPage1
	sub	cx,bx				;compute # of missing bytes
	call	FillOutputBlock			;fill remainder of current page
NextOutputPage1:
	ret
;
;==============================================================================
;
;	>	dx  -  segment number
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
ReadOutputSegment:
	mov	ah,DOS_READ			;read output segment
	jmp	CopyOutputSegment
;
;==============================================================================
;
;	>	dx  -  segment number
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
WriteOutputSegment:
	mov	ah,DOS_WRITE			;write output segment
	jmp	CopyOutputSegment
;
;==============================================================================
;
;	>	dx  -  segment number
;		ah  -  copy mode
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
CopyOutputSegment:
	mov	bOutputMode,ah			;save copy mode
	push	dx
	mov	bx,hOutput			;set file pointer
	mov	cx,dx
	mov	dx,0
	mov	al,0
	mov	ah,DOS_MOVEPOINTER
	int	DOS
	pop	dx
	jb	CopyOutputSegment6		;i/o error
	cmp	dx,word ptr dOutputSize+2	;current = last segment?
	mov	di,word ptr dOutputSize		;copy partial segment
	mov	si,0
	jz	CopyOutputSegment1
	mov	di,0				;copy full segment
	mov	si,1
CopyOutputSegment1:
	mov	dx,0				;load 1st output block address
CopyOutputSegment2:
	mov	cx,OUTPUT_BLOCK			;load output block size
	sub	di,cx				;count down bytes
	sbb	si,0
	jnb	CopyOutputSegment3		;copy full block
	add	cx,di				;copy partial block
	clc					;nothing to copy
	jz	CopyOutputSegment5
	mov	di,0				;last block
	mov	si,0
CopyOutputSegment3:
	push	si
	push	di
	push	cx
	push	dx
	mov	bx,hOutput			;copy block
	mov	ah,bOutputMode
	push	ds
	mov	ds,wOutputBuffer
	int	DOS
	pop	ds
	pop	dx
	pop	cx
	pop	di
	pop	si
	jb	CopyOutputSegment6		;i/o error
	add	dx,cx				;next output block address
CopyOutputSegment4:
	sub	ax,cx				;test number of bytes copied
	add	ax,-1
	jnb	CopyOutputSegment2		;next output block address
CopyOutputSegment5:
	mov	ax,0				;load return code
CopyOutputSegment6:
	ret
;
;==============================================================================
;
;	DISPLAY CONTROL
;
;==============================================================================
;
;	>	al  -  binary number
;
;------------------------------------------------------------------------------
;
DumpHexByte:
	mov	cx,2				;dump 2 hex digits
	jmp	DumpHexNumber
;
;==============================================================================
;
;	>	ax  -  binary number
;
;------------------------------------------------------------------------------
;
DumpHexWord:
	mov	cx,4				;dump 4 hex digits
	jmp	DumpHexNumber
;
;==============================================================================
;
;	>	dx:ax  -  binary number
;
;------------------------------------------------------------------------------
;
DumpHexDouble:
	mov	cx,8				;dump 8 hex digits
	jmp	DumpHexNumber
;
;==============================================================================
;
;	>	dx:ax  -  binary number
;		   cx  -  number of significant digits
;
;------------------------------------------------------------------------------
;
DumpHexNumber:
	mov	di,HexBuffer			;load hex number buffer
	add	di,cx				;go to end
	mov	byte ptr [di],0			;terminate string
DumpHexNumber1:
	mov	bl,al				;load next digit
	shr	dx,1				;divide by 16
	rcr	ax,1
	shr	dx,1
	rcr	ax,1
	shr	dx,1
	rcr	ax,1
	shr	dx,1
	rcr	ax,1
	and	bl,00001111b			;mask nibble
	cmp	bl,10				;range 0..9?
	mov	bh,'0'
	jb	DumpHexNumber2
	mov	bh,'A'-10			;range A..F
DumpHexNumber2:
	add	bl,bh				;convert to character
	dec	di				;save digit
	mov	[di],bl
	loop	DumpHexNumber1			;next digit
	mov	si,di				;display hex number
	jmp	OutputString
;
;==============================================================================
;
;	>	ax  -  fraction
;		bx  -  total
;
;------------------------------------------------------------------------------
;
DisplayPercent:
	mov	cx,100				;compute percent
	mul	cx
	div	bx
	add	dx,-1				;round up
	adc	ax,0
	mov	dx,0				;display hundreds
	mov	cx,100
	div	cx
	add	al,'0'
	cmp	al,'0'
	jnz	DisplayPercent1
	mov	al,' '
DisplayPercent1:
	push	dx
	push	ax
	call	OutputChar
	pop	bx
	pop	ax
	mov	dx,0				;display tens
	mov	cx,10
	div	cx
	add	al,'0'
	cmp	bl,' '
	jnz	DisplayPercent2
	cmp	al,'0'
	jnz	DisplayPercent2
	mov	al,' '
DisplayPercent2:
	push	dx
	call	OutputChar
	pop	ax
	add	al,'0'				;display ones
	jmp	OutputChar
;
;==============================================================================
;
;	>	si  -  section name
;
;------------------------------------------------------------------------------
;
DisplaySectionName:
	push	si
	mov	si,offset sBeginText		;begin text
	call	OutputString
	pop	si
	mov	cx,SNL				;maximum length
DisplaySectionName1:
	mov	al,[si]				;load character
	inc	si
	cmp	al,0				;end of name?
	jz	DisplaySectionName2
	push	si
	push	cx
	call	OutputChar			;display character
	pop	cx
	pop	si
	loop	DisplaySectionName1		;next character
DisplaySectionName2:
	mov	si,offset sEndText		;end text
	jmp	OutputString
;
;==============================================================================
;
;	>	al  -  character
;
;------------------------------------------------------------------------------
;
OutputChar:
	mov	bChar,al			;save character
	mov	dx,offset bChar			;display character
	mov	cx,1
	jmp	WriteToStdOut
;
;==============================================================================
;
;	>	bx  -  wrapper
;		si  -  string
;
;------------------------------------------------------------------------------
;
OutputQuotedMessage:
	push	si
	mov	si,bx				;begin wrapper
	call	OutputString
	mov	bx,si
	pop	si
	push	bx
	call	OutputQuotedString		;insert text in quotes
	pop	bx
	mov	si,bx				;end wrapper
	jmp	OutputString
;
;==============================================================================
;
;	>	bx  -  wrapper
;		si  -  string
;
;------------------------------------------------------------------------------
;
OutputMessage:
	push	si
	mov	si,bx				;begin wrapper
	call	OutputString
	mov	bx,si
	pop	si
	push	bx
	call	OutputString			;insert text
	pop	bx
	mov	si,bx				;end wrapper
	jmp	OutputString
;
;==============================================================================
;
;	>	si  -  string
;
;	<	si  -  next string
;
;------------------------------------------------------------------------------
;
OutputQuotedString:
	push	si
	mov	si,offset sBeginText		;begin text
	call	OutputString
	pop	si
	call	OutputString			;display text
	push	si
	mov	si,offset sEndText		;end text
	call	OutputString
	pop	si
	ret
;
;==============================================================================
;
;	>	si  -  string
;
;	<	si  -  next string
;
;------------------------------------------------------------------------------
;
OutputString:
	mov	dx,si				;save base address
OutputString1:
	inc	si				;seek end of string
	cmp	byte ptr [si-1],0
	jnz	OutputString1
	mov	cx,si				;compute string length
	dec	cx
	sub	cx,dx
	push	si
	call	WriteToStdOut			;display string
	pop	si
	ret
;
;==============================================================================
;
;	>	bx  -  wrapper
;		si  -  string
;
;------------------------------------------------------------------------------
;
InfoQuotedMessage:
	push	si
	mov	si,bx				;begin wrapper
	call	InfoString
	mov	bx,si
	pop	si
	push	bx
	call	InfoQuotedString		;insert text in quotes
	pop	bx
	mov	si,bx				;end wrapper
	jmp	InfoString
;
;==============================================================================
;
;	>	bx  -  wrapper
;		si  -  string
;
;------------------------------------------------------------------------------
;
InfoMessage:
	push	si
	mov	si,bx				;begin wrapper
	call	InfoString
	mov	bx,si
	pop	si
	push	bx
	call	InfoString			;insert text
	pop	bx
	mov	si,bx				;end wrapper
	jmp	InfoString
;
;==============================================================================
;
;	>	si  -  string
;
;	<	si  -  next string
;
;------------------------------------------------------------------------------
;
InfoQuotedString:
	push	si
	mov	si,offset sBeginText		;begin text
	call	InfoString
	pop	si
	call	InfoString			;display text
	push	si
	mov	si,offset sEndText		;end text
	call	InfoString
	pop	si
	ret
;
;==============================================================================
;
;	>	si  -  string
;
;	<	si  -  next string
;
;------------------------------------------------------------------------------
;
InfoString:
	mov	dx,si				;save base address
InfoString1:
	inc	si				;seek end of string
	cmp	byte ptr [si-1],0
	jnz	InfoString1
	mov	cx,si				;compute string length
	dec	cx
	sub	cx,dx
	push	si
	call	WriteToStdErr			;display string
	pop	si
	ret
;
;==============================================================================
;
;	>	cx  -  number of bytes
;		dx  -  data buffer
;
;------------------------------------------------------------------------------
;
WriteToStdOut:
	cmp	bSilentMode,0			;silent mode?
	jnz	WriteToStdOut2
	jcxz	WriteToStdOut2			;nothing to do
	cmp	bInsertLine,0			;insert line?
	mov	bInsertLine,0
	jz	WriteToStdOut1
	push	cx
	push	dx
	mov	si,offset sNewLine		;new line
	call	OutputString
	pop	dx
	pop	cx
WriteToStdOut1:
	mov	bx,STDOUT			;write to stdout
	mov	ah,DOS_WRITE
	int	DOS
WriteToStdOut2:
	ret
;
;==============================================================================
;
;	>	cx  -  number of bytes
;		dx  -  data buffer
;
;------------------------------------------------------------------------------
;
WriteToStdErr:
	jcxz	WriteToStdErr1			;nothing to do
	mov	bx,STDERR			;write to stderr
	mov	ah,DOS_WRITE
	int	DOS
WriteToStdErr1:
	ret
;
;==============================================================================
;
;	TIME/DATE ROUTINES
;
;==============================================================================
;
;	<	si:di  -  time/date stamp
;
;------------------------------------------------------------------------------
;
GetTimeDate:
	mov	ah,DOS_GETDATE			;get system date
	int	DOS
	push	cx
	push	dx
	mov	ah,DOS_GETTIME			;get system time
	int	DOS
	pop	bx
	pop	ax
	mov	di,0				;load default time/date
	mov	si,0
	cmp	ax,1970				;test for minimum year
	jb	GetTimeDate12
	ja	GetTimeDate1
	cmp	bh,1				;test for minimum month
	jb	GetTimeDate12
	ja	GetTimeDate6
	cmp	bl,1				;test for minimum day
	jb	GetTimeDate12
	ja	GetTimeDate6
	cmp	ch,1				;test for minimum hour
	jb	GetTimeDate12
	jmp	GetTimeDate6
GetTimeDate1:
	push	dx
	push	ax
GetTimeDate2:
	add	di,SECONDS_PER_YEAR_LOW		;add seconds per year
	adc	si,SECONDS_PER_YEAR_HIGH
	dec	ax
	test	al,00000011b			;year divisible by 4?
	jnz	GetTimeDate5
	push	ax
	mov	dl,100				;year divisible by 100?
	div	dl
	cmp	ah,0
	jnz	GetTimeDate3
	test	al,00000011b			;year divisible by 400?
	jnz	GetTimeDate4
GetTimeDate3:
	add	di,SECONDS_PER_DAY_LOW		;add another day
	adc	si,SECONDS_PER_DAY_HIGH
GetTimeDate4:
	pop	ax
GetTimeDate5:
	cmp	ax,1970				;base year reached?
	jnz	GetTimeDate2
	pop	ax
	pop	dx
GetTimeDate6:
	cmp	bh,3				;january or february?
	jb	GetTimeDate8
	test	al,00000011b			;year divisible by 4?
	jnz	GetTimeDate8
	push	dx
	mov	dl,100				;year divisible by 100?
	div	dl
	pop	dx
	cmp	ah,0
	jnz	GetTimeDate7
	test	al,00000011b			;year divisible by 400?
	jnz	GetTimeDate8
GetTimeDate7:
	add	di,SECONDS_PER_DAY_LOW		;add another day
	adc	si,SECONDS_PER_DAY_HIGH
GetTimeDate8:
	mov	ax,bx				;evaluate month
	mov	bx,GetTimeDate13
GetTimeDate9:
	sub	ah,1				;count down months
	jna	GetTimeDate10
	add	di,cs:[bx]			;add seconds per month
	adc	si,cs:[bx+2]
	add	bx,4				;next month
	jmp	GetTimeDate9
GetTimeDate10:
	sub	al,1				;count down days
	jna	GetTimeDate11
	add	di,SECONDS_PER_DAY_LOW		;add seconds per day
	adc	si,SECONDS_PER_DAY_HIGH
	jmp	GetTimeDate10
GetTimeDate11:
	mov	dl,dh				;add seconds
	mov	dh,0
	add	di,dx
	adc	si,0
	mov	al,SECONDS_PER_MINUTE		;add minutes
	mul	cl
	add	di,ax
	adc	si,0
	mov	ax,SECONDS_PER_HOUR		;add hours
	mov	cl,ch
	mov	ch,0
	mul	cx
	add	di,ax
	adc	si,dx
	sub	di,SECONDS_PER_HOUR		;subtract base hour
	sbb	si,0
GetTimeDate12:
	ret
GetTimeDate13:
	DWORD	2678400, 2419200, 2678400, 2592000, 2678400, 2592000
	DWORD	2678400, 2678400, 2592000, 2678400, 2592000, 2678400
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
SetRsrcTimeDate:
	mov	ax,word ptr dTimeDate		;load time/date stamp
	mov	dx,word ptr dTimeDate+2
	mov	bx,0				;load root directory offset
SetRsrcTimeDate1:
	add	bx,RSRC_SECTION			;set pointer to directory
	mov	word ptr [bx.rdTimeDate],ax	;set directory time/date stamp
	mov	word ptr [bx.rdTimeDate+2],dx
	lea	si,[bx+PE_RSRC_DIR_]		;set pointer to 1st entry
	mov	cx,[bx.rdNumberOfIdEntries]	;load number of entries
SetRsrcTimeDate2:
	cmp	[si.rdirDataOrSubdirFlag],PE_RSRC_IS_DIR ;subdirectory?
	jnz	SetRsrcTimeDate3
	mov	bx,[si.rdirDataOrSubdir]	;load subdirectory offset
	push	si
	push	cx
	call	SetRsrcTimeDate1		;next tree arc
	pop	cx
	pop	si
SetRsrcTimeDate3:
	add	si,PE_RSRC_DIR_ENTRY_		;next entry
	loop	SetRsrcTimeDate2
	ret
;
;==============================================================================
;
;	MISCELLANEOUS
;
;==============================================================================
;
;	>	si  -  source
;		di  -  destination
;		cx  -  number of bytes
;
;	<	si  -  next source
;		di  -  next destination
;
;------------------------------------------------------------------------------
;
CopyStructure:
	jcxz	CopyStructure2			;nothing to copy
CopyStructure1:
	mov	al,[si]				;copy byte
	inc	si
	mov	[di],al
	inc	di
	loop	CopyStructure1			;next byte
CopyStructure2:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  offset
;		   cx  -  page size
;
;	<	dx:ax  -  aligned offset
;
;------------------------------------------------------------------------------
;
GetNextPage:
	push	dx
	push	ax
	push	cx
	mov	bx,cx				;compute remainder in last page
	call	Divide
	pop	cx
	pop	ax
	pop	dx
	cmp	bx,0				;already aligned?
	jz	GetNextPage1
	sub	cx,bx				;compute next page offset
	add	ax,cx
	adc	dx,0
GetNextPage1:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  class style
;		   bx  -  class style table
;
;------------------------------------------------------------------------------
;
SetClassStyle:
	mov	di,ax				;load class style
	mov	si,dx
SetClassStyle1:
	mov	cl,[bx]				;load bit count
	inc	bx
	cmp	cl,0
	jz	SetClassStyle5			;end of table
	mov	ch,cl				;save bit count
SetClassStyle2:
	shr	si,1				;shift out style bits
	rcr	di,1
	rcr	ax,1
	dec	cl
	jnz	SetClassStyle2
	mov	cl,16				;right align style bits
	sub	cl,ch
	shr	ax,cl
	mov	cl,ch				;load bit count
SetClassStyle3:
	mov	dx,[bx]				;load entry length
	add	bx,2
	cmp	dx,0
	jz	SetClassStyle1			;next record
	push	si
	push	di
	push	ax
	push	dx
	mul	dx				;compute entry offset
	pop	dx
	mov	di,[bx]				;load destination pointer
	add	bx,2
	mov	si,bx				;compute source pointer
	add	si,ax
SetClassStyle4:
	mov	al,[si]				;copy entry
	inc	si
	mov	[di],al
	inc	di
	dec	dx
	jnz	SetClassStyle4
	mov	ax,[bx-2-2]			;go to next record
	shl	ax,cl
	add	bx,ax
	pop	ax
	pop	di
	pop	si
	jmp	SetClassStyle3			;next subrecord
SetClassStyle5:
	ret
;
;==============================================================================
;
;	>	   si  -  string
;
;	<	dx:ax  -  binary number
;		   si  -  next string
;
;------------------------------------------------------------------------------
;
StringToNumber:
	inc	si				;skip leading spaces
	cmp	byte ptr [si-1],' '
	jz	StringToNumber
	dec	si
	mov	ax,0				;clear destination
	mov	dx,0
	mov	ch,0				;clear upper half of cx
StringToNumber1:
	mov	cl,[si]				;load digit
	cmp	cl,0				;end of string?
	jz	StringToNumber2
	inc	si
	sub	cl,'0'				;ascii -> binary
	cmp	cl,10				;ok?
	jnb	StringToNumber2
	shl	ax,1				;* 2
	rcl	dx,1
	mov	bx,ax
	mov	di,dx
	shl	ax,1				;* 4
	rcl	dx,1
	shl	ax,1				;* 8
	rcl	dx,1
	add	ax,bx				;* 10
	adc	dx,di
	add	ax,cx				;add digit
	adc	dx,0
	jmp	StringToNumber1		;next digit
StringToNumber2:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  dividend
;		   bx  -  divisor
;
;	<	dx:ax  -  quotient
;		   bx  -  remainder
;
;------------------------------------------------------------------------------
;
Divide:
	mov	si,bx				;load divisor
	mov	bx,0				;clear remainder
	mov	cx,32				;load bit count
Divide1:
	shl	ax,1				;shift dividend into remainder
	rcl	dx,1
	rcl	bx,1
	adc	al,0				;save msb of remainder
	sub	bx,si				;try subtraction
	jnb	Divide2				;ok
	ror	al,1				;was remainder > ffff?
	rol	al,1
	jb	Divide3				;ok
	add	bx,si				;undo subtraction
Divide2:
	cmc
Divide3:
	rcr	al,1				;save quotient bit
	rol	al,1
	loop	Divide1
	ret
;
;==============================================================================
;
;	>	      dx:ax  -  1st factor
;		      bx:cx  -  2nd factor
;
;	<	bx:cx:dx:ax  -  product
;		          c  -  set if product >= 2^32
;
;------------------------------------------------------------------------------
;
Multiply:
	mov	di,cx				;move 2nd factor
	mov	si,bx
	mov	cx,ax				;save 1st factor
	mov	bx,dx
	mul	di				;[ - | X ] * [ - | X ]
	push	dx
	push	ax
	mov	ax,bx				;[ X | - ] * [ X | - ]
	mul	si
	push	dx
	push	ax
	mov	ax,cx				;[ - | X ] * [ X | - ]
	mul	si
	mov	si,ax
	mov	cx,dx
	mov	ax,bx				;[ X | - ] * [ - | X ]
	mul	di
	xchg	ax,dx
	add	dx,si				;add middle dwords
	adc	cx,ax
	pop	si
	pop	bx
	adc	bx,0				;add leftmost dword
	add	cx,si
	adc	bx,0
	pop	ax
	pop	di
	add	dx,di				;add rightmost dword
	adc	cx,0
	adc	bx,0
	mov	si,cx				;upper half = 0?
	or	si,bx
	add	si,-1
	ret
;
;==============================================================================
;
CodeSegment_	equ	$
_text		ends
;
;==============================================================================
;
;	STACK SEGMENT
;
;==============================================================================
;
_stack	segment	stack 'STACK'
;
	WORD	StackSegment_
	BYTE	" Stack Segment"
	WORD	256 dup (0)			;local stack
;
StackSegment_	equ	$
_stack		ends
;
;==============================================================================
;
;	DATA SEGMENT
;
;==============================================================================
;
_data	segment	public 'DATA'
;
;------------------------------------------------------------------------------
;
	WORD	DataSegment_
	BYTE	" Data Segment "
;
;==============================================================================
;
;	PE HEADERS
;
;------------------------------------------------------------------------------
;
IMAGE_BASE	equ	$
;
;------------------------------------------------------------------------------
;
MZ_HEADER	equ	$
mzSignature	BYTE	"MZ"				;signature
mzExtraBytes	WORD	(MZ_HEADER_+DOS_STUB_) mod 512	;bytes in last page
mzPages		WORD	((MZ_HEADER_+DOS_STUB_-1)/512)+1;number of pages
mzRelocItems	WORD	0				;entries in reloc table
mzHeaderSize	WORD	((MZ_HEADER_-1)/16)+1		;header paragraphs
mzMinAlloc	WORD	00000h				;minimum allocation
mzMaxAlloc	WORD	0FFFFh				;maximum allocation
mzInitSS	WORD	00000h				;initial ss value
mzInitSP	WORD	DOS_STUB_STACK-DOS_STUB		;initial sp value
mzChecksum	WORD	0				;complemented checksum
mzInitIP	WORD	00000h				;initial ip value
mzInitCS	WORD	DOS_STUB_CODE-DOS_STUB		;initial cs value
mzRelocTable	WORD	MZ_HEADER_			;reloc table offset
mzOverlay	WORD	0				;overlay number
mzReserved1	WORD	16 dup (0)			;(reserved)
mzNextHeader	DWORD	PE_SIGNATURE-MZ_HEADER		;pointer to next header
MZ_HEADER_	equ	$-MZ_HEADER
;
;------------------------------------------------------------------------------
;
DOS_STUB	equ	$
;
DOS_STUB_CODE	equ	$
		mov	dx,cs				;ds := cs
		mov	ds,dx
		mov	dx,DOS_STUB_DATA-DOS_STUB	;display info text
		mov	ah,DOS_DISPLAY
		int	DOS
		mov	ax,(DOS_TERMINATE*0100h)+1	;terminate program
		int	DOS
;
DOS_STUB_DATA	equ	$
		BYTE	CR,LF,"> This is a Win32 program <",CR,LF,"$"
		BYTE	"SBS W32Link 1.00"
;
DOS_STUB_STACK	equ	$+0078h
;
DOS_STUB_	equ	0450h
;
;------------------------------------------------------------------------------
;
PE_SIGNATURE	equ	$
		BYTE	"PE",0,0	;pe file signature
;
;------------------------------------------------------------------------------
;
PE_HEADER	equ	$
peMachine	WORD	PE_MACHINE_I386			;machine type
peNumSections	WORD	SEC_HEADERS_/PE_SECTION_HEADER_	;number of sections
peTimeDate	DWORD	0				;time/date stamp
peSymbolTable	DWORD	0				;pointer to sym table
peNumSymbols	DWORD	0				;# of sym table entries
peSizeOptHeader	WORD	PE_OPT_HEADER_			;optional header size
peAttributes	WORD	DEFAULT_ATTRIBUTES		;file attributes
PE_HEADER_	equ	$-PE_HEADER
;
;------------------------------------------------------------------------------
;
PE_OPT_HEADER	equ	$
;
PE_OPT_STD	equ	$
osSignature	WORD	010Bh				;signature
osLinkerMajor	BYTE	LINKER_VERSION_H		;linker major version
osLinkerMinor	BYTE	LINKER_VERSION_L		;linker minor version
osTextTotal	DWORD	0				;size of code sections
osDataTotal	DWORD	0				;size of data sections
osBssTotal	DWORD	0				;size of bss sections
osEntryPoint	DWORD	HEADERS_MEMORY_			;program entry point
osTextAddress	DWORD	0				;code section load addr
osDataAddress	DWORD	0				;data section load addr
PE_OPT_STD_	equ	$-PE_OPT_STD
;
PE_OPT_NT	equ	$
onImageBase	DWORD	DEFAULT_BASE			;preferred load address
onSectionAlign	DWORD	MEMORY_PAGE			;memory sect. alignment
onFileAlign	DWORD	FILE_PAGE			;file section alignment
onOsMajor	WORD	OS_VERSION_H			;os major version
onOsMinor	WORD	OS_VERSION_L			;os minor version
onImageMajor	WORD	IMAGE_VERSION_H			;image major version
onImageMinor	WORD	IMAGE_VERSION_L			;image minor version
onSubSysMajor	WORD	SUBSYS_VERSION_H		;subsys major version
onSubSysMinor	WORD	SUBSYS_VERSION_L		;subsys minor version
onReserved1	DWORD	0				;(reserved)
onImageSize	DWORD	0				;image size
onHeaderSize	DWORD	HEADERS_FILE_			;combined header size
onFileChecksum	DWORD	0				;file checksum
onSubSystem	WORD	DEFAULT_SUBSYS			;required subsystem
onDllFlags	WORD	0				;(obsolete)
onStackReserve	DWORD	00100000h			;stack space to reserve
onStackCommit	DWORD	00001000h			;stack space to commit
onHeapReserve	DWORD	00100000h			;heap space to reserve
onHeapCommit	DWORD	00001000h			;heap space to commit
onLoaderFlags	DWORD	0				;(obsolete)
onNumDataDir	DWORD	PE_OPT_DATADIR_/PE_DATADIR_	;# of data directories
PE_OPT_NT_	equ	$-PE_OPT_NT
;
PE_OPT_DATADIR	equ	$
odExport	PE_DATADIR {0,0}			;export table
odImport	PE_DATADIR {0,0}			;import table
odResource	PE_DATADIR {0,0}			;resource table
odException	PE_DATADIR {0,0}			;exception table
odSecurity	PE_DATADIR {0,0}			;security table
odBaseReloc	PE_DATADIR {0,0}			;base relocation table
odDebug		PE_DATADIR {0,0}			;debug data
odCopyright	PE_DATADIR {0,0}			;copyright string
odGlobalPtr	PE_DATADIR {0,0}			;global ptr register
odTls		PE_DATADIR {0,0}			;thread loc storage tbl
odLoadConfig	PE_DATADIR {0,0}			;load config table
odBoundImport	PE_DATADIR {0,0}			;bound import directory
odIat		PE_DATADIR {0,0}			;import address table
odReserved1	PE_DATADIR {0,0}			;(reserved)
odReserved2	PE_DATADIR {0,0}			;(reserved)
odReserved3	PE_DATADIR {0,0}			;(reserved)
PE_OPT_DATADIR_	equ	$-PE_OPT_DATADIR
;
PE_OPT_HEADER_	equ	$-PE_OPT_HEADER
;
;------------------------------------------------------------------------------
;
SEC_HEADERS	equ	$
seTextHeader	PE_SECTION_HEADER {".text" ,,,,,0,0,0,0,PE_TEXT}	;.text
seDataHeader	PE_SECTION_HEADER {".data" ,,,,,0,0,0,0,PE_DATA}	;.data
seLinkHeader	PE_SECTION_HEADER {".link" ,,,,,0,0,0,0,PE_LINK}	;.link
seRsrcHeader	PE_SECTION_HEADER {".rsrc" ,,,,,0,0,0,0,PE_RSRC}	;.rsrc
seRelocHeader	PE_SECTION_HEADER {".reloc",,,,,0,0,0,0,PE_RELOC}	;.reloc
SEC_HEADERS_	equ	$-SEC_HEADERS
;
;------------------------------------------------------------------------------
;
HEADERS_RAW_	equ	$-IMAGE_BASE
HEADERS_FILE_	equ	(((HEADERS_RAW_-1)/FILE_PAGE)+1)*FILE_PAGE
HEADERS_MEMORY_	equ	(((HEADERS_RAW_-1)/MEMORY_PAGE)+1)*MEMORY_PAGE
;
;==============================================================================
;
;	RESOURCE SECTION
;
;------------------------------------------------------------------------------
;
RSRC_SECTION		equ	$
;
;------------------------------------------------------------------------------
;
rsDirRoot		PE_RSRC_DIR {0,,0,0,0,rsDirRootCount}
;
rsEntryDirIcon		PE_RSRC_DIR_ENTRY\
			   {RT_ICON,                        PE_RSRC_IS_ID,\
			    rsDirIcon - RSRC_SECTION,       PE_RSRC_IS_DIR}
;
rsEntryDirGroupIcon	PE_RSRC_DIR_ENTRY\
			   {RT_GROUP_ICON,                  PE_RSRC_IS_ID,\
			    rsDirGroupIcon - RSRC_SECTION,  PE_RSRC_IS_DIR}
;
rsDirRootCount		equ ($-rsDirRoot-PE_RSRC_DIR_)/PE_RSRC_DIR_ENTRY_
;
;------------------------------------------------------------------------------
;
rsDirIcon		PE_RSRC_DIR {0,,0,0,0,rsDirIconCount}
;
rsEntryEnumIcon		PE_RSRC_DIR_ENTRY\
			   {ICON_ORDINAL_NUMBER,            PE_RSRC_IS_ID,\
			    rsEnumIcon - RSRC_SECTION,      PE_RSRC_IS_DIR}
;
rsDirIconCount		equ ($-rsDirIcon-PE_RSRC_DIR_)/PE_RSRC_DIR_ENTRY_
;
;------------------------------------------------------------------------------
;
rsDirGroupIcon		PE_RSRC_DIR {0,,0,0,0,rsDirGroupIconCount}
;
rsEntryEnumGroupIcon	PE_RSRC_DIR_ENTRY\
			   {ICON_ID,                        PE_RSRC_IS_ID,\
			    rsEnumGroupIcon - RSRC_SECTION, PE_RSRC_IS_DIR}
;
rsDirGroupIconCount	equ ($-rsDirGroupIcon-PE_RSRC_DIR_)/PE_RSRC_DIR_ENTRY_
;
;------------------------------------------------------------------------------
;
rsEnumIcon		PE_RSRC_DIR {0,,0,0,0,rsEnumIconCount}
;
rsEntryDataIcon		PE_RSRC_DIR_ENTRY\
			   {LANGUAGE_ID,                    PE_RSRC_IS_ID,\
			    rsDataIcon - RSRC_SECTION,      PE_RSRC_IS_DATA}
;
rsEnumIconCount		equ ($-rsEnumIcon-PE_RSRC_DIR_)/PE_RSRC_DIR_ENTRY_
;
;------------------------------------------------------------------------------
;
rsEnumGroupIcon		PE_RSRC_DIR {0,,0,0,0,rsEnumGroupIconCount}
;
rsEntryDataGroupIcon	PE_RSRC_DIR_ENTRY\
			   {LANGUAGE_ID,                    PE_RSRC_IS_ID,\
			    rsDataGroupIcon - RSRC_SECTION, PE_RSRC_IS_DATA}
;
rsEnumGroupIconCount	equ ($-rsEnumGroupIcon-PE_RSRC_DIR_)/PE_RSRC_DIR_ENTRY_
;
;------------------------------------------------------------------------------
;
rsDataIcon		PE_RSRC_DATA_ENTRY\
			   {rsIcon - RSRC_SECTION, rsIcon_, 0, 0}
;
;------------------------------------------------------------------------------
;
rsDataGroupIcon		PE_RSRC_DATA_ENTRY\
			   {rsGroupIcon - RSRC_SECTION, rsGroupIcon_, 0, 0}
;
;------------------------------------------------------------------------------
;
ICON_ID			equ	101			;icon id
ICON_ORDINAL_NUMBER	equ	  1			;ordinal number
ICON_PLANES		equ	  1			;number of planes
ICON_BIT_COUNT		equ	  4			;bits per pixel
ICON_COLOR_COUNT	equ	 16			;number of colors
ICON_WIDTH		equ	 32			;number of columns
ICON_HEIGHT		equ	 32			;number of rows
;
ICON_PIXELS		equ	ICON_WIDTH*ICON_HEIGHT		;# of pixels
ICON_XOR_BYTES		equ	(ICON_PIXELS*ICON_BIT_COUNT)/8	;# of xor bytes
ICON_AND_BYTES		equ	ICON_PIXELS/8			;# of and bytes
ICON_SIZE_IMAGE		equ	ICON_XOR_BYTES+ICON_AND_BYTES	;image size
;
;------------------------------------------------------------------------------
;
rsIcon			equ	$
;
			DWORD	rsIconPalette-rsIcon	;biSize
			DWORD	ICON_WIDTH		;biWidth
			DWORD	ICON_HEIGHT*2		;biHeight
			WORD	ICON_PLANES		;biPlanes
			WORD	ICON_BIT_COUNT		;biBitCount
			DWORD	0			;biCompression
			DWORD	ICON_SIZE_IMAGE		;biSizeImage
			DWORD	0			;biXPelsPerMeter
			DWORD	0			;biYPelsPerMeter
			DWORD	0			;biClrUsed
			DWORD	0			;biClrImportant
;
rsIconPalette		equ	$
;
			BYTE	000,000,000,000		;RGBQUAD [00]
			BYTE	000,000,128,000		;RGBQUAD [01]
			BYTE	000,128,000,000		;RGBQUAD [02]
			BYTE	000,128,128,000		;RGBQUAD [03]
			BYTE	128,000,000,000		;RGBQUAD [04]
			BYTE	128,000,128,000		;RGBQUAD [05]
			BYTE	128,128,000,000		;RGBQUAD [06]
			BYTE	128,128,128,000		;RGBQUAD [07]
			BYTE	192,192,192,000		;RGBQUAD [08]
			BYTE	000,000,255,000		;RGBQUAD [09]
			BYTE	000,255,000,000		;RGBQUAD [10]
			BYTE	000,255,255,000		;RGBQUAD [11]
			BYTE	255,000,000,000		;RGBQUAD [12]
			BYTE	255,000,255,000		;RGBQUAD [13]
			BYTE	255,255,000,000		;RGBQUAD [14]
			BYTE	255,255,255,000		;RGBQUAD [15]
;
rsIconXor		equ	$
;
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,000h,000h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,000h,000h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,000h,000h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,000h,000h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,000h,000h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,00Bh,0BBh,0BBh,0BBh
			BYTE	0BAh,0AAh,0B0h,000h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,00Bh,0BBh,0BBh,0BBh
			BYTE	0BAh,0AAh,0BBh,000h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,00Bh,0BBh,0BBh,0BBh
			BYTE	0BAh,0AAh,0BBh,0B0h,000h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,0BBh,0BAh,0A0h,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,0BBh,0AAh,0AAh,000h,0AAh,0A0h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	00Ah,0AAh,0BAh,0AAh,0AAh,0A0h,0AAh,0A0h
			BYTE	009h,099h,000h,000h,000h,000h,099h,090h
			BYTE	00Ah,0AAh,0AAh,0AAh,0AAh,0AAh,0AAh,0A0h
			BYTE	009h,099h,000h,000h,000h,000h,099h,090h
			BYTE	00Ah,0AAh,0AAh,0AAh,0AAh,0AAh,0AAh,0A0h
			BYTE	009h,099h,000h,000h,000h,00Bh,0BBh,0BBh
			BYTE	0BAh,0AAh,0AAh,0A0h,00Ah,0AAh,0AAh,0A0h
			BYTE	009h,099h,000h,000h,000h,0BBh,0BBh,0BBh
			BYTE	0BAh,0AAh,0AAh,000h,000h,0AAh,0AAh,0A0h
			BYTE	009h,099h,000h,000h,00Bh,0BBh,0BBh,0BBh
			BYTE	0BAh,0AAh,0A0h,000h,000h,00Ah,0AAh,0A0h
			BYTE	009h,099h,000h,000h,00Bh,0BBh,0B9h,090h
			BYTE	00Ah,0AAh,000h,000h,000h,000h,0AAh,0A0h
			BYTE	009h,099h,000h,000h,00Bh,0BBh,099h,090h
			BYTE	00Ah,0A0h,000h,000h,000h,000h,00Ah,0A0h
			BYTE	009h,099h,000h,000h,00Bh,0BBh,099h,090h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	009h,099h,099h,099h,09Bh,0BBh,099h,090h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	009h,099h,099h,099h,09Bh,0BBh,0B9h,090h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	009h,099h,099h,099h,09Bh,0BBh,0BBh,0BBh
			BYTE	0BBh,0BBh,0BBh,000h,000h,000h,000h,000h
			BYTE	009h,099h,000h,000h,000h,0BBh,0BBh,0BBh
			BYTE	0BBh,0BBh,0BBh,000h,000h,000h,000h,000h
			BYTE	009h,099h,000h,000h,000h,00Bh,0BBh,0BBh
			BYTE	0BBh,0BBh,0BBh,000h,000h,000h,000h,000h
			BYTE	009h,099h,000h,000h,000h,000h,099h,090h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	009h,099h,000h,000h,000h,000h,099h,090h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	009h,099h,090h,000h,000h,009h,099h,090h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	009h,099h,099h,099h,099h,099h,099h,090h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,099h,099h,099h,099h,099h,099h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,009h,099h,099h,099h,099h,090h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
;
rsIconAnd		equ	$
;
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
			BYTE	000h,000h,000h,000h,000h,000h,000h,000h
;
rsIcon_			equ	$-rsIcon
;
;------------------------------------------------------------------------------
;
rsGroupIcon		equ	$
;
			WORD	0			;icoReserved
			WORD	1			;icoResourceType
			WORD	1			;icoResourceCount
			BYTE	ICON_WIDTH		;icoWidth
			BYTE	ICON_HEIGHT		;icoHeight
			BYTE	ICON_COLOR_COUNT	;icoColorCount
			BYTE	0			;(reserved)
			WORD	ICON_PLANES		;icoPlanes
			WORD	ICON_BIT_COUNT		;icoBitCount
			DWORD	rsIcon_			;icoDIBSize
			WORD	ICON_ORDINAL_NUMBER	;icoOrdinalNumber
;
rsGroupIcon_		equ	$-rsGroupIcon
;
;------------------------------------------------------------------------------
;
RSRC_SECTION_		equ	$-RSRC_SECTION
;
;==============================================================================
;
;	INITIALIZED DATA
;
;------------------------------------------------------------------------------
;
wWin32Symbols		WORD	0
wWin32Index		WORD	0
wWin32Names		WORD	0
;
;------------------------------------------------------------------------------
;
wRecordBuffer		WORD	0
dRecordOffset		DWORD	0
bRecordType		BYTE	0
wRecordLength		WORD	0
bRecordCheck		BYTE	0
;
;------------------------------------------------------------------------------
;
hOutput			WORD	0
bOutputMode		BYTE	0
wOutputBuffer		WORD	0
wOutputOffset		WORD	0
wOutputSegment		WORD	0
dOutputSize		DWORD	0
;
;------------------------------------------------------------------------------
;
bDataType		BYTE	DATA_NONE
bDataByte		BYTE	0
dDataOffset		DWORD	0
dDataTarget		DWORD	0
dDataLengthX		DWORD	0
wDataLength		WORD	0
wDataRecursion		WORD	20
;
;------------------------------------------------------------------------------
;
wFixupBuffer		WORD	0
wFixupSubrecord		WORD	0
wFixupOffset		WORD	0
dFixupDataOffset	DWORD	0
wFixupFrame		WORD	0
wFixupTarget		WORD	0
dFixupDisplacement	DWORD	0
wFixupBaseReloc		WORD	0
dFixupBlockEntries	DWORD	0
wFixupExternal		WORD	0
;
;------------------------------------------------------------------------------
;
dTextBegin		DWORD	0
dTextEnd		DWORD	0
dDataBegin		DWORD	0
dDataEnd		DWORD	0
dNextBegin		DWORD	0
dNextLoadAddress	DWORD	0
dNextRawAddress		DWORD	0
dImportSymbols		DWORD	0
dExportAddress		DWORD	0
dExportNamePointer	DWORD	0
wExportOrdinal		WORD	0
;
;------------------------------------------------------------------------------
;
InputParameters		equ	$
;
hInput			WORD	0
dInputBlockOffset	DWORD	0
wInputBlockPointer	WORD	FileBuffer
wInputBlockEnd		WORD	FileBuffer
wInputBackup		WORD	0
;
InputParameters_	equ	$-InputParameters
;
;------------------------------------------------------------------------------
;
bInsertLine		BYTE	0
bSilentMode		BYTE	SILENT
bDumpWin32Symbols	BYTE	0
;
;------------------------------------------------------------------------------
;
bVerboseMode		BYTE	DETAILS
;
bRecordSpacing		BYTE	DETAILS
bDumpSource		BYTE	DETAILS
bDumpSegment		BYTE	DETAILS
bDumpOutputFileName	BYTE	DETAILS
bDumpSymbolFileName	BYTE	DETAILS
bDumpExternal		BYTE	DETAILS
bDumpPublic		BYTE	DETAILS
bDumpData		BYTE	DETAILS
bDumpSection		BYTE	DETAILS
bDumpFixupBaseReloc	BYTE	DETAILS
bDumpFixupExternal	BYTE	DETAILS
bDumpFixupEntryPoint	BYTE	DETAILS
bMemoryStatistics	BYTE	DETAILS
;
bVerboseModeCount	BYTE	$-bVerboseMode-1
;
;------------------------------------------------------------------------------
;
bChar			BYTE	"?"
bApiSuffix		BYTE	DEFAULT_API
wIconIndex		WORD	0
dTimeDate		DWORD	0
;
;------------------------------------------------------------------------------
;
sSymbolExtension	BYTE	"."
dSymbolExtension	DWORD	DEFAULT_IMPORT
			BYTE	0
;
;------------------------------------------------------------------------------
;
sIconExtension		BYTE	".ico",0
sInputExtension		BYTE	".obj",0
sOutputExtension	BYTE	DEFAULT_EXTENSION
;
;------------------------------------------------------------------------------
;
sUndefined		BYTE	"???",0
sBeginText		BYTE	"""",0
sEndText		BYTE	"""",0
sNewLine		BYTE	CR,LF,0
sNull			BYTE	0
dNull			DWORD	0
;
;------------------------------------------------------------------------------
;
CommandOptions		equ	$
;
			BYTE	"D"
			WORD	OptionDetails
;
			BYTE	"S"
			WORD	OptionSilent
;
			BYTE	"T"
			WORD	OptionTable
;
			BYTE	0
;
;------------------------------------------------------------------------------
;
RecordTypes	equ	$
;
	BYTE	06Eh, 0, "RHEADR ",0, "R-Module Header Record",0
	WORD	-1
;
	BYTE	070h, 0, "REGINT ",0, "Register Initialization",0
	WORD	-1
;
	BYTE	072h, 0, "REDATA ",0, "Relocatable Enumerated Data",0
	WORD	-1
;
	BYTE	074h, 0, "RIDATA ",0, "Relocatable Iterated Data",0
	WORD	-1
;
	BYTE	076h, 0, "OVLDEF ",0, "Overlay Definition",0
	WORD	-1
;
	BYTE	078h, 0, "ENDREC ",0, "End Record",0
	WORD	-1
;
	BYTE	07Ah, 0, "BLKDEF ",0, "Block Definition",0
	WORD	-1
;
	BYTE	07Ch, 0, "BLKEND ",0, "Block End",0
	WORD	-1
;
	BYTE	07Eh, 0, "DEBSYM ",0, "Debug Symbols",0
	WORD	-1
;
THEADR	BYTE	080h, 0, "THEADR ",0, "Translator Header",0
	WORD	THEADR_Handler
;
LHEADR	BYTE	082h, 0, "LHEADR ",0, "Library Module Header",0
	WORD	LHEADR_Handler
;
	BYTE	084h, 0, "PEDATA ",0, "Physical Enumerated Data",0
	WORD	-1
;
	BYTE	086h, 0, "PIDATA ",0, "Physical Iterated Data",0
	WORD	-1
;
	BYTE	088h, 0, "COMENT ",0, "Comment / Special Purpose",0
	WORD	0
;
MODEND	BYTE	08Ah, 1, "MODEND ",0, "Module End",0
	WORD	MODEND_Handler
;
	BYTE	08Ch, 0, "EXTDEF ",0, "External Names Definition",0
	WORD	EXTDEF_Handler
;
	BYTE	08Eh, 0, "TYPDEF ",0, "Type Definition",0
	WORD	-1
;
	BYTE	090h, 1, "PUBDEF ",0, "Public Names Definition",0
	WORD	PUBDEF_Handler
;
	BYTE	092h, 0, "LOCSYM ",0, "Local Symbols",0
	WORD	-1
;
	BYTE	094h, 1, "LINNUM ",0, "Line Numbers",0
	WORD	0
;
	BYTE	096h, 0, "LNAMES ",0, "List of Names",0
	WORD	LNAMES_Handler
;
	BYTE	098h, 1, "SEGDEF ",0, "Segment Definition",0
	WORD	SEGDEF_Handler
;
	BYTE	09Ah, 0, "GRPDEF ",0, "Group Definition",0
	WORD	-1
;
	BYTE	09Ch, 1, "FIXUPP ",0, "Fixup Record",0
	WORD	FIXUPP_Handler
;
	BYTE	0A0h, 1, "LEDATA ",0, "Logical Enumerated Data",0
	WORD	LEDATA_Handler
;
	BYTE	0A2h, 1, "LIDATA ",0, "Logical Iterated Data",0
	WORD	LIDATA_Handler
;
	BYTE	0A4h, 0, "LIBHED ",0, "Library Header",0
	WORD	-1
;
	BYTE	0A6h, 0, "LIBNAM ",0, "Library Module Names",0
	WORD	-1
;
	BYTE	0A8h, 0, "LIBLOC ",0, "Library Module Locations",0
	WORD	-1
;
	BYTE	0AAh, 0, "LIBDIC ",0, "Library Dictionary",0
	WORD	-1
;
	BYTE	0B0h, 0, "COMDEF ",0, "Communal Names Definition",0
	WORD	-1
;
	BYTE	0B2h, 1, "BAKPAT ",0, "Backpatch Record",0
	WORD	-1
;
	BYTE	0B4h, 1, "LEXTDEF",0, "Local External Names Definition",0
	WORD	LEXTDEF_Handler
;
	BYTE	0B6h, 1, "LPUBDEF",0, "Local Public Names Definition",0
	WORD	LPUBDEF_Handler
;
	BYTE	0B8h, 0, "LCOMDEF",0, "Local Communal Names Definition",0
	WORD	-1
;
	BYTE	0BAh, 1, "COMFIX ",0, "Communal Fixup",0
	WORD	-1
;
	BYTE	0BCh, 0, "CEXTDEF",0, "COMDAT External Names Definition",0
	WORD	-1
;
	BYTE	0C0h, 0, "SELDEF ",0, "Selector Definition",0
	WORD	-1
;
	BYTE	0C2h, 1, "COMDAT ",0, "Initialized Communal Data",0
	WORD	-1
;
	BYTE	0C4h, 1, "LINSYM ",0, "Symbol Line Numbers",0
	WORD	-1
;
	BYTE	0C6h, 0, "ALIAS  ",0, "Alias Definition",0
	WORD	-1
;
	BYTE	0C8h, 1, "NBKPAT ",0, "Named Backpatch",0
	WORD	-1
;
	BYTE	0CAh, 0, "LLNAMES",0, "Local Logical Names Definition",0
	WORD	LLNAMES_Handler
;
	BYTE	0CCh, 0, "VERNUM ",0, "OMF Version Number",0
	WORD	0
;
	BYTE	0CEh, 0, "VENDEXT",0, "Vendor-specific OMF Extension",0
	WORD	0
;
LibHdr	BYTE	0F0h, 0, "*LibHdr",0, "Library Header",0
	WORD	-1
;
LibEnd	BYTE	0F1h, 0, "*LibEnd",0, "Library End",0
	WORD	-1
;
	BYTE	000h, 0, "--??-- ",0, "(Unknown Record Type)",0
	WORD	-1
;
;------------------------------------------------------------------------------
;
SegAlignment	equ	$
;
	BYTE	" AT ",0
	BYTE	" BYTE",0
	BYTE	" WORD",0
	BYTE	" PARA",0
	BYTE	" PAGE",0
	BYTE	" DWORD",0
	BYTE	" ALIGNMENT6",0
	BYTE	" ALIGNMENT7",0
;
;------------------------------------------------------------------------------
;
SegCombination	equ	$
;
	BYTE	" PRIVATE",0
	BYTE	" MEMORY",0
	BYTE	" PUBLIC",0
	BYTE	" COMBINATION3",0
	BYTE	" PUBLIC",0
	BYTE	" STACK",0
	BYTE	" COMMON",0
	BYTE	" PUBLIC",0
;
;------------------------------------------------------------------------------
;
SegUse		equ	$
;
	BYTE	" USE16",0
	BYTE	" USE32",0
;
;------------------------------------------------------------------------------
;
FixupSubrecord	equ	$
;
	BYTE	"THREAD subrecord",0
	BYTE	"FIXUP subrecord",0
;
;------------------------------------------------------------------------------
;
FixupMode	equ	$
;
	BYTE	"Self-relative mode",0
	BYTE	"Segment-relative mode",0
;
;------------------------------------------------------------------------------
;
FixupLocation	equ	$
;
	BYTE	"Low-order byte location",0
	BYTE	"16-bit offset location",0
	BYTE	"16-bit base location",0
	BYTE	"16:16-bit pointer location",0
	BYTE	"High-order byte location",0
	BYTE	"16-bit loader-resolved offset location",0
	BYTE	"Location type #6",0
	BYTE	"Location type #7",0
	BYTE	"Location type #8",0
	BYTE	"32-bit offset location",0
	BYTE	"Location type #10",0
	BYTE	"16:32-bit pointer location",0
	BYTE	"Location type #12",0
	BYTE	"32-bit loader-resolved offset location",0
	BYTE	"Location type #14",0
	BYTE	"Location type #15",0
;
;------------------------------------------------------------------------------
;
FixDataThreads	equ	$
;
	BYTE	"Explicit frame and target",0
	BYTE	"Target thread reference",0
	BYTE	"Frame thread reference",0
	BYTE	"Frame and target thread reference",0
;
;------------------------------------------------------------------------------
;
FixDataFMethod	equ	$
;
	BYTE	"Frame method F0 (SEGDEF)",0
	BYTE	"Frame method F1 (GRPDEF)",0
	BYTE	"Frame method F2 (EXTDEF)",0
	BYTE	"Frame method F3 (Explicit Frame Number)",0
	BYTE	"Frame method F4 (LEDATA/LIDATA)",0
	BYTE	"Frame method F5 (Target Frame)",0
	BYTE	"Frame method F6 (?)",0
	BYTE	"Frame method F7 (?)",0
;
;------------------------------------------------------------------------------
;
FixDataTMethod	equ	$
;
	BYTE	"Target method T0 (SEGDEF + Displacement)",0
	BYTE	"Target method T1 (GRPDEF + Displacement)",0
	BYTE	"Target method T2 (EXTDEF + Displacement)",0
	BYTE	"Target method T3 (Explicit Frame Number)",0
	BYTE	"Target method T4 (SEGDEF)",0
	BYTE	"Target method T5 (GRPDEF)",0
	BYTE	"Target method T6 (EXTDEF)",0
	BYTE	"Target method T7 (?)",0
;
;------------------------------------------------------------------------------
;
ModTypeMain	equ	$
;
	BYTE	"Non-main module",0
	BYTE	"Main module",0
;
;------------------------------------------------------------------------------
;
ModTypeStart	equ	$
;
	BYTE	"Implicit entry point",0
	BYTE	"Explicit entry point",0
;
;------------------------------------------------------------------------------
;
ModTypeSegment	equ	$
;
	BYTE	"Segment Bit = 0",0
	BYTE	"Segment Bit = 1",0
;
;------------------------------------------------------------------------------
;
ModTypeX	equ	$
;
	BYTE	"Absolute entry point",0
	BYTE	"Relocatable entry point",0
;
;------------------------------------------------------------------------------
;
ClassStyleTable	equ	$
;
	BYTE	4
	WORD	2, onSubSystem
	WORD	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
	WORD	0
;
	BYTE	1
	WORD	1, bApiSuffix
	BYTE	"A", "W"
	WORD	0
;
	BYTE	1
	WORD	2, peAttributes
	WORD	PE_DEFAULT_ATTRIBUTES, PE_DEFAULT_ATTRIBUTES+PE_DLL
	WORD	4, onImageBase
	DWORD	APP_BASE, DLL_BASE
	WORD	5, sOutputExtension
	BYTE	APP_EXTENSION, DLL_EXTENSION
	WORD	0
;
	BYTE	0
;
;------------------------------------------------------------------------------
;
sBanner\
BYTE CR,LF
BYTE "________________________________________________________________",CR,LF
BYTE CR,LF
BYTE "                          W32Link.ASM",CR,LF
BYTE "                   Win32 PE File Linker V1.00",CR,LF
BYTE "        03-16-1996 Sven B. Schreiber sbs@psbs.franken.de",CR,LF
BYTE "                 This is Public Domain Software",CR,LF
BYTE "________________________________________________________________",CR,LF
BYTE CR,LF
BYTE 0
;
sNormalEnd\
BYTE CR,LF
BYTE "W32Link: Normal end.",CR,LF
BYTE 0
;
sMemoryError\
BYTE CR,LF
BYTE "W32Link: Memory allocation error.",CR,LF
BYTE 0
;
sOutOfMemory\
BYTE CR,LF
BYTE "W32Link: Not enough memory available.",CR,LF
BYTE 0
;
sInitFailure\
BYTE CR,LF
BYTE "W32Link: Program initialization failure.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sInvalidCommand\
BYTE CR,LF
BYTE "Usage:   W32Link [Options] <Input File>",CR,LF
BYTE CR,LF
BYTE "Options: /d = Detailed OMF Report "
     if DETAILS
BYTE "OFF",CR,LF
     else
BYTE "ON",CR,LF
     endif
BYTE "         /s = Silent Mode "
     if SILENT
BYTE "OFF",CR,LF
     else
BYTE "ON",CR,LF
     endif
BYTE "         /t = Dump Win32 Symbol Table",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sInvalidOption\
BYTE CR,LF
BYTE "W32Link: Unrecognized command line option.",CR,LF
BYTE 0
;
sIconNotLoaded\
BYTE CR,LF
BYTE "W32Link: Unable to load the application icon.",CR,LF
BYTE 0
;
sFileNotFound\
BYTE CR,LF
BYTE "W32Link: Input file not found.",CR,LF
BYTE 0
;
sFileNotWritten\
BYTE CR,LF
BYTE "W32Link: Output file write error - check disk space.",CR,LF
BYTE 0
;
sFileNotSaved\
BYTE CR,LF
BYTE "W32Link: Output file could not be saved.",CR,LF
BYTE 0
;
sFileIoError\
BYTE CR,LF
BYTE "W32Link: File I/O error.",CR,LF
BYTE 0
;
sNoOmfFile\
BYTE CR,LF
BYTE "W32Link: Input file is not an OMF object file.",CR,LF
BYTE 0
;
sEndOfFile\
BYTE CR,LF
BYTE "W32Link: Unexpected end of input file.",CR,LF
BYTE 0
;
sInvalidData\
BYTE CR,LF
BYTE "W32Link: An error occurred while processing OMF record data.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sIconFile\
BYTE CR,LF,"Icon File:  ",0,0
;
sInputFile\
BYTE CR,LF,"Input File: ",0,CR,LF,0
;
sDumpWin32Symbols\
BYTE CR,LF,"[Win32 Symbols]",CR,LF,0
;
sRecordCaption\
BYTE 0,": [",0,"] ",0," ",0,CR,LF,0
;
s32Bit\
BYTE "32-Bit ",0
;
sChecksumError\
BYTE " [Checksum Error]",0
;
sRecordIgnored\
BYTE CR,LF
BYTE "      !!! RECORD IGNORED",0
;
sRecordNotSupported\
BYTE CR,LF
BYTE "      !!! RECORD TYPE NOT SUPPORTED",0
;
sWriteError\
BYTE "      !!! Output file write error",CR,LF,0
;
sTooManySegments\
BYTE "      !!! Multiple segments not supported",CR,LF,0
;
sInvalidSegment\
BYTE "      !!! Segment type must be ""BYTE PRIVATE USE32""",CR,LF,0
;
sOutputFileNotCreated\
BYTE "      !!! Unable to create the PE output file",CR,LF,0
;
sSymbolsNotLoaded\
BYTE "      !!! Unable to load the requested Win32 symbol file",CR,LF,0
;
sInvalidExternal\
BYTE "      !!! Unknown external symbol: ",0,CR,LF,0
;
sNothingToFix\
BYTE "      !!! There's no data to be fixed up",CR,LF,0
;
sNothingToWrite\
BYTE "      !!! There's no data to be written to the image",CR,LF,0
;
sCantFixupLidata\
BYTE "      !!! LIDATA fixups not supported",CR,LF,0
;
sInvalidFixupOffset\
BYTE "      !!! Fixup offset out of range",CR,LF,0
;
sFixupNotSupported\
BYTE "      !!! ",0,": ",0," not supported",CR,LF,0
;
sInvalidExternalRef\
BYTE "      !!! Invalid external reference",CR,LF,0
;
sFixupBufferOverflow\
BYTE "      !!! Fixup buffer overflow",CR,LF,0
;
;------------------------------------------------------------------------------
;
sDumpSourceFileName\
BYTE "          Source File Name: ",0,CR,LF,0
;
sDumpOutputFileName\
BYTE "          Output File ",0," will be created",CR,LF,0
;
sDumpSymbolFileName\
BYTE "          Symbol file ",0," will be loaded",CR,LF,0
;
sDumpSegment\
BYTE "          ",0," SEGMENT",0,CR,LF
BYTE "          Segment size: ",0," Bytes",CR,LF,0
;
sDumpExternal\
BYTE "          [",0,"] ",0," (",0,")",CR,LF,0
;
sDumpPublic\
BYTE "          [",0,"] ",0,CR,LF,0
;
sDumpData\
BYTE "          Segment ",0,", Offset ",0,", Length ",0,CR,LF,0
;
sDumpTextSection\
BYTE "          Code: Memory ",0,"/",0,", File ",0,"/",0,", ",0,CR,LF,0
;
sDumpDataSection\
BYTE "          Data: Memory ",0,"/",0,", File ",0,"/",0,", ",0,CR,LF,0
;
sDumpFixupBaseReloc\
BYTE "          -> ",0,": Address ",0,CR,LF,0
;
sDumpFixupExternal\
BYTE "          -> ",0,": External ID ",0," ",0,CR,LF,0
;
sDumpFixupEntryPoint\
BYTE "          Module entry point: ",0,CR,LF,0
;
;------------------------------------------------------------------------------
;
sMemoryStatistics\
BYTE CR,LF
BYTE "Memory Usage: ",0,"% - Win32 Symbol Table",CR,LF
BYTE "              ",0,"% - Application Symbol Table",CR,LF
BYTE "              ",0,"% - Object Names Table",CR,LF
BYTE "              ",0,"% - External Names Table",CR,LF
BYTE "              ",0,"% - Public Names Table",CR,LF
BYTE "              ",0,"% - Module Names Table",CR,LF
BYTE "              ",0,"% - Fixup Table",CR,LF,0
;
;==============================================================================
;
;	UNINITIALIZED DATA
;
;------------------------------------------------------------------------------
;
XX		=	0
;
;------------------------------------------------------------------------------
;
FileParameter_	equ	PATH_LENGTH
FileParameter	equ	$  + XX
XX		=	XX + FileParameter_
;
DirBuffer_	equ	PATH_LENGTH
DirBuffer	equ	$  + XX
XX		=	XX + DirBuffer_
;
ProgramFile_	equ	PATH_LENGTH
ProgramFile	equ	$  + XX
XX		=	XX + ProgramFile_
;
SymbolFile_	equ	PATH_LENGTH
SymbolFile	equ	$  + XX
XX		=	XX + SymbolFile_
;
IconFile_	equ	PATH_LENGTH
IconFile	equ	$  + XX
XX		=	XX + IconFile_
;
SourceFile_	equ	PATH_LENGTH
SourceFile	equ	$  + XX
XX		=	XX + SourceFile_
;
InputFile_	equ	PATH_LENGTH
InputFile	equ	$  + XX
XX		=	XX + InputFile_
;
OutputFile_	equ	PATH_LENGTH
OutputFile	equ	$  + XX
XX		=	XX + OutputFile_
;
;------------------------------------------------------------------------------
;
HexBuffer_	equ	8+1
HexBuffer	equ	$  + XX
XX		=	XX + HexBuffer_
;
StringBuffer_	equ	256
StringBuffer	equ	$  + XX
XX		=	XX + StringBuffer_
;
LineBuffer_	equ	256
LineBuffer	equ	$  + XX
XX		=	XX + LineBuffer_
;
FileBuffer_	equ	2000h
FileBuffer	equ	$  + XX
XX		=	XX + FileBuffer_
;
DataBuffer_	equ	0400h
DataBuffer	equ	$  + XX
XX		=	XX + DataBuffer_
;
;------------------------------------------------------------------------------
;
IconDir		equ	$  + XX
XX		=	XX + ICONDIR_
;
IconDirEntry	equ	$  + XX
XX		=	XX + ICONDIRENTRY_
;
;------------------------------------------------------------------------------
;
LNAMES_Index	equ	$  + XX
XX		=	XX + LNAMES_INDEX_
;
PUBDEF_Index	equ	$  + XX
XX		=	XX + PUBDEF_INDEX_
;
EXTDEF_Index	equ	$  + XX
XX		=	XX + EXTDEF_INDEX_
;
MODDEF_Index	equ	$  + XX
XX		=	XX + MODDEF_INDEX_
;
ImportDir	equ	$  + XX
XX		=	XX + PE_IMPORT_DIR_
;
ExportDir	equ	$  + XX
XX		=	XX + PE_EXPORT_DIR_
;
FixupBlock	equ	$  + XX
XX		=	XX + PE_FIXUP_BLOCK_
;
MainSegment	equ	$  + XX
XX		=	XX + SEGDEF_DATA_
;
TextSection	equ	$  + XX
XX		=	XX + SECTION_DATA_
;
DataSection	equ	$  + XX
XX		=	XX + SECTION_DATA_
;
SymbolTable	equ	$  + XX
XX		=	XX + SYMBOL_TABLE_
;
;==============================================================================
;
DataSegment_	equ	$ + XX
_data		ends
;
;==============================================================================
;
		end	Main

