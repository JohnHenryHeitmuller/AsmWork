;
;	________________________________________________________________
;
;	                          PEexport.ASM
;	                 PE Export Section Dumper V1.01
;	        01-29-1996 Sven B. Schreiber sbs@psbs.franken.de
;	                 This is Public Domain Software
;	________________________________________________________________
;
;
;
;==============================================================================
;
; PLEASE NOTE
;
; PEexport is Public Domain Software and is distributed with the ASM source
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
; 12-12-1995  V1.00  SBS  Original Version
;
; 01-29-1996  V1.01  SBS  Update
;
;	Output format changed to include unbiased ordinal numbers as well.
;	New format is "<Name>=<Unbiased>,<Biased>".
;
;==============================================================================
;
;	CONSTANTS
;
;==============================================================================
;
PATH_LENGTH		equ	260		;maximum path length
COMMAND_TAIL		equ	0081h		;command tail address
;
;------------------------------------------------------------------------------
;
DOS			equ	21h		;dos api
;
DOS_DISPLAY		equ	02h		;display character
DOS_OPEN		equ	3Dh		;open file
DOS_CLOSE		equ	3Eh		;close file
DOS_READ		equ	3Fh		;read file
DOS_WRITE		equ	40h		;write file
DOS_MOVEPOINTER		equ	42h		;move file pointer
DOS_REALLOCATE		equ	4Ah		;reallocate memory block
DOS_TERMINATE		equ	4Ch		;terminate program
DOS_GETPSP		equ	51h		;get current psp address
;
;------------------------------------------------------------------------------
;
STDIN			equ	0		;standard input
STDOUT			equ	1		;standard output
STDERR			equ	2		;standard error output
STDAUX			equ	3		;standard comm output
STDPRN			equ	4		;standard printer output
;
;------------------------------------------------------------------------------
;
RET_NORMAL_END		equ	0		;program terminated normally
RET_MEMORY_ERROR	equ	1		;memory allocation error
RET_INVALID_COMMAND	equ	2		;invalid command line
RET_FILE_NOT_FOUND	equ	3		;input file not found
RET_NO_PE_FILE		equ	4		;input file is not a pe file
RET_BAD_PE_FILE		equ	5		;input file is corrupt
RET_BAD_EXPORT_DIR	equ	6		;export directory is corrupt
RET_BAD_EXPORT_DATA	equ	7		;export data is corrupt
RET_NO_EXPORTS		equ	8		;input file exports nothing
;
;------------------------------------------------------------------------------
;
LF			equ	0Ah		;linefeed
CR			equ	0Dh		;carriage return
;
;------------------------------------------------------------------------------
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
PE_LINE_NUMS_STRIPPED	equ	0004h		;line nunbers stripped
PE_LOCAL_SYMS_STRIPPED	equ	0008h		;local symbols stripped
PE_BYTES_REVERSED_LO	equ	0080h		;bytes of machine word reversed
PE_32BIT_MACHINE	equ	0100h		;32 bit word machine
PE_DEBUG_STRIPPED	equ	0200h		;debugging info stripped
PE_SYSTEM		equ	1000h		;system file
PE_DLL			equ	2000h		;file is a dll
PE_BYTES_REVERSED_HI	equ	8000h		;bytes of machine word reversed
;
;==============================================================================
;
;	STRUCTURES
;
;==============================================================================
;
MZ_HEADER	struct
mzSignature	WORD	0		;signature
mzExtraBytes	WORD	0		;number of bytes in last (partial) page
mzPages		WORD	0		;number of whole and part pages in file
mzRelocItems	WORD	0		;number of pointers in relocation table
mzHeaderSize	WORD	0		;size of header, in paragraphs
mzMinAlloc	WORD	0		;minimum allocation
mzMaxAlloc	WORD	0		;maximum allocation
mzInitSS	WORD	0		;initial ss value
mzInitSP	WORD	0		;initial sp value
mzChecksum	WORD	0		;complemented checksum
mzInitIP	WORD	0		;initial ip value
mzInitCS	WORD	0		;initial cs value
mzRelocTable	WORD	0		;byte offset to relocation table
mzOverlay	WORD	0		;overlay number
mzReserved1	WORD	16 dup (0)	;(reserved)
mzNextHeader	DWORD	0		;pointer to next header
MZ_HEADER	ends
MZ_HEADER_	equ	2+2+2+2+2+2+2+2+2+2+2+2+2+2+32+4
;
;------------------------------------------------------------------------------
;
PE_HEADER	struct
peMachine	WORD	0		;machine type
peNumSections	WORD	0		;number of sections
peTimeDate	DWORD	0		;time/date stamp
peSymbolTable	DWORD	0		;pointer to symbol table
peNumSymbols	DWORD	0		;number of symbol table entries
peSizeOptHeader	WORD	0		;size of optional header
peAttributes	WORD	0		;file attributes
PE_HEADER	ends
PE_HEADER_	equ	2+2+4+4+4+2+2
;
;------------------------------------------------------------------------------
;
PE_OPT_HEADER	struct
ohSignature	WORD	0		;signature
ohLinkerMajor	BYTE	0		;linker major version number
ohLinkerMinor	BYTE	0		;linker minor version number
ohTextSize	DWORD	0		;size of code sections
ohDataSize	DWORD	0		;size of initialized data sections
ohBssSize	DWORD	0		;size of uninitialized data sections
ohEntryPoint	DWORD	0		;main program entry point
ohTextBase	DWORD	0		;code section load address
ohDataBase	DWORD	0		;data section load address
ohImageBase	DWORD	0		;preferred load address
ohSectionAlign	DWORD	0		;section alignment in memory
ohFileAlign	DWORD	0		;section alignment in file
ohOsMajor	WORD	0		;required os major version number
ohOsMinor	WORD	0		;required os minor version number
ohImageMajor	WORD	0		;image major version number
ohImageMinor	WORD	0		;image minor version number
ohSubSysMajor	WORD	0		;subsystem major version number
ohSubSysMinor	WORD	0		;subsystem minor version number
ohReserved1	DWORD	0		;(reserved)
ohImageSize	DWORD	0		;size of image including all headers
ohHeaderSize	DWORD	0		;size of mz/pe header and section table
ohFileChecksum	DWORD	0		;file checksum (drivers and services)
ohSubSystem	WORD	0		;required subsystem
ohDllFlags	WORD	0		;(obsolete)
ohStackReserve	DWORD	0		;size of stack space to reserve
ohStackCommit	DWORD	0		;size of stack space to commit
ohHeapReserve	DWORD	0		;size of local heap space to reserve
ohHeapCommit	DWORD	0		;size of local heap space to commit
ohLoaderFlags	DWORD	0		;(obsolete)
ohNumDataDir	DWORD	0		;number of data directory entries
ohExportAddr	DWORD	0		;export table address
ohExportSize	DWORD	0		;export table size
ohImportAddr	DWORD	0		;import table address
ohImportSize	DWORD	0		;import table size
ohResourceAddr	DWORD	0		;resource table address
ohResourceSize	DWORD	0		;resource table size
ohExceptionAddr	DWORD	0		;exception table address
ohExceptionSize	DWORD	0		;exception table size
ohSecurityAddr	DWORD	0		;security table address
ohSecuritySize	DWORD	0		;security table size
ohBaseRelocAddr	DWORD	0		;base relocation table address
ohBaseRelocSize	DWORD	0		;base relocation table size
ohDebugDataAddr	DWORD	0		;debug data address
ohDebugDataSize	DWORD	0		;debug data size
ohCopyrightAddr	DWORD	0		;copyright string address
ohCopyrightSize	DWORD	0		;copyright string length
ohGlobalPtrAddr	DWORD	0		;global pointer register address
ohGlobalPtrSize	DWORD	0		;global pointer register size
ohTlsAddr	DWORD	0		;thread local storage table address
ohTlsSize	DWORD	0		;thread local storage table size
ohLoadConfAddr	DWORD	0		;load configuration table address
ohLoadConfSize	DWORD	0		;load configuration table size
ohReservedAddr1	DWORD	0		;(reserved)
ohReservedSize1	DWORD	0		;(reserved)
ohReservedAddr2	DWORD	0		;(reserved)
ohReservedSize2	DWORD	0		;(reserved)
ohReservedAddr3	DWORD	0		;(reserved)
ohReservedSize3	DWORD	0		;(reserved)
ohReservedAddr4	DWORD	0		;(reserved)
ohReservedSize4	DWORD	0		;(reserved)
ohReservedAddr5	DWORD	0		;(reserved)
ohReservedSize5	DWORD	0		;(reserved)
PE_OPT_HEADER	ends
PE_OPT_HEADER_	equ	2+1+1+4+4+4+4+4+4+\
                        4+4+4+2+2+2+2+2+2+4+4+4+4+2+2+4+4+4+4+4+4+\
			8+8+8+8+8+8+8+8+8+8+8+8+8+8+8+8
;
;------------------------------------------------------------------------------
;
SECTION_HEADER	struct
shSectionName	BYTE	8 dup (0)	;section name
shLoadSize	DWORD	0		;section size in memory
shLoadAddr	DWORD	0		;section offset in memory
shRawSize	DWORD	0		;section size in file
shRawAddr	DWORD	0		;section offset in file
shRelocations	DWORD	0		;pointer to relocation entries
shLineNumbers	DWORD	0		;pointer to line number entries
shNumRelocs	WORD	0		;number of relocation entries
shNumLines	WORD	0		;number of line number entries
shAttributes	DWORD	0		;section attributes
SECTION_HEADER	ends
SECTION_HEADER_	equ	8+4+4+4+4+4+4+2+2+4
;
;------------------------------------------------------------------------------
;
EXPORT_DIR	struct
edExportFlags	DWORD	0		;export flags
edTimeDate	DWORD	0		;time/date stamp
edVersionMajor	WORD	0		;major version number
edVersionMinor	WORD	0		;minor version number
edFileName	DWORD	0		;pointer to file name
edOrdinalBase	DWORD	0		;starting ordinal number (bias)
edNumAddresses	DWORD	0		;number of address entries
edNumNames	DWORD	0		;number of name entries
edAddresses	DWORD	0		;pointer to address table
edNames		DWORD	0		;pointer to name table
edOrdinals	DWORD	0		;pointer to ordinal table
EXPORT_DIR	ends
EXPORT_DIR_	equ	4+4+2+2+4+4+4+4+4+4+4
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
	mov	si,offset sMemoryError		;memory allocation error
	mov	al,RET_MEMORY_ERROR
	jb	Main1
	mov	si,offset sBanner		;display banner
	call	InfoString
	call	ParseCommandLine		;parse command line
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
;	no parameters
;
;------------------------------------------------------------------------------
;
ParseCommandLine:
	mov	si,COMMAND_TAIL			;evaluate command tail
	mov	di,InputFile			;copy input file path
	mov	cx,InputFile_
ParseCommandLine1:
	inc	si				;skip initial spaces
	cmp	byte ptr es:[si-1],' '
	jz	ParseCommandLine1
	dec	si
	mov	bx,di				;set end marker
ParseCommandLine2:
	cmp	cx,1				;buffer full?
	jna	ParseCommandLine3
	mov	al,es:[si]			;copy character
	inc	si
	mov	[di],al
	inc	di
	dec	cx
	cmp	al,CR				;end?
	jz	ParseCommandLine3
	cmp	al,' '				;look for trailing spaces
	jz	ParseCommandLine2
	mov	bx,di				;advance end marker
	jmp	ParseCommandLine2
ParseCommandLine3:
	mov	byte ptr [bx],0			;terminate string
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
	mov	bx,InputFile			;test input file path
	cmp	byte ptr [bx],1
	mov	si,offset sInvalidCommand
	mov	al,RET_INVALID_COMMAND
	jb	Execute2
	mov	si,InputFile			;open input file
	call	OpenFile
	mov	si,offset sFileNotFound		;input file not found
	mov	al,RET_FILE_NOT_FOUND
	jb	Execute2
	call	LoadFileHeaders			;load mz/pe file headers
	jb	Execute1
	call	LoadExportDir			;find export directory
	jb	Execute1
	call	DumpExportTable			;dump exported names
Execute1:
	pushf
	push	si
	push	ax
	call	CloseFile			;close input file
	pop	ax
	pop	si
	popf
	jb	Execute2			;error
	mov	si,offset sNormalEnd		;ok
	mov	al,RET_NORMAL_END
Execute2:
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
LoadFileHeaders:
	mov	di,MZ_Header			;read dos stub header
	mov	cx,MZ_HEADER_
	call	ReadFileBlock
	mov	si,offset sUnknownFileType	;incomplete dos stub header
	mov	al,RET_NO_PE_FILE
	jb	LoadFileHeaders1
	mov	bx,MZ_Header			;evaluate dos stub header
	mov	dx,[bx.mzSignature]		;dos executable?
	xchg	dl,dh
	cmp	dx,'MZ'
	stc
	mov	si,offset sUnknownFileType
	mov	al,RET_NO_PE_FILE
	jnz	LoadFileHeaders1
	cmp	word ptr [bx.mzRelocTable],40h	;test new-exe id
	stc
	mov	si,offset sMzExecutable
	mov	al,RET_NO_PE_FILE
	jnz	LoadFileHeaders1
	mov	ax,word ptr [bx.mzNextHeader]	;move to next header
	mov	dx,word ptr [bx.mzNextHeader+2]
	call	SetFilePointer
	mov	si,offset sUnknownFileType	;error
	mov	al,RET_NO_PE_FILE
	jb	LoadFileHeaders1
	call	ReadFileWord			;read signature
	mov	dx,ax
	xchg	dl,dh
	mov	si,offset sUnknownFileType	;incomplete header
	mov	al,RET_NO_PE_FILE
	jb	LoadFileHeaders1
	cmp	dx,'NE'				;new executable?
	stc
	mov	si,offset sNeExecutable
	mov	al,RET_NO_PE_FILE
	jz	LoadFileHeaders1
	cmp	dx,'LE'				;linear windows executable?
	stc
	mov	si,offset sLeExecutable
	mov	al,RET_NO_PE_FILE
	jz	LoadFileHeaders1
	cmp	dx,'LX'				;linear os/2 executable?
	stc
	mov	si,offset sLxExecutable
	mov	al,RET_NO_PE_FILE
	jz	LoadFileHeaders1
	cmp	dx,'PE'				;portable executable?
	stc
	mov	si,offset sUnknownFileType
	mov	al,RET_NO_PE_FILE
	jnz	LoadFileHeaders1
	call	ReadFileWord			;read 2nd half of signature
	mov	dx,ax
	mov	si,offset sUnknownFileType	;error
	mov	al,RET_NO_PE_FILE
	jb	LoadFileHeaders1
	add	dx,-1				;pe signature ok?
	jb	LoadFileHeaders1
	mov	di,PE_Header			;read pe main header
	mov	cx,PE_HEADER_
	call	ReadFileBlock
	mov	si,offset sBadFileHeader	;incomplete pe main header
	mov	al,RET_BAD_PE_FILE
	jb	LoadFileHeaders1
	mov	di,PE_OptHeader			;read pe optional header
	mov	cx,PE_OPT_HEADER_
	call	ReadFileBlock
	mov	si,offset sBadFileHeader	;incomplete pe optional header
	mov	al,RET_BAD_PE_FILE
	jb	LoadFileHeaders1
	clc					;ok
	mov	si,0
	mov	al,RET_NORMAL_END
LoadFileHeaders1:
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
LoadExportDir:
	mov	bx,PE_OptHeader			;test export table size
	mov	ax,word ptr [bx.ohExportSize]
	or	ax,word ptr [bx.ohExportSize+2]
	stc					;no export section
	mov	si,offset sNoExports
	mov	al,RET_NO_EXPORTS
	jz	LoadExportDir2
	mov	bx,PE_Header			;load number of sections
	mov	cx,[bx.peNumSections]
LoadExportDir1:
	sub	cx,1				;count sections
	mov	si,offset sExportsNotFound	;export section not found
	mov	al,RET_NO_EXPORTS
	jb	LoadExportDir2
	push	cx
	mov	di,SectionHeader		;read next section header
	mov	cx,SECTION_HEADER_
	call	ReadFileBlock
	pop	cx
	mov	si,offset sBadSectionHeader	;incomplete section header
	mov	al,RET_BAD_PE_FILE
	jb	LoadExportDir2
	mov	bx,PE_OptHeader			;load section address
	mov	ax,word ptr [bx.ohExportAddr]
	mov	dx,word ptr [bx.ohExportAddr+2]
	mov	bx,SectionHeader		;test section header
	sub	ax,word ptr [bx.shLoadAddr]	;section address too low?
	sbb	dx,word ptr [bx.shLoadAddr+2]
	jb	LoadExportDir1
	sub	ax,word ptr [bx.shLoadSize]	;section address too high?
	sbb	dx,word ptr [bx.shLoadSize+2]
	jnb	LoadExportDir1
	add	ax,word ptr [bx.shLoadSize]	;restore section offset
	adc	dx,word ptr [bx.shLoadSize+2]
	add	ax,word ptr [bx.shRawAddr]	;restore section offset
	adc	dx,word ptr [bx.shRawAddr+2]
	call	SetFilePointer
	mov	si,offset sExportsNotFound	;error
	mov	al,RET_NO_EXPORTS
	jb	LoadExportDir2
	mov	di,ExportDir			;read export directory
	mov	cx,EXPORT_DIR_
	call	ReadFileBlock
	mov	si,offset sBadExportDir		;incomplete export directory
	mov	al,RET_BAD_EXPORT_DIR
	jb	LoadExportDir2
	mov	bx,ExportDir			;test number of exported names
	mov	ax,word ptr [bx.edNumNames]
	or	ax,word ptr [bx.edNumNames+2]
	stc					;no exported names
	mov	si,offset sNoExportedNames
	mov	al,RET_NO_EXPORTS
	jz	LoadExportDir2
	mov	bx,SectionHeader		;compute memory bias
	mov	ax,word ptr [bx.shLoadAddr]
	mov	dx,word ptr [bx.shLoadAddr+2]
	sub	ax,word ptr [bx.shRawAddr]
	sbb	dx,word ptr [bx.shRawAddr+2]
	mov	word ptr dMemoryBias,ax
	mov	word ptr dMemoryBias+2,dx
	clc					;ok
	mov	si,0
	mov	al,RET_NORMAL_END
LoadExportDir2:
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
DumpExportTable:
	mov	si,offset sSectionName		;display section name
	call	InfoString
	push	si
	mov	bx,SectionHeader
	call	DumpSectionName
	pop	si
	call	InfoString
	mov	si,offset sRecordHeader		;start record header
	call	OutputString
	push	si
	mov	bx,ExportDir			;insert exported file name
	mov	ax,word ptr [bx.edFileName]
	mov	dx,word ptr [bx.edFileName+2]
	call	DumpFileString
	pop	si
	pushf
	call	OutputString			;complete record header
	popf
	jb	DumpExportTable4		;error
	mov	bx,ExportDir			;load number of exported names
	mov	ax,word ptr [bx.edNumNames]	;set name count
	mov	dx,word ptr [bx.edNumNames+2]
	mov	word ptr dNumNames,ax
	mov	word ptr dNumNames+2,dx
	mov	ax,word ptr [bx.edNames]	;set name table pointer
	mov	dx,word ptr [bx.edNames+2]
	mov	word ptr dNames,ax
	mov	word ptr dNames+2,dx
	mov	ax,word ptr [bx.edOrdinals]	;set ordinal table pointer
	mov	dx,word ptr [bx.edOrdinals+2]
	mov	word ptr dOrdinals,ax
	mov	word ptr dOrdinals+2,dx
	mov	cx,NUM_NAMES			;load block size
DumpExportTable1:
	sub	word ptr dNumNames,cx		;count names
	sbb	word ptr dNumNames+2,0
	jnb	DumpExportTable2		;load complete block
	add	cx,word ptr dNumNames
	jz	DumpExportTable5		;no more names
DumpExportTable2:
	push	cx
	mov	ax,word ptr dNames		;move to name pointer table
	mov	dx,word ptr dNames+2
	sub	ax,word ptr dMemoryBias
	sbb	dx,word ptr dMemoryBias+2
	call	SetFilePointer
	pop	cx
	jb	DumpExportTable4		;error
	push	cx
	mov	di,Names			;read name pointers
	shl	cx,1
	shl	cx,1
	add	word ptr dNames,cx
	adc	word ptr dNames+2,0
	call	ReadFileBlock
	pop	cx
	jb	DumpExportTable4		;error
	push	cx
	mov	ax,word ptr dOrdinals		;move to ordinal number table
	mov	dx,word ptr dOrdinals+2
	sub	ax,word ptr dMemoryBias
	sbb	dx,word ptr dMemoryBias+2
	call	SetFilePointer
	pop	cx
	jb	DumpExportTable4		;error
	push	cx
	mov	di,Ordinals			;read ordinal numbers
	shl	cx,1
	add	word ptr dOrdinals,cx
	adc	word ptr dOrdinals+2,0
	call	ReadFileBlock
	pop	cx
	jb	DumpExportTable4		;error
	mov	di,0
DumpExportTable3:
	push	cx
	push	di
	mov	si,offset sRecordData		;start record data line
	call	OutputString
	pop	di
	push	di
	push	si
	mov	bx,Names			;insert name
	shl	di,1
	shl	di,1
	mov	ax,[bx+di]
	mov	dx,[bx+di+2]
	call	DumpFileString
	pop	si
	sbb	al,al				;save error flag
	push	ax
	call	OutputString			;continue record data line
	pop	ax
	pop	di
	push	di
	push	ax
	mov	bx,Ordinals			;load ordinal number
	shl	di,1
	mov	ax,[bx+di]
	mov	dx,0
	push	dx
	push	ax
	push	si
	call	DumpDecimalNumber		;insert unbiased ordinal number
	pop	si
	call	OutputString			;continue record data line
	pop	ax
	pop	dx
	push	si
	mov	bx,ExportDir			;insert biased ordinal number
	add	ax,word ptr [bx.edOrdinalBase]
	adc	dx,word ptr [bx.edOrdinalBase+2]
	call	DumpDecimalNumber
	pop	si
	call	OutputString			;complete record data line
	pop	ax
	pop	di
	pop	cx
	add	al,al				;test error flag
	jb	DumpExportTable4
	inc	di				;count names
	cmp	di,cx
	jb	DumpExportTable3		;next record data line
	cmp	cx,NUM_NAMES			;last block?
	jnz	DumpExportTable5
	jmp	DumpExportTable1		;next block
DumpExportTable4:
	stc					;error
	mov	si,offset sBadExportData
	mov	al,RET_BAD_EXPORT_DATA
	jmp	DumpExportTable6
DumpExportTable5:
	clc					;ok
	mov	si,0
	mov	al,RET_NORMAL_END
DumpExportTable6:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  image offset
;
;	<	    c  -  set if error
;
;------------------------------------------------------------------------------
;
DumpFileString:
	mov	bx,ax				;null pointer?
	or	bx,dx
	sub	bx,1
	jb	DumpFileString1
	sub	ax,word ptr dMemoryBias		;compute file offset
	sbb	dx,word ptr dMemoryBias+2
	call	SetFilePointer			;move to string base
	jb	DumpFileString1
	mov	di,StringBuffer			;read string
	mov	cx,StringBuffer_
	call	ReadFileString
	jb	DumpFileString1
	mov	si,StringBuffer			;display string
	call	OutputString
	clc					;ok
DumpFileString1:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  binary number
;
;------------------------------------------------------------------------------
;
DumpDecimalNumber:
	mov	di,NumberBuffer			;convert to string
	call	NumberToString
	mov	si,NumberBuffer			;display string
	jmp	OutputString
;
;==============================================================================
;
;	>	bx  -  section header
;
;------------------------------------------------------------------------------
;
DumpSectionName:
	lea	dx,[bx.shSectionName]		;get section name address
	mov	si,dx				;scan section name
	mov	cx,8
DumpSectionName1:
	cmp	byte ptr [si],0			;end?
	jz	DumpSectionName2
	inc	si				;go on
	loop	DumpSectionName1
DumpSectionName2:
	mov	cx,si				;compute name length
	sub	cx,dx
	jz	DumpSectionName3		;no data
	mov	bx,STDERR			;display section name
	mov	ah,DOS_WRITE
	int	DOS
DumpSectionName3:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  binary number
;		   di  -  buffer (11 bytes)
;
;------------------------------------------------------------------------------
;
NumberToString:
	push	di				;save buffer base
	add	di,10				;write backwards to buffer
	mov	byte ptr [di],0
NumberToString1:
	push	di
	mov	bx,10				;extract digit
	call	Divide
	pop	di
	dec	di				;save digit
	add	bl,'0'
	mov	[di],bl
	mov	bx,ax				;more digits?
	or	bx,dx
	jnz	NumberToString1
	mov	si,di				;left justify
	pop	di
NumberToString2:
	mov	al,[si]				;copy digits
	inc	si
	mov	[di],al
	inc	di
	cmp	al,0				;end?
	jnz	NumberToString2
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
	shl	ax,1				;shift dividend to remainder
	rcl	dx,1
	rcl	bx,1
	adc	al,0				;save remainder bit
	sub	bx,si				;try subtraction
	jnb	Divide2				;ok
	ror	al,1				;was remainder > ffff?
	rol	al,1
	jb	Divide3				;ok
	add	bx,si				;undo subtraction
Divide2:
	cmc
Divide3:
	rcr	al,1				;save result bit
	rol	al,1
	loop	Divide1
	ret
;
;==============================================================================
;
;	CONSOLE I/O
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
	jz	OutputString2			;no data
	push	si
	mov	bx,STDOUT			;display string
	mov	ah,DOS_WRITE
	int	DOS
	pop	si
OutputString2:
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
	jz	InfoString2			;no data
	push	si
	mov	bx,STDERR			;display string
	mov	ah,DOS_WRITE
	int	DOS
	pop	si
InfoString2:
	ret
;
;==============================================================================
;
;	FILE I/O
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
OpenFile:
	mov	word ptr dFileBlockOffset,0	;clear data block offset
	mov	word ptr dFileBlockOffset+2,0
	mov	wFileBlockPointer,0		;clear data block pointer
	mov	wFileBlockEnd,0			;clear data block end pointer
	mov	dx,si				;open file
	mov	al,0
	mov	ah,DOS_OPEN
	int	DOS
	mov	hFile,0				;clear file handle
	jb	OpenFile1			;error
	mov	hFile,ax			;save file handle
OpenFile1:
	ret
;
;==============================================================================
;
;	<	ax  -  return code
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
CloseFile:
	mov	word ptr dFileBlockOffset,0	;clear data block offset
	mov	word ptr dFileBlockOffset+2,0
	mov	wFileBlockPointer,0		;clear data block pointer
	mov	wFileBlockEnd,0			;clear data block end pointer
	mov	ax,hFile			;file opened?
	cmp	ax,1
	jb	CloseFile1			;error
	mov	bx,ax				;close file
	mov	ah,DOS_CLOSE
	int	DOS
CloseFile1:
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
SetFilePointer:
	mov	di,word ptr dFileBlockOffset	;load data block offset
	mov	si,word ptr dFileBlockOffset+2
	mov	cx,ax				;file pointer above buffer?
	mov	bx,dx
	sub	cx,di
	sbb	bx,si
	jnb	SetFilePointer1
	sub	di,wFileBlockEnd		;compute buffer start offset
	sbb	si,0
	add	di,FileBuffer
	adc	si,0
	mov	cx,ax				;file pointer below buffer?
	mov	bx,dx
	sub	cx,di
	sbb	bx,si
	jb	SetFilePointer1
	add	cx,FileBuffer			;set data block pointer only
	mov	wFileBlockPointer,cx
	mov	ax,-1				;ok
	clc
	jmp	SetFilePointer2
SetFilePointer1:
	mov	word ptr dFileBlockOffset,ax	;save data block offset
	mov	word ptr dFileBlockOffset+2,dx
	mov	wFileBlockPointer,0		;clear data block pointer
	mov	wFileBlockEnd,0			;clear data block end pointer
	mov	ax,hFile			;file opened?
	cmp	ax,1
	jb	SetFilePointer2			;error
	mov	bx,ax				;set file pointer
	mov	dx,word ptr dFileBlockOffset
	mov	cx,word ptr dFileBlockOffset+2
	mov	al,0
	mov	ah,DOS_MOVEPOINTER
	int	DOS
SetFilePointer2:
	ret
;
;==============================================================================
;
;	<	dx:ax  -  file pointer
;
;------------------------------------------------------------------------------
;
GetFilePointer:
	mov	ax,word ptr dFileBlockOffset	;load data block offset
	mov	dx,word ptr dFileBlockOffset+2
	sub	ax,wFileBlockEnd		;consider buffer pointer
	sbb	dx,0
	add	ax,wFileBlockPointer
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
ReadFile:
	mov	wFileBlockPointer,FileBuffer	;init data block pointer
	mov	wFileBlockEnd,FileBuffer	;init data block end pointer
	mov	ax,hFile			;file opened?
	cmp	ax,1
	jb	ReadFile1			;error
	mov	bx,ax				;read data block
	mov	cx,FileBuffer_
	mov	dx,FileBuffer
	mov	ah,DOS_READ
	int	DOS
	jb	ReadFile1			;error
	add	word ptr dFileBlockOffset,ax	;compute data block offset
	adc	word ptr dFileBlockOffset+2,0
	add	wFileBlockEnd,ax		;set data block end pointer
	clc					;ok
ReadFile1:
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
ReadFileBlock:
	call	ReadFileByte			;read byte from input file
	mov	[di],al				;save byte
	inc	di
	loop	ReadFileBlock			;count bytes
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
ReadFileString:
	call	ReadFileByte			;read byte from input file
	mov	[di],al				;save byte
	inc	di
	inc	al				;end of string?
	dec	al
	loopnz	ReadFileString			;count bytes
	mov	byte ptr [di-1],0		;terminate string
	ret
;
;==============================================================================
;
;	<	dx:ax  -  file word
;		    c  -  set if end of file
;
;	si, di not changed
;
;------------------------------------------------------------------------------
;
ReadFileDWord:
	call	ReadFileWord			;read low word
	mov	cx,ax
	call	ReadFileWord			;read high word
	mov	dx,ax				;load file dword
	mov	ax,cx
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
ReadFileWord:
	call	ReadFileByte			;read low byte
	mov	dl,al
	call	ReadFileByte			;read high byte
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
ReadFileByte:
	mov	bx,wFileBlockPointer		;load data block pointer
	cmp	wFileBlockEnd,bx		;end of data block?
	jz	ReadFileByte1			;load next data block
	mov	al,[bx]				;load file byte
	inc	wFileBlockPointer		;advance data block pointer
	ret					;nc = ok
ReadFileByte1:
	cmp	wFileBlockEnd,FileBuffer	;file buffer empty?
	stc
	jz	ReadFileByte2
	push	cx
	push	dx
	push	si
	push	di
	call	ReadFile			;load next data block
	pop	di
	pop	si
	pop	dx
	pop	cx
	jb	ReadFileByte2			;error
	cmp	wFileBlockEnd,FileBuffer+1	;end of file?
	jnb	ReadFileByte
ReadFileByte2:
	mov	al,0				;return 0 if end of file
	ret					;c = end of file
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
	WORD	128 dup (0)			;local stack
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
;	INITIALIZED DATA
;
;------------------------------------------------------------------------------
;
hFile			WORD	0
dFileBlockOffset	DWORD	0
wFileBlockPointer	WORD	FileBuffer
wFileBlockEnd		WORD	FileBuffer
;
;------------------------------------------------------------------------------
;
dMemoryBias		DWORD	0
dNumNames		DWORD	0
dNames			DWORD	0
dOrdinals		DWORD	0
;
;------------------------------------------------------------------------------
;
sBanner\
BYTE CR,LF
BYTE "________________________________________________________________",CR,LF
BYTE CR,LF
BYTE "                          PEexport.ASM",CR,LF
BYTE "                 PE Export Section Dumper V1.01",CR,LF
BYTE "        01-29-1996 Sven B. Schreiber sbs@psbs.franken.de",CR,LF
BYTE "                 This is Public Domain Software",CR,LF
BYTE "________________________________________________________________",CR,LF
BYTE CR,LF
BYTE 0
;
sNormalEnd\
BYTE CR,LF
BYTE "PEexport: Normal end.",CR,LF
BYTE 0
;
sMemoryError\
BYTE CR,LF
BYTE "PEexport: Memory allocation error.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sInvalidCommand\
BYTE CR,LF
BYTE "Usage: PEexport <input file>",CR,LF
BYTE 0
;
sFileNotFound\
BYTE CR,LF
BYTE "PEexport: Input file not found.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sMzExecutable\
BYTE CR,LF
BYTE "PEexport: Input file is a DOS executable.",CR,LF
BYTE 0
;
sNeExecutable\
BYTE CR,LF
BYTE "PEexport: Input file is a Win16 executable.",CR,LF
BYTE 0
;
sLeExecutable\
BYTE CR,LF
BYTE "PEexport: Input file is a Windows VxD executable.",CR,LF
BYTE 0
;
sLxExecutable\
BYTE CR,LF
BYTE "PEexport: Input file is an OS/2 executable.",CR,LF
BYTE 0
;
sUnknownFileType\
BYTE CR,LF
BYTE "PEexport: Input file is not a PE executable.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sBadFileHeader\
BYTE CR,LF
BYTE "PEexport: Bad input file header.",CR,LF
BYTE 0
;
sBadSectionHeader\
BYTE CR,LF
BYTE "PEexport: Bad input file section header.",CR,LF
BYTE 0
;
sBadExportDir\
BYTE CR,LF
BYTE "PEexport: Bad export directory table.",CR,LF
BYTE 0
;
sBadExportData\
BYTE CR,LF
BYTE "PEexport: Bad export data table.",CR,LF
BYTE 0
;
sExportsNotFound\
BYTE CR,LF
BYTE "PEexport: Export data section not found.",CR,LF
BYTE 0
;
sNoExports\
BYTE CR,LF
BYTE "PEexport: Input file doesn't export anything.",CR,LF
BYTE 0
;
sNoExportedNames\
BYTE CR,LF
BYTE "PEexport: Input file doesn't export any names.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sSectionName\
BYTE CR,LF,"Export section is '",0,"'",CR,LF,0
;
sRecordHeader\
BYTE CR,LF,"[",0,"]",CR,LF,0
;
sRecordData\
BYTE 0,"=",0,",",0,CR,LF,0
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
MZ_Header	equ	$  + XX
XX		=	XX + MZ_HEADER_
;
PE_Header	equ	$  + XX
XX		=	XX + PE_HEADER_
;
PE_OptHeader	equ	$  + XX
XX		=	XX + PE_OPT_HEADER_
;
;------------------------------------------------------------------------------
;
SectionHeader	equ	$  + XX
XX		=	XX + SECTION_HEADER_
;
ExportDir	equ	$  + XX
XX		=	XX + EXPORT_DIR_
;
;------------------------------------------------------------------------------
;
NUM_NAMES	equ	1000
;
Names_		equ	NUM_NAMES * 4
Names		equ	$  + XX
XX		=	XX + Names_
;
Ordinals_	equ	NUM_NAMES * 2
Ordinals	equ	$  + XX
XX		=	XX + Ordinals_
;
;------------------------------------------------------------------------------
;
InputFile_	equ	PATH_LENGTH
InputFile	equ	$  + XX
XX		=	XX + InputFile_
;
StringBuffer_	equ	0400h
StringBuffer	equ	$  + XX
XX		=	XX + StringBuffer_
;
NumberBuffer_	equ	10+1
NumberBuffer	equ	$  + XX
XX		=	XX + NumberBuffer_
;
FileBuffer_	equ	8000h
FileBuffer	equ	$  + XX
XX		=	XX + FileBuffer_
;
;==============================================================================
;
DataSegment_	equ	$ + XX
_data		ends
;
;==============================================================================
;
		end	Main

