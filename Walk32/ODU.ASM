;
;	________________________________________________________________
;
;	                            ODU.ASM
;	                  OMF Object File Dumper V2.00
;	        01-03-1996 Sven B. Schreiber sbs@psbs.franken.de
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
; Suggested MASM command line: ml /I. /Zm /c /Cp /FoODU.OBJ /Ta ODU.ASM
;
;==============================================================================
;
; Important Notes
; ---------------
;
; ODU is Public Domain Software and is distributed with the ASM source
; code included. This software package may be distributed freely on any media
; including bulletin board systems and Internet hosts, provided that all files
; are included and no fee is charged for the software. Although all code and
; documentation belongs to the Public Domain, I strongly recommend that all
; changes be documented properly, including the name of the author, the date,
; and what parts have been changed in which way. If you encounter any OMF files
; not properly handled by ODU, please e-mail them to me. Feel free to contact
; me at sbs@psbs.franken.de, 100557.177@compuserve.com, or sbs_msn@msn.com.
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
; 01-19-1993  V1.00  SBS  Original Version
;
;	Ugly, experimental piece of code, written in Turbo Pascal.
;
; 01-23-1993  V1.01  SBS  Upgrade
;
;	Supports multiple LNAMES records. Evaluates COMENT/Translator records
;	(Comment Class 00h).
;
; 01-03-1996  V2.00  SBS  Redesign
;
;	All code rewritten from scratch in assembly language. Supports 32-bit
;	record variants, OMF extensions, and library files. Numerous fixes and
;	enhancements. Supported record types: COMENT, EXTDEF, FIXUPP, GRPDEF,
;	LEDATA, LEXTDEF, LHEADR, LIDATA, LLNAMES, LNAMES, LPUBDEF, PUBDEF,
;	SEGDEF, THEADR, Record F0h (Library Header), and Record F1h (Library
;	End). From the OMF extensions (COMENT Class A0h), only IMPDEF is
;	currently supported.
;
;==============================================================================
;
; OMF File Header Check
; ---------------------
;
; Starting with version 2.00, ODU tests the input file header to ensure that
; the file is really an OMF formatted file. The test algorithm is derived from
; a few restrictions imposed on the file format by the OMF specification. In
; short, ODU requires the input file to start either with a valid Translator or
; Library Module Header Record, or a .LIB file header, followed by one of them.
; More formally, the algorithm can be stated as follows:
;
; (1) Read the first input file BYTE. In an OMF file, this is the record type
;     of the first OMF record. If it's not a Library Header Record (F0h), go to
;     step (4).
;
; (2) Read the next 16-bit WORD from the input file, which should be the
;     Library Header Record's length, and add the number of bytes just read
;     (i.e. three) to it. If the result is not a power of two in the range
;     16..32768, it's not an OMF file. Otherwise, save this value as the
;     Library Page Size.
;
; (3) Skip the Library Header Record and read the next input file BYTE. In a
;     properly formatted OMF file, this is the record type of the first OMF
;     record in the library's first object module.
;
; (4) If the last read input file BYTE is neither a THEADR nor a LHEADR record
;     type indicator, it's not an OMF file.
;
; (5) Read the next 16-bit WORD (record length) and the next BYTE (name string
;     length) from the input file. If the former is equal to the latter plus
;     two, classify the file as being OMF formatted. A THEADR or LHEADR record
;     carries just a name string in COUNT/NAME format. The record length must
;     be equal to the number of NAME bytes, plus one for the COUNT byte, plus
;     one for the record CHECKSUM byte.
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
DOS_OPEN		equ	3Dh		;open file
DOS_CLOSE		equ	3Eh		;close file
DOS_READ		equ	3Fh		;read file
DOS_WRITE		equ	40h		;write file
DOS_MOVEPOINTER		equ	42h		;move file pointer
DOS_ALLOCATE		equ	48h		;allocate memory block
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
RET_OUT_OF_MEMORY	equ	2		;not enough memory available
RET_INVALID_COMMAND	equ	3		;invalid command line
RET_FILE_NOT_FOUND	equ	4		;input file not found
RET_FILE_IO_ERROR	equ	5		;input file i/o error
RET_NO_OMF_FILE		equ	6		;input file format invalid
RET_BAD_RECORD		equ	7		;input file record is corrupt
;
;------------------------------------------------------------------------------
;
LF			equ	0Ah		;linefeed
CR			equ	0Dh		;carriage return
;
;==============================================================================
;
;	STRUCTURES
;
;==============================================================================
;
SYMBOL_TABLE		struct
stBuffer		WORD	0		;data buffer segment address
stArray			WORD	0		;pointer array base address
stSize			WORD	0		;maximum number of symbols
stIndex			WORD	0		;next index
stData			WORD	0		;next data offset
stBytes			WORD	0		;number of bytes per entry
SYMBOL_TABLE		ends
SYMBOL_TABLE_		equ	2+2+2+2+2+2
;
;------------------------------------------------------------------------------
;
SEGMENT_DATA		struct
sdSegmentName		WORD	0		;segment name index
sdClassName		WORD	0		;class name index
sdOverlayName		WORD	0		;overlay name index
sdLength		DWORD	0		;segment length
SEGMENT_DATA		ends
SEGMENT_DATA_		equ	2+2+2
;
;------------------------------------------------------------------------------
;
GROUP_DATA		struct
gdGroupName		WORD	0		;group name index
GROUP_DATA		ends
GROUP_DATA_		equ	2
;
;------------------------------------------------------------------------------
;
THREAD_DATA		struct
tdFrameMethod		BYTE	0		;frame method
tdFrameIndex		WORD	0		;frame index
tdTargetMethod		BYTE	0		;target method
tdTargetIndex		WORD	0		;target index
THREAD_DATA		ends
THREAD_DATA_		equ	1+2+1+2
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
	call	AllocateBuffers			;allocate buffers
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
AllocateBuffers:
	mov	bx,1000h			;allocate record buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	wRecordBuffer,ax
	jb	AllocateBuffers1
	mov	bx,1000h			;allocate name buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	NameTable.stBuffer,ax
	jb	AllocateBuffers1
	mov	bx,1000h			;allocate segment buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	SegmentTable.stBuffer,ax
	jb	AllocateBuffers1
	mov	bx,1000h			;allocate group buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	GroupTable.stBuffer,ax
	jb	AllocateBuffers1
	mov	bx,1000h			;allocate external buffer
	mov	ah,DOS_ALLOCATE
	int	DOS
	mov	ExternalTable.stBuffer,ax
	mov	si,0				;ok
	mov	al,RET_NORMAL_END
	jnb	AllocateBuffers2
AllocateBuffers1:
	mov	si,offset sOutOfMemory		;not enough memory available
	mov	al,RET_OUT_OF_MEMORY
AllocateBuffers2:
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
	call	TestFileType			;validate input file format
	jb	Execute1
	call	DumpRecords			;dump input file records
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
TestFileType:
	mov	bLibraryFile,0			;assume object file
	mov	wPageSize,1			;set object file page size
	call	ReadFileByte			;read record type
	jb	TestFileType5
	cmp	al,LibHdr			;library header?
	jnz	TestFileType2
	mov	bLibraryFile,1			;assume library file
	call	ReadFileWord			;read record length
	jb	TestFileType5
	add	ax,1+2				;compute page size
	jb	TestFileType4
	cmp	ax,0004h			;check against minimum
	jb	TestFileType4
	cmp	ax,8000h			;check against maximum
	ja	TestFileType4
	mov	cx,16				;count bits
	mov	dx,0
TestFileType1:
	ror	ax,1
	adc	dx,0
	loop	TestFileType1
	cmp	dx,1				;power of two?
	jnz	TestFileType4
	mov	wPageSize,ax			;set library file page size
	mov	dx,0				;move to next page
	call	SetFilePointer
	jb	TestFileType5
	call	ReadFileByte			;read record type
	jb	TestFileType5
TestFileType2:
	cmp	al,THEADR			;translator header?
	jz	TestFileType3
	cmp	al,LHEADR			;library module header?
	jnz	TestFileType4
TestFileType3:
	call	ReadFileWord			;read record length
	jb	TestFileType5
	push	ax
	call	ReadFileByte			;read name string length
	mov	dl,al
	mov	dh,0
	pop	ax
	jb	TestFileType5
	add	dx,1+1				;length byte + checksum byte
	cmp	dx,ax				;matching record length?
	jnz	TestFileType4
	mov	ax,0
	mov	dx,0
	call	SetFilePointer			;rewind file
	jb	TestFileType5
	mov	si,offset sNormalEnd		;ok
	mov	al,RET_NORMAL_END
	clc
	jmp	TestFileType6
TestFileType4:
	mov	si,offset sNoOmfFile		;not an omf file
	mov	al,RET_NO_OMF_FILE
	stc
	jmp	TestFileType6
TestFileType5:
	mov	si,offset sFileIoError		;file i/o error
	mov	al,RET_FILE_IO_ERROR
	stc
TestFileType6:
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
DumpRecords:
	push	es
	mov	es,wRecordBuffer		;address record buffer
DumpRecords1:
	call	ClearSymbolTables		;clear all symbol tables
DumpRecords2:
	call	GetFilePointer			;get record offset
	mov	word ptr dRecordOffset,ax
	mov	word ptr dRecordOffset+2,dx
	call	ReadFileByte			;read next record type
	mov	bRecordType,al
	jb	DumpRecords10			;done
	call	ReadFileWord			;read record length
	mov	wRecordLength,ax
	mov	si,offset sBadRecord		;incomplete record header
	mov	al,RET_BAD_RECORD
	jb	DumpRecords11
	call	ReadFileRecord
	mov	bRecordCheck,al
	mov	si,offset sBadRecord		;incomplete record data
	mov	al,RET_BAD_RECORD
	jb	DumpRecords11
	mov	al,bRecordType			;identify record type
	mov	bx,RecordTypes
DumpRecords3:
	mov	dl,[bx]				;load record type
	inc	bx
	mov	dh,[bx]				;load 32-bit flag
	inc	bx
	mov	si,bx				;save short name address
DumpRecords4:
	inc	bx				;skip short name
	cmp	byte ptr [bx-1],0
	jnz	DumpRecords4
	mov	di,bx				;save description address
DumpRecords5:
	inc	bx				;skip description
	cmp	byte ptr [bx-1],0
	jnz	DumpRecords5
	add	bx,2				;skip record handler
	mov	cx,offset sNull
	cmp	dl,0				;end of table?
	jz	DumpRecords6
	sub	dl,al				;entry found?
	jz	DumpRecords6
	add	dl,dh				;32-bit variant?
	jnz	DumpRecords3
	mov	cx,offset s32Bit		;select 32-bit comment
DumpRecords6:
	push	[bx-2]				;save record handler
	push	cx
	push	di
	push	si
	mov	si,offset sRecordCaption	;begin record caption
	call	OutputString
	pop	dx
	push	si
	mov	si,dx				;insert short name
	call	OutputString
	pop	si
	call	OutputString			;continue record caption
	push	si
	mov	al,bRecordType			;insert record type
	call	DumpHexByte
	pop	si
	call	OutputString			;continue record caption
	push	si
	mov	ax,word ptr dRecordOffset	;insert record offset
	mov	dx,word ptr dRecordOffset+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;continue record caption
	pop	dx
	push	si
	mov	si,dx				;insert description
	call	OutputString
	pop	si
	pop	cx
	push	si
	mov	si,cx				;insert comment if any
	call	OutputString
	mov	al,bRecordType			;no checksum in library records
	cmp	al,LibHdr
	jz	DumpRecords7
	cmp	al,LibEnd
	jz	DumpRecords7
	cmp	bRecordCheck,0			;checksum ok?
	jz	DumpRecords7
	mov	si,offset sChecksumError	;insert error message
	call	OutputString
DumpRecords7:
	pop	si
	call	OutputString			;end record caption
	pop	cx
	jcxz	DumpRecords8			;no record handler available
	mov	bInsertLine,1
	call	cx				;call record handler
	mov	bInsertLine,0
DumpRecords8:
	cmp	bLibraryFile,0			;library file?
	jz	DumpRecords2
	mov	al,bRecordType			;test record type
	cmp	al,LibHdr			;library header?
	jnz	DumpRecords9
	mov	si,offset sModuleSeparator	;separate modules
	call	OutputString
	jmp	DumpRecords2			;next record
DumpRecords9:
	cmp	al,LibEnd			;library end?
	jz	DumpRecords10
	and	al,11111110b
	cmp	al,MODEND			;module end?
	jnz	DumpRecords2			;next record
	mov	si,offset sModuleSeparator	;separate modules
	call	OutputString
	call	GetFilePointer			;get current file position
	mov	cx,wPageSize			;make page bitmask
	neg	cx
	sub	ax,1				;compute next page boundary
	sbb	dx,0
	and	ax,cx
	add	ax,wPageSize
	adc	dx,0
	call	SetFilePointer			;move to next page
	mov	si,offset sFileIoError		;file i/o error
	mov	al,RET_FILE_IO_ERROR
	jb	DumpRecords11
	jmp	DumpRecords1			;next library module
DumpRecords10:
	clc					;ok
	mov	si,0
	mov	al,RET_NORMAL_END
DumpRecords11:
	pop	es
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
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
GetRecordString:
	mov	bx,wRecordLength		;record offset ok?
	sub	bx,si
	jb	GetRecordString2
	sub	bx,2				;end of record?
	jb	GetRecordString2
	mov	dl,es:[si]			;load string length
	mov	dh,0
	cmp	bx,dx				;string length ok?
	jb	GetRecordString2
	inc	si				;load source pointer
	mov	bx,si
	add	si,dx				;compute next record offset
GetRecordString1:
	cmp	bx,si				;end of string?
	jnb	GetRecordString2
	mov	al,es:[bx]			;copy character
	inc	bx
	mov	[di],al
	inc	di
	loop	GetRecordString1		;next character
	dec	di				;delete last character
	clc					;not end of record
GetRecordString2:
	mov	byte ptr [di],0			;terminate string
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
	sub	cx,2				;end of record?
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
	sub	cx,5				;end of record?
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
	sub	cx,3				;end of record?
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
	sub	cx,2				;end of record?
	jb	GetRecordByte1
	mov	al,es:[si]			;load data byte
	inc	si
	clc					;ok
GetRecordByte1:
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
;	no parameters
;
;------------------------------------------------------------------------------
;
ClearSymbolTables:
	mov	bx,NameTable			;reset name table
	mov	[bx.stArray],NameArray
	mov	[bx.stSize],MAX_NAMES
	mov	[bx.stIndex],0
	mov	[bx.stData],0
	mov	[bx.stBytes],0
	mov	si,offset sUndefined		;add dummy entry
	call	AddSymbol
	mov	bx,SegmentTable			;reset segment table
	mov	[bx.stArray],SegmentArray
	mov	[bx.stSize],MAX_SEGMENTS
	mov	[bx.stIndex],0
	mov	[bx.stData],0
	mov	[bx.stBytes],SEGMENT_DATA_
	mov	si,SegmentData			;add dummy entry
	mov	[si.sdSegmentName],0
	mov	[si.sdClassName],0
	mov	[si.sdOverlayName],0
	mov	word ptr [si.sdLength],0
	mov	word ptr [si.sdLength+2],0
	call	AddData
	mov	bx,GroupTable			;reset group table
	mov	[bx.stArray],GroupArray
	mov	[bx.stSize],MAX_GROUPS
	mov	[bx.stIndex],0
	mov	[bx.stData],0
	mov	[bx.stBytes],GROUP_DATA_
	mov	si,GroupData			;add dummy entry
	mov	[si.gdGroupName],0
	call	AddData
	mov	bx,ExternalTable		;reset external table
	mov	[bx.stArray],ExternalArray
	mov	[bx.stSize],MAX_EXTERNALS
	mov	[bx.stIndex],0
	mov	[bx.stData],0
	mov	[bx.stBytes],0
	mov	si,offset sUndefined		;add dummy entry
	jmp	AddSymbol
;
;==============================================================================
;
;	>	bx  -  symbol table
;		si  -  symbol string
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
AddSymbol:
	push	es
	mov	es,[bx.stBuffer]		;load buffer segment address
	mov	dx,[bx.stIndex]			;test index
	cmp	dx,[bx.stSize]
	cmc					;array overflow
	jb	AddSymbol2
	mov	di,[bx.stData]			;load data offset
AddSymbol1:
	mov	al,[si]				;copy character
	inc	si
	mov	es:[di],al
	inc	di
	stc					;buffer overflow
	jz	AddSymbol2
	cmp	al,0				;end of string?
	jnz	AddSymbol1			;next character
	xchg	di,[bx.stData]			;get/set data offset
	mov	si,[bx.stArray]			;save pointer to symbol
	add	si,dx
	add	si,dx
	mov	[si],di	
	inc	dx				;save next index
	mov	[bx.stIndex],dx
	clc					;ok
AddSymbol2:
	pop	es
	ret
;
;==============================================================================
;
;	>	bx  -  symbol table
;		si  -  data
;
;	<	 c  -  set if error
;
;------------------------------------------------------------------------------
;
AddData:
	push	es
	mov	es,[bx.stBuffer]		;load buffer segment address
	mov	dx,[bx.stIndex]			;test index
	cmp	dx,[bx.stSize]
	cmc					;array overflow
	jb	AddData2
	mov	di,[bx.stData]			;load data offset
	mov	cx,[bx.stBytes]			;load number of bytes
AddData1:
	mov	al,[si]				;copy data byte
	inc	si
	mov	es:[di],al
	inc	di
	stc					;buffer overflow
	jz	AddData2
	loop	AddData1			;next data byte
	xchg	di,[bx.stData]			;get/set data offset
	mov	si,[bx.stArray]			;save pointer to symbol
	add	si,dx
	add	si,dx
	mov	[si],di	
	inc	dx				;save next index
	mov	[bx.stIndex],dx
	clc					;ok
AddData2:
	pop	es
	ret
;
;==============================================================================
;
;	>	ax  -  index
;		bx  -  symbol table
;		di  -  buffer
;		cx  -  buffer size
;
;	<	 c  -  set if invalid index
;
;------------------------------------------------------------------------------
;
RetrieveSymbol:
	push	es
	mov	es,[bx.stBuffer]		;load buffer segment address
	cmp	ax,[bx.stIndex]			;test index
	cmc
	jnb	RetrieveSymbol1
	mov	ax,0				;use dummy index
RetrieveSymbol1:
	pushf
	mov	si,[bx.stArray]			;locate string pointer
	add	si,ax
	add	si,ax
	mov	si,[si]				;load string pointer
RetrieveSymbol2:
	mov	al,es:[si]			;copy character
	inc	si
	mov	[di],al
	inc	di
	cmp	al,0				;end of string?
	loopnz	RetrieveSymbol2			;next character
	dec	di
	mov	byte ptr [di],0			;terminate string
	popf
	pop	es
	ret
;
;==============================================================================
;
;	>	ax  -  index
;		bx  -  symbol table
;		di  -  buffer
;
;	<	 c  -  set if invalid index
;
;------------------------------------------------------------------------------
;
RetrieveData:
	push	es
	mov	es,[bx.stBuffer]		;load buffer segment address
	cmp	ax,[bx.stIndex]			;test index
	cmc
	jnb	RetrieveData1
	mov	ax,0				;use dummy index
RetrieveData1:
	pushf
	mov	si,[bx.stArray]			;locate string pointer
	add	si,ax
	add	si,ax
	mov	si,[si]				;load string pointer
	mov	cx,[bx.stBytes]			;load number of bytes
RetrieveData2:
	mov	al,es:[si]			;copy data byte
	inc	si
	mov	[di],al
	inc	di
	loop	RetrieveData2			;next data byte
	popf
	pop	es
	ret
;
;==============================================================================
;
;	>	si  -  text table
;		al  -  bit array
;		ah  -  bit mask
;
;	<	si  -  text
;
;------------------------------------------------------------------------------
;
SelectText:
	mov	cl,0				;clear selection count
	mov	ch,8				;load bit count
SelectText1:
	shl	ax,1				;evaluate next bit
	jnb	SelectText2
	ror	ah,1				;copy selection bit
	rol	ah,1
	rcl	cl,1
SelectText2:
	dec	ch				;next bit
	jnz	SelectText1
SelectText3:
	sub	cl,1				;text found?
	jb	SelectText5
SelectText4:
	inc	si				;skip text
	cmp	byte ptr [si-1],0
	jnz	SelectText4
	jmp	SelectText3			;try again
SelectText5:
	ret
;
;==============================================================================
;
;	RECORD HANDLERS
;
;==============================================================================
;
THEADR_Handler:
LHEADR_Handler:
	mov	si,0				;get module name
	mov	di,ModuleName
	mov	cx,ModuleName_
	call	GetRecordString
	mov	si,offset sModuleName		;display module name
	call	OutputString
	push	si
	mov	si,ModuleName
	call	OutputQuotedString
	pop	si
	jmp	OutputString
;
;==============================================================================
;
COMENT_Handler:
	mov	si,0				;load first record offset
	call	GetRecordByte			;get comment type
	jb	COMENT_Handler3			;error
	push	si
	mov	bx,offset sCommentType		;display comment type
	mov	si,CommentType
	mov	ah,11000000b
	call	DisplayBitText
	pop	si
	call	GetRecordByte			;get comment class
	mov	bCommentClass,al
	jb	COMENT_Handler3			;error
	mov	bx,CommentClasses		;detect comment class
COMENT_Handler1:
	mov	dl,[bx]				;load minimum
	inc	bx
	mov	dh,[bx]				;load maximum
	inc	bx
	mov	di,bx				;load description
COMENT_Handler2:
	inc	bx				;skip description
	cmp	byte ptr [bx-1],0
	jnz	COMENT_Handler2
	add	bx,2+2				;skip handler
	cmp	bCommentClass,dl		;check against minimum
	jb	COMENT_Handler1
	cmp	bCommentClass,dh		;check against maximum
	ja	COMENT_Handler1
	push	si
	push	[bx-2]
	push	[bx-4]
	push	di
	mov	si,offset sCommentClass		;begin comment class
	call	OutputString
	push	si
	mov	al,bCommentClass		;insert comment class hex
	call	DumpHexByte
	pop	si
	call	OutputString
	pop	di
	push	si
	mov	si,di				;insert comment class text
	call	OutputString
	pop	si
	call	OutputString			;end comment class
	pop	cx
	pop	bx
	pop	si
	jcxz	COMENT_Handler3			;no handler available
	call	cx				;call handler
COMENT_Handler3:
	ret
;
;------------------------------------------------------------------------------
;
OMFEXT_Handler:
	call	GetRecordByte			;get subtype
	mov	bOmfExtension,al
	jb	OMFEXT_Handler4
	mov	bx,OmfExtensions		;detect omf extension
OMFEXT_Handler1:
	mov	dl,[bx]				;load omf extension id
	inc	bx
	mov	di,bx				;load description
OMFEXT_Handler2:
	inc	bx				;skip description
	cmp	byte ptr [bx-1],0
	jnz	OMFEXT_Handler2
	add	bx,2				;skip handler
	cmp	dl,0				;end of table?
	jz	OMFEXT_Handler3
	cmp	dl,bOmfExtension		;entry found?
	jnz	OMFEXT_Handler1
OMFEXT_Handler3:
	push	si
	push	[bx-2]
	push	di
	mov	si,offset sOmfExtension		;begin omf extension
	call	OutputString
	push	si
	mov	al,bOmfExtension		;insert omf extension id
	call	DumpHexByte
	pop	si
	call	OutputString
	pop	di
	push	si
	mov	si,di				;insert omf extension text
	call	OutputString
	pop	si
	call	OutputString			;end omf extension
	pop	cx
	pop	si
	jcxz	OMFEXT_Handler4			;no handler available
	call	cx				;call handler
OMFEXT_Handler4:
	ret
;
;------------------------------------------------------------------------------
;
IMPDEF_Handler:
	call	GetRecordByte			;get ordinal flag
	jb	IMPDEF_Handler4
	mov	bx,si				;save offset of internal name
	push	ax
	push	bx
	mov	di,StringBuffer			;skip internal name
	mov	cx,StringBuffer_
	call	GetRecordString
	pop	bx
	pop	ax
	jb	IMPDEF_Handler4
	push	ax
	push	bx
	mov	bx,offset sImpdefModName	;display module name
	call	DisplayString
	pop	bx
	pop	ax
	jb	IMPDEF_Handler4
	push	si
	push	ax
	push	bx
	mov	si,bx				;display internal name
	mov	bx,offset sImpdefIntName
	call	DisplayString
	pop	bx
	pop	ax
	pop	si
	jb	IMPDEF_Handler4
	cmp	al,0				;ordinal or name?
	jz	IMPDEF_Handler1
	call	GetRecordWord			;get entry id ordinal
	jb	IMPDEF_Handler4
	mov	cx,DumpHexWord			;display entry id ordinal
	jmp	IMPDEF_Handler3
IMPDEF_Handler1:
	push	bx
	mov	di,StringBuffer			;read entry id name
	mov	cx,StringBuffer_
	call	GetRecordString
	pop	bx
	jb	IMPDEF_Handler4
	cmp	byte ptr StringBuffer,0		;explicitly specified?
	jnz	IMPDEF_Handler2
	mov	si,bx				;use internal name
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	GetRecordString
	jb	IMPDEF_Handler4
IMPDEF_Handler2:
	mov	bx,StringBuffer			;display entry id name
	mov	cx,OutputQuotedString
IMPDEF_Handler3:
	push	ax
	push	bx
	push	cx
	mov	si,offset sImpdefEntryId	;begin entry id
	call	OutputString
	pop	cx
	pop	bx
	pop	ax
	push	si
	mov	si,bx				;insert entry id name/ordinal
	call	cx
	pop	si
	call	OutputString			;end entry id
IMPDEF_Handler4:
	ret
;
;------------------------------------------------------------------------------
;
EXPDEF_Handler:
	ret
;
;------------------------------------------------------------------------------
;
INCDEF_Handler:
	ret
;
;------------------------------------------------------------------------------
;
LNKDIR_Handler:
	ret
;
;==============================================================================
;
MODEND_Handler:
	mov	si,0				;load first record offset
	call	GetRecordByte			;get module type
	jb	MODEND_Handler4			;error
	push	si
	push	ax
	mov	si,offset sModuleType		;start module type
	call	OutputString
	pop	ax
	push	si
	push	ax
	test	al,10000000b			;main module?
	mov	si,offset sModuleNonMain
	jz	MODEND_Handler1
	mov	si,offset sModuleMain
MODEND_Handler1:
	call	OutputString
	pop	ax
	push	ax
	test	al,01000000b			;start address defined?
	mov	si,offset sModuleNoStart
	jz	MODEND_Handler3
	test	al,00000001b			;fixup required?
	mov	si,offset sModuleNoFixup
	jz	MODEND_Handler2
	mov	si,offset sModuleFixup
MODEND_Handler2:
	call	OutputString
	mov	si,offset sModuleStart		;start address defined
MODEND_Handler3:
	call	OutputString
	pop	ax
	pop	si
	push	ax
	call	OutputString			;end module type
	pop	ax
	pop	si
	test	al,01000000b			;start address defined?
	jz	MODEND_Handler4
	call	DisplayFixupData		;display fixup data
MODEND_Handler4:
	ret
;
;==============================================================================
;
LEXTDEF_Handler:
EXTDEF_Handler:
	mov	si,0				;load first record offset
EXTDEF_Handler1:
	mov	di,StringBuffer			;read symbol string
	mov	cx,StringBuffer_
	call	GetRecordString
	jb	EXTDEF_Handler2			;end of record
	call	GetRecordIndex			;read type index
	push	si
	push	ax
	mov	bx,ExternalTable		;add symbol to external table
	mov	si,StringBuffer
	push	[bx.stIndex]
	call	AddSymbol
	mov	si,offset sExternal		;begin external symbol
	call	OutputString
	pop	ax
	push	si
	call	DumpHexWord			;insert symbol index
	pop	si
	call	OutputString
	pop	ax
	push	si
	call	DumpHexWord			;insert type index
	pop	si
	call	OutputString
	push	si
	mov	si,StringBuffer			;insert symbol string
	call	OutputQuotedString
	pop	si
	call	OutputString			;end external symbol
	pop	si
	jmp	EXTDEF_Handler1
EXTDEF_Handler2:
	ret
;
;==============================================================================
;
TYPDEF_Handler:
	ret
;
;==============================================================================
;
LPUBDEF_Handler:
PUBDEF_Handler:
	mov	si,0				;load first record offset
	mov	bx,offset sPubGroup		;display base group
	call	DisplayGroupName
	jb	PUBDEF_Handler5			;error
PUBDEF_Handler1:
	mov	bx,offset sPubSegment		;display base segment
	call	DisplaySegmentName
	jb	PUBDEF_Handler5			;error
	jnz	PUBDEF_Handler3			;no base frame specified
PUBDEF_Handler2:
	call	GetRecordWord			;get base frame
	jb	PUBDEF_Handler5			;error
	push	si
	push	ax
	mov	si,offset sPubFrame		;start base frame
	call	OutputString
	pop	ax
	push	si
	call	DumpHexWord			;insert base frame number
	pop	si
	call	OutputString			;end base frame
	pop	si
PUBDEF_Handler3:
	mov	di,StringBuffer			;read symbol string
	mov	cx,StringBuffer_
	call	GetRecordString
	jb	PUBDEF_Handler5			;end of record
	test	bRecordType,00000001b		;32-bit segment?
	mov	dx,GetRecordWord
	mov	di,DumpHexWord
	jz	PUBDEF_Handler4
	mov	dx,GetRecordDouble
	mov	di,DumpHexDouble
PUBDEF_Handler4:
	push	di
	call	dx				;get public offset
	push	dx
	push	ax
	call	GetRecordIndex			;get type index
	mov	cx,ax
	pop	ax
	pop	dx
	pop	di
	push	si
	push	di
	push	dx
	push	ax
	push	cx
	mov	bx,ExternalTable		;add symbol to external table
	mov	si,StringBuffer
	push	[bx.stIndex]
	call	AddSymbol
	mov	si,offset sPubName		;start public symbol
	call	OutputString
	pop	ax
	push	si
	call	DumpHexWord			;insert symbol index
	pop	si
	call	OutputString
	pop	cx
	push	si
	mov	ax,cx				;insert type index
	call	DumpHexWord
	pop	si
	call	OutputString
	pop	ax
	pop	dx
	pop	di
	push	si
	call	di				;insert public offset
	pop	si
	call	OutputString
	push	si
	mov	si,StringBuffer			;insert symbol string
	call	OutputQuotedString
	pop	si
	call	OutputString			;end public symbol
	pop	si
	jmp	PUBDEF_Handler3			;next symbol
PUBDEF_Handler5:
	ret
;
;==============================================================================
;
LINNUM_Handler:
	ret
;
;==============================================================================
;
LLNAMES_Handler:
LNAMES_Handler:
	mov	si,0				;load first record offset
LNAMES_Handler1:
	mov	di,StringBuffer			;read symbol string
	mov	cx,StringBuffer_
	call	GetRecordString
	jb	LNAMES_Handler2			;end of record
	push	si
	mov	bx,NameTable			;add symbol to name table
	mov	si,StringBuffer
	push	[bx.stIndex]
	call	AddSymbol
	mov	si,offset sName			;display symbol
	call	OutputString
	pop	ax
	push	si
	call	DumpHexWord			;insert symbol index
	pop	si
	call	OutputString
	push	si
	mov	si,StringBuffer			;insert symbol string
	call	OutputQuotedString
	pop	si
	call	OutputString
	pop	si
	jmp	LNAMES_Handler1
LNAMES_Handler2:
	ret
;
;==============================================================================
;
SEGDEF_Handler:
	mov	si,0				;load first record offset
	call	GetRecordByte			;get alignment type
	jb	SEGDEF_Handler4			;error
	push	si
	push	ax
	mov	si,offset sSegAlignment		;begin alignment type
	call	OutputString
	pop	ax
	push	si
	push	ax
	mov	ah,11100000b			;get alignment type
	mov	si,SegAlignment
	call	SelectText
	call	OutputString			;insert alignment type
	pop	ax
	pop	si
	mov	bx,si				;save remaining text
	pop	si
	test	al,11100000b			;type 0?
	clc
	push	ax
	push	bx
	jnz	SEGDEF_Handler2
	call	GetRecordWord			;get frame number
	mov	cx,ax
	jb	SEGDEF_Handler2
	push	cx
	call	GetRecordByte			;get offset
	pop	cx
	jb	SEGDEF_Handler2
	push	si
	push	ax
	push	cx
	mov	si,offset sSegAbsolute		;begin absolute location
	call	OutputString
	pop	cx
	push	si
	mov	ax,cx				;insert frame number
	call	DumpHexWord
	pop	si
	call	OutputString
	pop	ax
	push	si
	call	DumpHexByte			;insert offset
	pop	si
	call	OutputString			;end absolute location
	pop	si
SEGDEF_Handler2:
	pop	bx
	pushf
	push	si
	mov	si,bx				;end alignment type
	call	OutputString
	pop	si
	popf
	pop	ax
	jb	SEGDEF_Handler4			;error
	push	si
	push	ax
	mov	bx,offset sSegCombination	;display combination type
	mov	si,SegCombination
	mov	ah,00011100b
	call	DisplayBitText
	pop	ax
	push	ax
	mov	bx,offset sSegUse		;display use type
	mov	si,SegUse
	mov	ah,00000001b
	call	DisplayBitText
	pop	ax
	pop	si
	mov	bx,offset sSegLength		;display segment length
	call	DisplayAddress
	mov	word ptr SegmentData.sdLength,ax
	mov	word ptr SegmentData.sdLength+2,dx
SEGDEF_Handler4:
	call	GetRecordIndex			;get segment name index
	mov	SegmentData.sdSegmentName,ax
	call	GetRecordIndex			;get class name index
	mov	SegmentData.sdClassName,ax
	call	GetRecordIndex			;get overlay name index
	mov	SegmentData.sdOverlayName,ax
	mov	bx,SegmentTable			;add segment data
	mov	si,SegmentData
	call	AddData
	cmp	SegmentData.sdSegmentName,0	;segment name defined?
	jz	SEGDEF_Handler5
	mov	ax,SegmentData.sdSegmentName	;retrieve segment name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	cmp	byte ptr StringBuffer,0		;dummy name?
	jz	SEGDEF_Handler5
	mov	si,offset sSegName		;start segment name
	call	OutputString
	push	si
	mov	si,StringBuffer			;insert segment name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end segment name
SEGDEF_Handler5:
	cmp	SegmentData.sdClassName,0	;class name defined?
	jz	SEGDEF_Handler6
	mov	ax,SegmentData.sdClassName	;retrieve class name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	cmp	byte ptr StringBuffer,0		;dummy name?
	jz	SEGDEF_Handler6
	mov	si,offset sSegClass		;start class name
	call	OutputString
	push	si
	mov	si,StringBuffer			;insert class name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end class name
SEGDEF_Handler6:
	cmp	SegmentData.sdOverlayName,0	;overlay name defined?
	jz	SEGDEF_Handler7
	mov	ax,SegmentData.sdOverlayName	;retrieve overlay name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	cmp	byte ptr StringBuffer,0		;dummy name?
	jz	SEGDEF_Handler7
	mov	si,offset sSegOverlay		;start overlay name
	call	OutputString
	push	si
	mov	si,StringBuffer			;insert overlay name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end overlay name
SEGDEF_Handler7:
	ret
;
;==============================================================================
;
GRPDEF_Handler:
	mov	si,0				;load first record offset
	call	GetRecordIndex			;get group name index
	mov	GroupData.gdGroupName,ax
	jb	GRPDEF_Handler2			;error
	push	si
	mov	bx,GroupTable			;add group data
	mov	si,GroupData
	call	AddData
	mov	si,offset sGroupName		;begin group name
	call	OutputString
	push	si
	mov	ax,GroupData.gdGroupName	;retrieve group name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert group name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end group name
	pop	si
GRPDEF_Handler1:
	call	GetRecordByte			;read type byte
	mov	cl,al
	jb	GRPDEF_Handler2			;no more segments
	push	cx
	call	GetRecordIndex			;read segment name index
	pop	cx
	jb	GRPDEF_Handler2			;error
	push	si
	push	ax
	push	cx
	mov	si,offset sGroupSegment		;begin segment reference
	call	OutputString
	pop	cx
	push	si
	mov	al,cl				;insert type byte
	call	DumpHexByte
	pop	si
	call	OutputString
	pop	ax
	push	si
	mov	bx,SegmentTable			;retrieve segment data
	mov	di,SegmentData
	call	RetrieveData
	mov	ax,SegmentData.sdSegmentName	;retrieve segment name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert segment name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end segment reference
	pop	si
	jmp	GRPDEF_Handler1
GRPDEF_Handler2:
	ret
;
;==============================================================================
;
FIXUPP_Handler:
	mov	si,0				;load first record offset
FIXUPP_Handler1:
	mov	bInsertLine,1
	call	GetRecordByte			;get subrecord header
	jb	FIXUPP_Handler3			;end of record
	push	si
	push	ax
	mov	bx,offset sFixupSubrecord	;display fixup subrecord type
	mov	si,FixupSubrecord
	mov	ah,10000000b
	call	DisplayBitText
	pop	ax
	pop	si
	test	al,10000000b			;fixup subrecord?
	jnz	FIXUPP_Handler2
	call	DisplayThread			;thread subrecord
	jnb	FIXUPP_Handler1			;next subrecord
	jmp	FIXUPP_Handler3			;error
FIXUPP_Handler2:
	push	ax
	call	GetRecordByte			;get msb of subrecord header
	mov	dh,al
	pop	ax
	mov	ah,dh
	jb	FIXUPP_Handler3			;error
	call	DisplayFixup			;fixup subrecord
	jnb	FIXUPP_Handler1			;next subrecord
FIXUPP_Handler3:
	ret
;
;==============================================================================
;
LEDATA_Handler:
	mov	bCurrentDataIterated,0		;clear iteration flag
	mov	si,0				;load first record offset
	mov	bx,offset sDataSegment		;display segment
	call	DisplaySegmentName
	jb	LEDATA_Handler2			;error
	mov	wCurrentSegment,ax		;save segment index
	mov	bx,offset sDataOffset		;display data offset
	call	DisplayAddress
	jb	LEDATA_Handler2			;error
	mov	word ptr dCurrentOffset,ax	;save data offset
	mov	word ptr dCurrentOffset+2,dx
	mov	word ptr dDataOffset,ax
	mov	word ptr dDataOffset+2,dx
	mov	ax,wRecordLength		;compute data length
	stc
	sbb	ax,si
	jb	LEDATA_Handler2			;error
	mov	wDataLength,ax			;save data length
	push	si
	mov	si,offset sDataLength		;start data length
	call	OutputString
	push	si
	mov	ax,wDataLength			;insert data length
	call	DumpHexWord
	pop	si
	call	OutputString			;end data length
	pop	si
	mov	cx,wDataLength			;load data count
	jcxz	LEDATA_Handler2			;no data
	push	cx
	push	si
	call	OpenHexDump			;start hex dump
	pop	si
	pop	cx
LEDATA_Handler1:
	push	cx
	call	GetRecordByte			;get data byte
	push	si
	call	WriteHexDump			;append to hex dump
	pop	si
	pop	cx
	loop	LEDATA_Handler1			;next data byte
	call	CloseHexDump			;end hex dump
LEDATA_Handler2:
	ret
;
;==============================================================================
;
LIDATA_Handler:
	mov	bCurrentDataIterated,1		;set iteration flag
	mov	si,0				;load first record offset
	mov	bx,offset sDataSegment		;display segment
	call	DisplaySegmentName
	jb	LIDATA_Handler1			;error
	mov	wCurrentSegment,ax		;save segment index
	mov	bx,offset sDataOffset		;display data offset
	call	DisplayAddress
	jb	LIDATA_Handler1			;error
	mov	word ptr dCurrentOffset,ax	;save data offset
	mov	word ptr dCurrentOffset+2,dx
	mov	word ptr dDataOffset,ax
	mov	word ptr dDataOffset+2,dx
	push	si
	call	CountIteratedData		;get number of bytes
	pop	si
	jb	LIDATA_Handler1			;error
	mov	word ptr dDataLength,ax		;save data length
	mov	word ptr dDataLength+2,dx
	push	si
	mov	si,offset sDataLength		;start data length
	call	OutputString
	push	si
	mov	ax,word ptr dDataLength		;insert data length
	mov	dx,word ptr dDataLength+2
	call	DumpHexDouble
	pop	si
	call	OutputString			;end data length
	pop	si
	mov	ax,word ptr dDataLength		;no data?
	or	ax,word ptr dDataLength+2
	jz	LIDATA_Handler1
	call	DisplayIteratedData		;display hex dump
LIDATA_Handler1:
	ret
;
;==============================================================================
;
LCOMDEF_Handler:
COMDEF_Handler:
	ret
;
;==============================================================================
;
BAKPAT_Handler:
	ret
;
;==============================================================================
;
CEXTDEF_Handler:
	ret
;
;==============================================================================
;
COMDAT_Handler:
	ret
;
;==============================================================================
;
LINSYM_Handler:
	ret
;
;==============================================================================
;
ALIAS_Handler:
	ret
;
;==============================================================================
;
NBKPAT_Handler:
	ret
;
;==============================================================================
;
VERNUM_Handler:
	ret
;
;==============================================================================
;
VENDEXT_Handler:
	ret
;
;==============================================================================
;
;	DISPLAY CONTROL
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
OpenHexDump:
	mov	si,offset sDataHexHeader	;display hed dump header
	call	OutputString
	mov	cl,byte ptr dDataOffset		;extract data column
	and	cl,00001111b
	mov	bDataColumn,cl			;save data column
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
CloseHexDump:
	test	byte ptr dDataOffset,00001111b	;partial row left?
	jz	CloseHexDump1
	call	DisplayHexDump			;dump last row
CloseHexDump1:
	ret
;
;==============================================================================
;
;	>	al  -  data byte
;
;------------------------------------------------------------------------------
;
WriteHexDump:
	mov	cl,byte ptr dDataOffset		;extract data column
	and	cl,00001111b
	mov	bx,offset bDataRowBuffer	;copy data byte to row buffer
	add	bl,cl
	adc	bh,0
	mov	[bx],al
	add	word ptr dDataOffset,1		;compute next data offset
	adc	word ptr dDataOffset+2,0
	test	byte ptr dDataOffset,00001111b	;row complete?
	jnz	WriteHexDump1
	call	DisplayHexDump
	mov	bDataColumn,0
WriteHexDump1:
	ret
;
;==============================================================================
;
;	no parameters
;
;------------------------------------------------------------------------------
;
DisplayHexDump:
	mov	si,offset sDataHexRow		;start hex dump row
	call	OutputString
	push	si
	mov	ax,word ptr dDataOffset		;load next offset
	mov	dx,word ptr dDataOffset+2
	mov	cl,al				;compute number of bytes
	and	cl,00001111b
	sub	cl,bDataColumn
	ja	DisplayHexDump1
	add	cl,16
DisplayHexDump1:
	push	cx
	sub	al,cl				;compute row data offset
	sbb	ah,0
	sbb	dx,0
	and	al,11110000b			;display row base offset
	call	DumpHexDouble
	pop	cx
	pop	si
	mov	ch,0				;clear column count
DisplayHexDump2:
	push	cx
	call	OutputString			;spacing
	pop	cx
	push	cx
	push	si
	mov	bx,offset bDataRowBuffer	;load data byte
	add	bl,ch
	adc	bh,0
	mov	al,[bx]
	sub	ch,bDataColumn			;test column range
	jb	DisplayHexDump3
	cmp	ch,cl
	jnb	DisplayHexDump3
	call	DumpHexByte			;display hex bate
	jmp	DisplayHexDump4
DisplayHexDump3:
	mov	si,offset sNoHexByte		;skip hex byte
	call	OutputString
DisplayHexDump4:
	pop	si
	pop	cx
	inc	ch				;count columns
	cmp	ch,16
	jb	DisplayHexDump2
	push	cx
	call	OutputString			;spacing
	pop	cx
	push	si
	mov	ch,0				;clear column count
DisplayHexDump5:
	push	cx
	mov	bx,offset bDataRowBuffer	;load data byte
	add	bl,ch
	adc	bh,0
	mov	al,[bx]
	sub	ch,bDataColumn			;test column range
	jb	DisplayHexDump7
	cmp	ch,cl
	jnb	DisplayHexDump7
	cmp	al,20h				;replace special characters
	jnb	DisplayHexDump6
	mov	al,'.'
DisplayHexDump6:
	call	OutputChar			;display ascii byte
	jmp	DisplayHexDump8
DisplayHexDump7:
	mov	si,offset sNoAsciiByte		;skip ascii byte
	call	OutputString
DisplayHexDump8:
	pop	cx
	inc	ch				;count columns
	cmp	ch,16
	jb	DisplayHexDump5
	pop	si
	jmp	OutputString			;end hex dump row
;
;==============================================================================
;
;	>	si  -  record offset
;
;	<	si  -  next record offset
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
DisplayIteratedData:
	push	si
	call	OpenHexDump			;start hex dump
	pop	si
DisplayIteratedData1:
	test	bRecordType,00000001b		;32-bit segment?
	mov	dx,GetRecordWord
	jz	DisplayIteratedData2
	mov	dx,GetRecordDouble
DisplayIteratedData2:
	call	dx				;get repeat count
	cmc					;end of record
	jnb	DisplayIteratedData4
DisplayIteratedData3:
	push	si
	call	DisplayDataBlockBytes		;display data block
	mov	di,si
	pop	si
	jb	DisplayIteratedData4		;error
	mov	bx,ax				;test repeat count
	or	bx,dx
	jnz	DisplayIteratedData3		;repeat data block
	mov	si,di				;next data block
	jmp	DisplayIteratedData1
DisplayIteratedData4:
	jmp	CloseHexDump			;end hex dump
;
;==============================================================================
;
;	>	   si  -  record offset
;		dx:ax  -  repeat count
;
;	<	   si  -  next record offset
;		dx:ax  -  modified repeat count
;		    c  -  set if error
;
;------------------------------------------------------------------------------
;
DisplayDataBlockBytes:
	push	dx
	push	ax
	sub	wDataRecursion,1		;count recursions
	jb	DisplayDataBlockBytes8		;error
	call	GetRecordWord			;get data block count
	mov	cx,ax
	jb	DisplayDataBlockBytes8		;error
	jcxz	DisplayDataBlockBytes4
DisplayDataBlockBytes1:
	test	bRecordType,00000001b		;32-bit segment?
	mov	dx,GetRecordWord
	jz	DisplayDataBlockBytes2
	mov	dx,GetRecordDouble
DisplayDataBlockBytes2:
	push	cx
	call	dx				;get repeat count
	pop	cx
	jb	DisplayDataBlockBytes8		;error
DisplayDataBlockBytes3:
	push	cx
	push	si
	call	DisplayDataBlockBytes		;display data block
	mov	di,si
	pop	si
	pop	cx
	jb	DisplayDataBlockBytes8		;error
	mov	bx,ax				;test repeat count
	or	bx,dx
	jnz	DisplayDataBlockBytes3		;repeat data block
	mov	si,di				;next data block
	loop	DisplayDataBlockBytes1
	jmp	DisplayDataBlockBytes7		;ok
DisplayDataBlockBytes4:
	call	GetRecordByte			;get data byte count
	jb	DisplayDataBlockBytes8		;error
	mov	cl,al				;load data byte count
	mov	ch,0
	jcxz	DisplayDataBlockBytes7
DisplayDataBlockBytes5:
	push	cx
	call	GetRecordByte			;get data byte
	mov	bl,al
	pop	cx
	jb	DisplayDataBlockBytes8		;error
	pop	ax
	pop	dx
	push	dx
	push	ax
	or	ax,dx				;repeat count = 0?
	jz	DisplayDataBlockBytes6
	push	cx
	push	si
	mov	al,bl				;append to hex dump
	call	WriteHexDump
	pop	si
	pop	cx
DisplayDataBlockBytes6:
	loop	DisplayDataBlockBytes5		;next data byte
DisplayDataBlockBytes7:
	clc					;ok
DisplayDataBlockBytes8:
	inc	wDataRecursion			;recursion done
	pop	ax
	pop	dx
	pushf
	mov	cx,ax				;repeat count = 0?
	or	cx,dx
	add	cx,-1
	sbb	ax,0				;decrement if not 0
	sbb	dx,0
	popf
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;		al  -  subrecord header
;
;	<	si  -  next record offset
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
DisplayThread:
	push	si
	push	ax
	mov	si,offset sFixupThread		;begin thread description
	call	OutputString
	pop	ax
	push	ax
	push	si
	mov	si,FixupThread			;insert thread type
	mov	ah,01000000b
	call	SelectText
	call	OutputString
	pop	si
	call	OutputString
	pop	ax
	push	ax
	push	si
	and	al,00000011b			;insert thread number
	add	al,'0'
	call	OutputChar
	pop	si
	call	OutputString			;end thread description
	pop	ax
	pop	si
	mov	bl,al				;extract thread number
	and	bl,00000011b
	mov	bh,0
	shl	bx,1				;address thread structure
	mov	bx,[bx+ThreadTable]
	mov	ah,al				;extract method
	ror	ah,1
	ror	ah,1
	test	al,01000000b			;frame or target thread?
	jz	DisplayThread2
	and	ah,00000111b			;strip unused bits
	mov	[bx.tdFrameMethod],ah		;save frame method
	mov	[bx.tdFrameIndex],0		;clear frame index
	push	si
	push	bx
	mov	bx,offset sFixupFMethod		;display frame method
	mov	si,FixupFMethod
	mov	ah,00011100b
	call	DisplayBitText
	pop	bx
	pop	si
	cmp	[bx.tdFrameMethod],3		;test frame method
	ja	DisplayThread4			;F4..F7 (no carry)
	mov	dx,GetRecordIndex		;F0..F2
	jb	DisplayThread1
	mov	dx,GetRecordWord		;F3
DisplayThread1:
	push	bx
	call	dx				;get frame index
	pop	bx
	mov	[bx.tdFrameIndex],ax		;save frame index
	jmp	DisplayThread4
DisplayThread2:
	and	ah,00000011b			;strip unused bits
	mov	[bx.tdTargetMethod],ah		;save target method
	mov	[bx.tdTargetIndex],0		;clear target index
	push	si
	push	bx
	mov	bx,offset sFixupTMethod		;display target method
	mov	si,FixupTMethod
	mov	ah,00001100b
	call	DisplayBitText
	pop	bx
	pop	si
	cmp	[bx.tdTargetMethod],3		;test target method
	mov	dx,GetRecordIndex		;T0..T2 / T4..T6
	jb	DisplayThread3
	mov	dx,GetRecordWord		;T3 / T7
DisplayThread3:
	push	bx
	call	dx				;get target index
	pop	bx
	mov	[bx.tdTargetIndex],ax		;save target index
DisplayThread4:
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;		ax  -  subrecord header
;
;	<	si  -  next record offset
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
DisplayFixup:
	push	si
	push	ax
	mov	bx,offset sFixupMode		;display fixup mode
	mov	si,FixupMode
	mov	ah,01000000b
	call	DisplayBitText
	pop	ax
	push	ax
	mov	bx,offset sFixupLocation	;display fixup location
	mov	si,FixupLocation
	mov	ah,00111100b
	call	DisplayBitText
	mov	si,offset sFixupSegment		;start fixup segment
	call	OutputString
	push	si
	mov	ax,wCurrentSegment		;retrieve segment data
	mov	bx,SegmentTable
	mov	di,SegmentData
	call	RetrieveData
	mov	ax,SegmentData.sdSegmentName	;retrieve segment name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert segment name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end fixup segment
	mov	si,offset sFixupOffset		;start fixup offset
	call	OutputString
	pop	ax
	push	si
	xchg	al,ah				;compute fixup offset
	and	ax,03FFh
	mov	dx,0
	add	ax,word ptr dCurrentOffset
	adc	dx,word ptr dCurrentOffset+2
	call	DumpHexDouble			;insert fixup offset
	cmp	bCurrentDataIterated,0
	jz	DisplayFixup1
	mov	si,offset sFixupIterated	;insert iteration comment
	call	OutputString
DisplayFixup1:
	pop	si
	call	OutputString			;end fixup offset
	pop	si
	jmp	DisplayFixupData		;display fixup data
;
;==============================================================================
;
;	>	si  -  record offset
;
;	<	si  -  next record offset
;		 c  -  set if error
;
;------------------------------------------------------------------------------
;
DisplayFixupData:
	call	GetRecordByte			;get fix data
	mov	bFixData,al
	jb	DisplayFixupData9		;error
	push	si
	mov	si,offset sFixupSource		;begin fixup source
	call	OutputString
	push	si
	mov	si,FixupSource			;insert frame definition
	mov	al,bFixData
	mov	ah,10000000b
	call	SelectText
	call	OutputString
	mov	al,bFixData			;thread source?
	test	al,10000000b
	jz	DisplayFixupData1
	and	al,00110000b			;insert thread number
	mov	cl,4
	shr	al,cl
	add	al,'0'
	call	OutputChar
DisplayFixupData1:
	pop	si
	call	OutputString
	push	si
	mov	si,FixupSource			;insert target definition
	mov	al,bFixData
	mov	ah,00001000b
	call	SelectText
	call	OutputString
	mov	al,bFixData			;thread source?
	test	al,00001000b
	jz	DisplayFixupData2
	and	al,00000011b			;insert thread number
	add	al,'0'
	call	OutputChar
DisplayFixupData2:
	pop	si
	call	OutputString
	pop	si
	mov	al,bFixData			;test frame fix data
	mov	cl,4
	ror	al,cl
	test	al,00001000b			;frame thread specified?
	jz	DisplayFixupData3
	mov	bl,al				;extract frame thread number
	and	bl,00000011b
	mov	bh,0
	shl	bx,1				;address thread structure
	mov	bx,[bx+ThreadTable]
	mov	al,[bx.tdFrameMethod]		;copy frame thread method
	mov	bFrameMethod,al
	mov	ax,[bx.tdFrameIndex]		;copy frame thread index
	mov	wFrameIndex,ax
	jmp	DisplayFixupData5
DisplayFixupData3:
	and	al,00000111b			;extract frame method
	mov	bFrameMethod,al			;save frame method
	cmp	al,3				;test frame method
	ja	DisplayFixupData5		;F4..F7
	mov	dx,GetRecordIndex		;F0..F2
	jb	DisplayFixupData4
	mov	dx,GetRecordWord		;F3
DisplayFixupData4:
	call	dx				;get frame index
	mov	wFrameIndex,ax			;save frame index
	jb	DisplayFixupData9		;error
DisplayFixupData5:
	mov	al,bFixData			;test target fix data
	test	al,00001000b			;target thread specified?
	jz	DisplayFixupData6
	mov	bl,al				;extract target thread number
	and	bl,00000011b
	mov	bh,0
	shl	bx,1				;address thread structure
	mov	bx,[bx+ThreadTable]
	mov	al,[bx.tdTargetMethod]		;copy target thread method
	mov	bTargetMethod,al
	mov	ax,[bx.tdTargetIndex]		;copy target thread index
	mov	wTargetIndex,ax
	jmp	DisplayFixupData8
DisplayFixupData6:
	and	al,00000011b			;extract target method
	mov	bTargetMethod,al		;save target method
	cmp	al,3				;test target method
	mov	dx,GetRecordIndex		;T0..T2 / T4..T6
	jb	DisplayFixupData7
	mov	dx,GetRecordWord		;T3 / T7
DisplayFixupData7:
	call	dx				;get target index
	mov	wTargetIndex,ax			;save target index
	jb	DisplayFixupData9		;error
DisplayFixupData8:
	push	si
	mov	bx,offset sFixupFMethod		;display fixup frame method
	mov	si,FixupFMethod
	mov	al,bFrameMethod
	mov	ah,00000111b
	call	DisplayBitText
	mov	bx,offset sFixupTMethod		;display fixup target method
	mov	si,FixupTMethod
	mov	al,bFixData
	and	al,00000100b
	or	al,bTargetMethod
	mov	ah,00000111b
	call	DisplayBitText
	mov	al,bFrameMethod			;display frame datum
	mov	ah,bTargetMethod
	mov	bx,wFrameIndex
	mov	cx,wTargetIndex
	mov	dx,wCurrentSegment
	call	DisplayFixupFrame
	mov	ah,bTargetMethod		;display target datum
	mov	cx,wTargetIndex
	call	DisplayFixupTarget
	pop	si
	mov	al,bFixData			;displacement specified?
	test	al,00000100b
	clc					;ok
	jnz	DisplayFixupData9
	mov	bx,offset sFixupDisplacement	;display fixup displacement
	call	DisplayAddress
DisplayFixupData9:
	ret
;
;==============================================================================
;
;	>	al  -  frame method
;		ah  -  target method
;		bx  -  frame index
;		cx  -  target index
;		dx  -  current segment index
;
;------------------------------------------------------------------------------
;
DisplayFixupFrame:
	cmp	al,5				;test frame method
	ja	DisplayFixupFrame2		;F6..F7 invalid
	jz	DisplayFixupFrame1		;F5 = use target index
	cmp	al,3				;test frame method
	mov	ah,0
	mov	cx,dx
	ja	DisplayFixupFrame1		;F4 = use current segment index
	mov	ah,al				;F0..F3 = use frame index
	mov	cx,bx
DisplayFixupFrame1:
	mov	si,offset sFixupFrame		;display fixup frame
	call	DisplayFixupDatum
DisplayFixupFrame2:
	ret
;
;==============================================================================
;
;	>	ah  -  target method
;		cx  -  target index
;
;------------------------------------------------------------------------------
;
DisplayFixupTarget:
	mov	si,offset sFixupTarget		;display fixup target
	jmp	DisplayFixupDatum
;
;==============================================================================
;
;	>	ah  -  method
;		cx  -  index
;		si  -  text
;
;------------------------------------------------------------------------------
;
DisplayFixupDatum:
	push	ax
	push	cx
	call	OutputString			;begin fixup datum
	pop	cx
	pop	ax
	push	si
	and	ah,00000011b			;segment reference?
	jnz	DisplayFixupDatum1
	mov	ax,cx				;retrieve segment data
	mov	bx,SegmentTable
	mov	di,SegmentData
	call	RetrieveData
	mov	ax,SegmentData.sdSegmentName	;retrieve segment name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert segment name
	call	OutputQuotedString
	jmp	DisplayFixupDatum4
DisplayFixupDatum1:
	dec	ah				;group reference?
	jnz	DisplayFixupDatum2
	mov	ax,cx				;retrieve group data
	mov	bx,GroupTable
	mov	di,GroupData
	call	RetrieveData
	mov	ax,GroupData.gdGroupName	;retrieve group name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert group name
	call	OutputQuotedString
	jmp	DisplayFixupDatum4
DisplayFixupDatum2:
	dec	ah				;external reference?
	jnz	DisplayFixupDatum3
	mov	ax,cx				;retrieve external name
	mov	bx,ExternalTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert external name
	call	OutputQuotedString
	jmp	DisplayFixupDatum4
DisplayFixupDatum3:
	mov	ax,cx				;display explicit frame number
	call	DumpHexWord
DisplayFixupDatum4:
	pop	si
	jmp	OutputString			;end fixup datum
;
;==============================================================================
;
;	>	si  -  record offset
;		bx  -  text
;
;	<	si  -  next record offset
;		ax  -  segment index
;		 z  -  set if null index
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
DisplaySegmentName:
	push	bx
	call	GetRecordIndex			;get segment index
	pop	bx
	jb	DisplaySegmentName2		;end of record
	cmp	ax,0				;segment specified?
	jz	DisplaySegmentName1
	push	si
	push	ax
	mov	si,bx				;start segment info
	call	OutputString
	pop	ax
	push	ax
	push	si
	mov	bx,SegmentTable			;retrieve segment data
	mov	di,SegmentData
	call	RetrieveData
	mov	ax,SegmentData.sdSegmentName	;retrieve segment name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert segment name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end segment info
	pop	ax
	pop	si
DisplaySegmentName1:
	clc					;ok
DisplaySegmentName2:
	rcl	dl,1				;save carry
	or	ax,ax				;null index?
	rcr	dl,1				;restore carry
	ret
;
;==============================================================================
;
;	>	si  -  record offset
;		bx  -  text
;
;	<	si  -  next record offset
;		ax  -  group index
;		 z  -  set if null index
;		 c  -  set if end of record
;
;------------------------------------------------------------------------------
;
DisplayGroupName:
	push	bx
	call	GetRecordIndex			;get group index
	pop	bx
	jb	DisplayGroupName2		;end of record
	cmp	ax,0				;group specified?
	jz	DisplayGroupName1
	push	si
	push	ax
	mov	si,bx				;start group info
	call	OutputString
	pop	ax
	push	ax
	push	si
	mov	bx,GroupTable			;retrieve group data
	mov	di,GroupData
	call	RetrieveData
	mov	ax,GroupData.gdGroupName	;retrieve group name
	mov	bx,NameTable
	mov	di,StringBuffer
	mov	cx,StringBuffer_
	call	RetrieveSymbol
	mov	si,StringBuffer			;insert group name
	call	OutputQuotedString
	pop	si
	call	OutputString			;end group info
	pop	ax
	pop	si
DisplayGroupName1:
	clc					;ok
DisplayGroupName2:
	rcl	dl,1				;save carry
	or	ax,ax				;null index?
	rcr	dl,1				;restore carry
	ret
;
;==============================================================================
;
;	>	bx  -  text
;		si  -  text table
;		al  -  data byte
;		ah  -  bit mask
;
;------------------------------------------------------------------------------
;
DisplayBitText:
	push	si
	push	ax
	mov	si,bx				;begin text
	call	OutputString
	mov	bx,si
	pop	ax
	pop	si
	push	bx
	call	SelectText			;select bit text
	call	OutputString			;insert bit text
	pop	bx
	mov	si,bx
	jmp	OutputString			;end text
;
;==============================================================================
;
;	>	   si  -  record offset
;		   bx  -  text
;
;	<	   si  -  next record offset
;		dx:ax  -  address
;		    c  -  set if end of record
;
;------------------------------------------------------------------------------
;
DisplayAddress:
	test	bRecordType,00000001b		;32-bit segment?
	mov	dx,GetRecordWord
	mov	di,DumpHexWord
	jz	DisplayAddress1
	mov	dx,GetRecordDouble
	mov	di,DumpHexDouble
DisplayAddress1:
	push	bx
	push	di
	call	dx				;get data offset
	pop	di
	pop	bx
	jb	DisplayAddress2			;end of record
	push	si
	push	dx
	push	ax
	push	di
	mov	si,bx				;begin data offset
	call	OutputString
	pop	di
	pop	ax
	pop	dx
	push	dx
	push	ax
	push	si
	call	di				;insert data offset
	pop	si
	call	OutputString			;end data offset
	pop	ax
	pop	dx
	pop	si
	clc					;ok
DisplayAddress2:
	ret
;
;==============================================================================
;
;	>	   si  -  record offset
;		   bx  -  text
;
;	<	   si  -  next record offset
;		    c  -  set if end of record
;
;------------------------------------------------------------------------------
;
DisplayString:
	push	si
	mov	si,bx				;begin text
	call	OutputString
	mov	bx,si
	pop	si
	push	bx
	push	si
	mov	si,offset sBeginText
	call	OutputString
	pop	si
	call	GetRecordByte			;get character count
	jb	DisplayString2			;end of record
	mov	cl,al				;load character count
	mov	ch,0
	jcxz	DisplayString2			;no characters
DisplayString1:
	push	cx
	call	GetRecordByte			;get character
	pop	cx
	jb	DisplayString2			;end of record
	push	cx
	push	si
	call	OutputChar			;display character
	pop	si
	pop	cx
	loop	DisplayString1			;next character
DisplayString2:
	push	si
	mov	si,offset sEndText		;end text
	call	OutputString
	pop	si
	pop	bx
	push	si
	mov	si,bx
	call	OutputString
	pop	si
	ret
;
;==============================================================================
;
;	>	   si  -  record offset
;		   bx  -  text
;
;	<	   si  -  next record offset
;		    c  -  set if end of record
;
;------------------------------------------------------------------------------
;
DisplayText:
	push	si
	mov	si,bx				;begin text
	call	OutputString
	mov	bx,si
	pop	si
	push	bx
	push	si
	mov	si,offset sBeginText
	call	OutputString
	pop	si
DisplayText1:
	call	GetRecordByte			;get character
	jb	DisplayText2			;end of record
	push	si
	call	OutputChar			;display character
	pop	si
	jmp	DisplayText1			;next character
DisplayText2:
	push	si
	mov	si,offset sEndText		;end text
	call	OutputString
	pop	si
	pop	bx
	push	si
	mov	si,bx
	call	OutputString
	pop	si
	ret
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
;	>	al  -  character
;
;------------------------------------------------------------------------------
;
OutputChar:
	mov	bChar,al			;save character
	mov	dx,offset bChar			;display character
	mov	cx,1
	mov	bx,STDOUT
	mov	ah,DOS_WRITE
	int	DOS
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
	jz	OutputString3			;no data
	cmp	bInsertLine,0			;insert line?
	mov	bInsertLine,0
	jz	OutputString2
	push	si
	push	cx
	push	dx
	mov	si,offset sNewLine		;new line
	call	OutputString
	pop	dx
	pop	cx
	pop	si
OutputString2:
	push	si
	mov	bx,STDOUT			;display string
	mov	ah,DOS_WRITE
	int	DOS
	pop	si
OutputString3:
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
;	<	al  -  0 if checksum ok
;		 c  -  set if end of file
;
;------------------------------------------------------------------------------
;
ReadFileRecord:
	mov	di,0				;load data offset
	mov	cx,wRecordLength		;load number of bytes
	mov	dl,bRecordType			;initialize checksum
	add	dl,cl
	add	dl,ch
	mov	al,0				;zero length record
	clc
	jcxz	ReadFileRecord2
ReadFileRecord1:
	call	ReadFileByte			;read byte from input file
	pushf
	add	dl,al				;compute checksum
	mov	es:[di],al			;save byte
	inc	di
	popf
	loop	ReadFileRecord1			;count bytes
ReadFileRecord2:
	pushf
	add	dl,-1				;evaluate checksum
	sbb	dl,dl
	and	al,dl
	popf
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
;	ARITHMETIC
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
;	INITIALIZED DATA
;
;------------------------------------------------------------------------------
;
bLibraryFile		BYTE	0
wPageSize		WORD	1
wRecordBuffer		WORD	0
dRecordOffset		DWORD	0
bRecordType		BYTE	0
wRecordLength		WORD	0
bRecordCheck		BYTE	0
bCommentClass		BYTE	0
bOmfExtension		BYTE	0
;
;------------------------------------------------------------------------------
;
dDataOffset		DWORD	0
dDataLength		DWORD	0
wDataLength		WORD	0
wDataRecursion		WORD	20
bDataRowBuffer		BYTE	16 dup (0)
bDataColumn		BYTE	0
;
;------------------------------------------------------------------------------
;
dCurrentOffset		DWORD	0
wCurrentSegment		WORD	0
bCurrentDataIterated	BYTE	0
bFixData		BYTE	0
bFrameMethod		BYTE	0
wFrameIndex		WORD	0
bTargetMethod		BYTE	0
wTargetIndex		WORD	0
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
bInsertLine		BYTE	0
bChar			BYTE	"?"
;
;------------------------------------------------------------------------------
;
sUndefined		BYTE	"???",0
sBeginText		BYTE	"""",0
sEndText		BYTE	"""",0
sNoHexByte		BYTE	"  ",0
sNoAsciiByte		BYTE	" ",0
sNewLine		BYTE	CR,LF,0
sNull			BYTE	0
;
;------------------------------------------------------------------------------
;
ThreadTable		WORD	Thread0, Thread1, Thread2, Thread3
;
Thread0			THREAD_DATA {}
Thread1			THREAD_DATA {}
Thread2			THREAD_DATA {}
Thread3			THREAD_DATA {}
;
;------------------------------------------------------------------------------
;
RecordTypes	equ	$
;
	BYTE	06Eh, 0, "RHEADR ",0, "R-Module Header Record",0
	WORD	0
;
	BYTE	070h, 0, "REGINT ",0, "Register Initialization",0
	WORD	0
;
	BYTE	072h, 0, "REDATA ",0, "Relocatable Enumerated Data",0
	WORD	0
;
	BYTE	074h, 0, "RIDATA ",0, "Relocatable Iterated Data",0
	WORD	0
;
	BYTE	076h, 0, "OVLDEF ",0, "Overlay Definition",0
	WORD	0
;
	BYTE	078h, 0, "ENDREC ",0, "End Record",0
	WORD	0
;
	BYTE	07Ah, 0, "BLKDEF ",0, "Block Definition",0
	WORD	0
;
	BYTE	07Ch, 0, "BLKEND ",0, "Block End",0
	WORD	0
;
	BYTE	07Eh, 0, "DEBSYM ",0, "Debug Symbols",0
	WORD	0
;
THEADR	BYTE	080h, 0, "THEADR ",0, "Translator Header",0
	WORD	THEADR_Handler
;
LHEADR	BYTE	082h, 0, "LHEADR ",0, "Library Module Header",0
	WORD	LHEADR_Handler
;
	BYTE	084h, 0, "PEDATA ",0, "Physical Enumerated Data",0
	WORD	0
;
	BYTE	086h, 0, "PIDATA ",0, "Physical Iterated Data",0
	WORD	0
;
	BYTE	088h, 0, "COMENT ",0, "Comment / Special Purpose",0
	WORD	COMENT_Handler
;
MODEND	BYTE	08Ah, 1, "MODEND ",0, "Module End",0
	WORD	MODEND_Handler
;
	BYTE	08Ch, 0, "EXTDEF ",0, "External Names Definition",0
	WORD	EXTDEF_Handler
;
	BYTE	08Eh, 0, "TYPDEF ",0, "Type Definition",0
	WORD	TYPDEF_Handler
;
	BYTE	090h, 1, "PUBDEF ",0, "Public Names Definition",0
	WORD	PUBDEF_Handler
;
	BYTE	092h, 0, "LOCSYM ",0, "Local Symbols",0
	WORD	0
;
	BYTE	094h, 1, "LINNUM ",0, "Line Numbers",0
	WORD	LINNUM_Handler
;
	BYTE	096h, 0, "LNAMES ",0, "List of Names",0
	WORD	LNAMES_Handler
;
	BYTE	098h, 1, "SEGDEF ",0, "Segment Definition",0
	WORD	SEGDEF_Handler
;
	BYTE	09Ah, 0, "GRPDEF ",0, "Group Definition",0
	WORD	GRPDEF_Handler
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
	WORD	0
;
	BYTE	0A6h, 0, "LIBNAM ",0, "Library Module Names",0
	WORD	0
;
	BYTE	0A8h, 0, "LIBLOC ",0, "Library Module Locations",0
	WORD	0
;
	BYTE	0AAh, 0, "LIBDIC ",0, "Library Dictionary",0
	WORD	0
;
	BYTE	0B0h, 0, "COMDEF ",0, "Communal Names Definition",0
	WORD	COMDEF_Handler
;
	BYTE	0B2h, 1, "BAKPAT ",0, "Backpatch Record",0
	WORD	BAKPAT_Handler
;
	BYTE	0B4h, 1, "LEXTDEF",0, "Local External Names Definition",0
	WORD	LEXTDEF_Handler
;
	BYTE	0B6h, 1, "LPUBDEF",0, "Local Public Names Definition",0
	WORD	LPUBDEF_Handler
;
	BYTE	0B8h, 0, "LCOMDEF",0, "Local Communal Names Definition",0
	WORD	LCOMDEF_Handler
;
	BYTE	0BAh, 1, "COMFIX ",0, "Communal Fixup",0
	WORD	0
;
	BYTE	0BCh, 0, "CEXTDEF",0, "COMDAT External Names Definition",0
	WORD	CEXTDEF_Handler
;
	BYTE	0C0h, 0, "SELDEF ",0, "Selector Definition",0
	WORD	0
;
	BYTE	0C2h, 1, "COMDAT ",0, "Initialized Communal Data",0
	WORD	COMDAT_Handler
;
	BYTE	0C4h, 1, "LINSYM ",0, "Symbol Line Numbers",0
	WORD	LINSYM_Handler
;
	BYTE	0C6h, 0, "ALIAS  ",0, "Alias Definition",0
	WORD	ALIAS_Handler
;
	BYTE	0C8h, 1, "NBKPAT ",0, "Named Backpatch",0
	WORD	NBKPAT_Handler
;
	BYTE	0CAh, 0, "LLNAMES",0, "Logical Names Definition",0
	WORD	LLNAMES_Handler
;
	BYTE	0CCh, 0, "VERNUM ",0, "OMF Version Number",0
	WORD	VERNUM_Handler
;
	BYTE	0CEh, 0, "VENDEXT",0, "Vendor-specific OMF Extension",0
	WORD	VENDEXT_Handler
;
LibHdr	BYTE	0F0h, 0, "*LibHdr",0, "Library Header",0
	WORD	0
;
LibEnd	BYTE	0F1h, 0, "*LibEnd",0, "Library End",0
	WORD	0
;
	BYTE	000h, 0, "--??-- ",0, "(Unknown Record Type)",0
	WORD	0
;
;------------------------------------------------------------------------------
;
CommentClasses	equ	$
;
	BYTE	000h, 000h, "Translator",0
	WORD	DisplayText, sCommentText
;
	BYTE	001h, 001h, "Intel Copyright",0
	WORD	0, 0
;
	BYTE	002h, 09Bh, "(Reserved for Intel Products)",0
	WORD	0, 0
;
	BYTE	09Ch, 09Ch, "MS-DOS Version",0
	WORD	0, 0
;
	BYTE	09Dh, 09Dh, "Memory Model",0
	WORD	0, 0
;
	BYTE	09Eh, 09Eh, "DOSSEG - Set DOSSEG switch",0
	WORD	0, 0
;
	BYTE	09Fh, 09Fh, "Default Library Search Name",0
	WORD	DisplayText, sCommentText
;
	BYTE	0A0h, 0A0h, "OMF Extension",0
	WORD	OMFEXT_Handler, 0
;
	BYTE	0A1h, 0A1h, "New OMF / Debug Info Version",0
	WORD	0, 0
;
	BYTE	0A2h, 0A2h, "Link Pass Separator",0
	WORD	0, 0
;
	BYTE	0A3h, 0A3h, "LIBMOD - Library Module Name",0
	WORD	DisplayString, sCommentText
;
	BYTE	0A4h, 0A4h, "EXESTR - Executable String",0
	WORD	DisplayText, sCommentText
;
	BYTE	0A6h, 0A6h, "INCERR - Incremental Compilation Error",0
	WORD	0, 0
;
	BYTE	0A7h, 0A7h, "NOPAD - No Segment Padding",0
	WORD	0, 0
;
	BYTE	0A8h, 0A8h, "WKEXT - Weak Extern Record",0
	WORD	0, 0
;
	BYTE	0A9h, 0A9h, "LZEXT - Lazy Extern Record",0
	WORD	0, 0
;
	BYTE	0DAh, 0DAh, "Random Comment",0
	WORD	0, 0
;
	BYTE	0DBh, 0DBh, "Compiler Pragma Comment",0
	WORD	0, 0
;
	BYTE	0DCh, 0DCh, "Date Stamp Pragma Comment",0
	WORD	0, 0
;
	BYTE	0DDh, 0DDh, "Time Stamp Pragma Comment",0
	WORD	0, 0
;
	BYTE	0DFh, 0DFh, "User Pragma Comment",0
	WORD	0, 0
;
	BYTE	0E9h, 0E9h, "Borland Dependency File",0
	WORD	0, 0
;
	BYTE	0FFh, 0FFh, "Microsoft QuickC Command Line",0
	WORD	0, 0
;
	BYTE	0C0h, 0FFh, "(User-Defined Comment Class)",0
	WORD	0, 0
;
	BYTE	000h, 0FFh, "(Unknown Comment Class)",0
	WORD	0, 0
;
;------------------------------------------------------------------------------
;
OmfExtensions	equ	$
;
	BYTE	001h, "IMPDEF - Import Definition",0
	WORD	IMPDEF_Handler
;
	BYTE	002h, "EXPDEF - Export Definition",0
	WORD	EXPDEF_Handler
;
	BYTE	003h, "INCDEF - Incremental Compilation",0
	WORD	INCDEF_Handler
;
	BYTE	004h, "Protected Memory Library",0
	WORD	0
;
	BYTE	005h, "LNKDIR - Microsoft C++ Linker Directives",0
	WORD	LNKDIR_Handler
;
	BYTE	006h, "Big-endian Machine",0
	WORD	0
;
	BYTE	007h, "PRECOMP - Use sstPreComp in $$TYPES",0
	WORD	0
;
	BYTE	000h, "(Unknown OMF Extension)",0
	WORD	0
;
;------------------------------------------------------------------------------
;
SegAlignment	equ	$
;
	BYTE	"Absolute (Type 0)",0
	BYTE	"Relocatable, byte aligned (Type 1)",0
	BYTE	"Relocatable, word (16-bit) aligned (Type 2)",0
	BYTE	"Relocatable, paragraph (16-byte) aligned (Type 3)",0
	BYTE	"Relocatable, page (256-byte) aligned (Type 4)",0
	BYTE	"Relocatable, double word (32-bit) aligned (Type 5)",0
	BYTE	"Not supported (Type 6)",0
	BYTE	"Not defined (Type 7)",0
;
;------------------------------------------------------------------------------
;
SegCombination	equ	$
;
	BYTE	"Private (Type 0)",0
	BYTE	"Memory (Type 1)",0
	BYTE	"Public (Type 2)",0
	BYTE	"Reserved (Type 3)",0
	BYTE	"Public (Type 4)",0
	BYTE	"Stack (Type 5)",0
	BYTE	"Common (Type 6)",0
	BYTE	"Public (Type 7)",0
;
;------------------------------------------------------------------------------
;
SegUse		equ	$
;
	BYTE	"16-bit (Type 0)",0
	BYTE	"32-bit (Type 1)",0
;
;------------------------------------------------------------------------------
;
FixupSubrecord	equ	$
;
	BYTE	"THREAD",0
	BYTE	"FIXUP",0
;
;------------------------------------------------------------------------------
;
FixupThread	equ	$
;
	BYTE	"TARGET",0
	BYTE	"FRAME",0
;
;------------------------------------------------------------------------------
;
FixupMode	equ	$
;
	BYTE	"Self-relative",0
	BYTE	"Segment-relative",0
;
;------------------------------------------------------------------------------
;
FixupLocation	equ	$
;
	BYTE	"Low-order byte (8-bit displacement or LSB of 16-bit offset)",0
	BYTE	"16-bit offset",0
	BYTE	"16-bit base - logical segment base (selector)",0
	BYTE	"32-bit long pointer (base16:offset16)",0
	BYTE	"High-order byte (MSB of 16-bit offset)",0
	BYTE	"16-bit loader-resolved offset",0
	BYTE	"(Reserved)",0
	BYTE	"(Reserved)",0
	BYTE	"(Reserved)",0
	BYTE	"32-bit offset",0
	BYTE	"(Reserved)",0
	BYTE	"48-bit pointer (base16:offset32)",0
	BYTE	"(Reserved)",0
	BYTE	"32-bit loader-resolved offset",0
	BYTE	"(Reserved)",0
	BYTE	"(Reserved)",0
;
;------------------------------------------------------------------------------
;
FixupSource	equ	$
;
	BYTE	"Explicit",0
	BYTE	"Thread #",0
;
;------------------------------------------------------------------------------
;
FixupFMethod	equ	$
;
	BYTE	"[F0] Frame specified by a SEGDEF index",0
	BYTE	"[F1] Frame specified by a GRPDEF index",0
	BYTE	"[F2] Frame specified by an EXTDEF index",0
	BYTE	"[F3] Frame specified by an explicit frame number",0
	BYTE	"[F4] Frame specified by the last data block's segment index",0
	BYTE	"[F5] Frame specified by the target datum",0
	BYTE	"[F6] (Invalid)",0
	BYTE	"[F7] (Invalid)",0
;
;------------------------------------------------------------------------------
;
FixupTMethod	equ	$
;
	BYTE	"[T0] Target specified by a SEGDEF index",0
	BYTE	"[T1] Target specified by a GRPDEF index",0
	BYTE	"[T2] Target specified by an EXTDEF index",0
	BYTE	"[T3] Target specified by an explicit frame number",0
	BYTE	"[T4] Target specified by a SEGDEF index, no displacement",0
	BYTE	"[T5] Target specified by a GRPDEF index, no displacement",0
	BYTE	"[T6] Target specified by an EXTDEF index, no displacement",0
	BYTE	"[T7] (Invalid)",0
;
;------------------------------------------------------------------------------
;
CommentType	equ	$
;
	BYTE	"Purge: YES, List: YES",0
	BYTE	"Purge: YES, List: NO",0
	BYTE	"Purge: NO, List: YES",0
	BYTE	"Purge: NO, List: NO",0
;
;------------------------------------------------------------------------------
;
sBanner\
BYTE CR,LF
BYTE "________________________________________________________________",CR,LF
BYTE CR,LF
BYTE "                            ODU.ASM",CR,LF
BYTE "                  OMF Object File Dumper V2.00",CR,LF
BYTE "        01-03-1996 Sven B. Schreiber sbs@psbs.franken.de",CR,LF
BYTE "                 This is Public Domain Software",CR,LF
BYTE "________________________________________________________________",CR,LF
BYTE CR,LF
BYTE 0
;
sModuleSeparator\
BYTE CR,LF
BYTE "===============================================================================",CR,LF
BYTE 0
;
sNormalEnd\
BYTE CR,LF
BYTE "ODU: Normal end.",CR,LF
BYTE 0
;
sMemoryError\
BYTE CR,LF
BYTE "ODU: Memory allocation error.",CR,LF
BYTE 0
;
sOutOfMemory\
BYTE CR,LF
BYTE "ODU: Not enough memory available.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sInvalidCommand\
BYTE CR,LF
BYTE "Usage: ODU <input file>",CR,LF
BYTE 0
;
sFileNotFound\
BYTE CR,LF
BYTE "ODU: Input file not found.",CR,LF
BYTE 0
;
sFileIoError\
BYTE CR,LF
BYTE "ODU: Input file I/O error.",CR,LF
BYTE 0
;
sNoOmfFile\
BYTE CR,LF
BYTE "ODU: Input file is not an OMF file.",CR,LF
BYTE 0
;
sBadRecord\
BYTE CR,LF
BYTE "ODU: Invalid record encountered.",CR,LF
BYTE 0
;
;------------------------------------------------------------------------------
;
sRecordCaption\
BYTE CR,LF,0," (",0,"/",0,") - ",0,CR,LF,0
;
s32Bit\
BYTE " (32 Bit)",0
;
sChecksumError\
BYTE " [Checksum Error]",0
;
sModuleName\
BYTE "   Name = ",0,CR,LF,0
;
;------------------------------------------------------------------------------
;
sModuleType\
BYTE "   Type of Module = ",0,CR,LF,0
;
sModuleMain\
BYTE "Main module",0
;
sModuleNonMain\
BYTE "Non-main module",0
;
sModuleFixup\
BYTE " with relocatable",0
;
sModuleNoFixup\
BYTE " with absolute",0
;
sModuleStart\
BYTE " start address",0
;
sModuleNoStart\
BYTE " without start address",0
;
;------------------------------------------------------------------------------
;
sName\
BYTE "   #",0," = ",0,CR,LF,0
;
sExternal\
BYTE "   #",0," (Type ",0,") = ",0,CR,LF,0
;
;------------------------------------------------------------------------------
;
sPubGroup\
BYTE "   Base Group        = ",0,CR,LF,0
;
sPubSegment\
BYTE "   Base Segment      = ",0,CR,LF,0
;
sPubFrame\
BYTE "   Base Frame        = ",0,CR,LF,0
;
sPubName\
BYTE "   #",0," (Type ",0,") = [",0,"] ",0,CR,LF,0
;
;------------------------------------------------------------------------------
;
sSegAlignment\
BYTE "   Align   = ",0,CR,LF,0
;
sSegAbsolute\
BYTE ", Frame ",0,", Offset ",0,0
;
sSegCombination\
BYTE "   Combine = ",0,CR,LF,0
;
sSegUse\
BYTE "   Use     = ",0,CR,LF,0
;
sSegLength\
BYTE "   Length  = ",0,CR,LF,0
;
sSegName\
BYTE "   Name    = ",0,CR,LF,0
;
sSegClass\
BYTE "   Class   = ",0,CR,LF,0
;
sSegOverlay\
BYTE "   Overlay = ",0,CR,LF,0
;
;------------------------------------------------------------------------------
;
sGroupName\
BYTE "   Segment Group Name = ",0,CR,LF,0
;
sGroupSegment\
BYTE "   Segment (Type ",0,")  = ",0,CR,LF,0
;
;------------------------------------------------------------------------------
;
sDataSegment\
BYTE "   Segment = ",0,CR,LF,0
;
sDataOffset\
BYTE "   Offset  = ",0,CR,LF,0
;
sDataLength\
BYTE "   Length  = ",0,CR,LF,0
;
sDataHexHeader\
BYTE CR,LF
BYTE "   Offset    x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 xA xB xC xD xE xF [0123456789ABCDEF]",CR,LF
BYTE "   ----------------------------------------------------------------------------",CR,LF
BYTE 0
;
sDataHexRow\
BYTE "   ",0,":"
BYTE " ",0," ",0," ",0," ",0," ",0," ",0," ",0," ",0
BYTE "-",0," ",0," ",0," ",0," ",0," ",0," ",0," ",0," "
BYTE "[",0,"]",CR,LF,0
;
;------------------------------------------------------------------------------
;
sFixupSubrecord\
BYTE "   Subrecord Type = ",0,CR,LF,0
;
sFixupThread\
BYTE "   Thread Type    = ",0," #",0,CR,LF,0
;
sFixupMode\
BYTE "   Fixup Mode     = ",0,CR,LF,0
;
sFixupLocation\
BYTE "   Fixup Location = ",0,CR,LF,0
;
sFixupSegment\
BYTE "   Fixup Segment  = ",0,CR,LF,0
;
sFixupOffset\
BYTE "   Fixup Offset   = ",0,CR,LF,0
;
sFixupIterated\
BYTE " (first occurrence)",0
;
sFixupSource\
BYTE "   Data Source    = Frame: ",0,", Target: ",0,CR,LF,0
;
sFixupFMethod\
BYTE "   Frame Method   = ",0,CR,LF,0
;
sFixupTMethod\
BYTE "   Target Method  = ",0,CR,LF,0
;
sFixupFrame\
BYTE "   Frame Datum    = ",0,CR,LF,0
;
sFixupTarget\
BYTE "   Target Datum   = ",0,CR,LF,0
;
sFixupDisplacement\
BYTE "   Displacement   = ",0,CR,LF,0
;
;------------------------------------------------------------------------------
;
sCommentType\
BYTE "   Comment Type  = ",0,CR,LF,0
;
sCommentClass\
BYTE "   Comment Class = [",0,"] ",0,CR,LF,0
;
sCommentText\
BYTE "   Comment Text  = ",0,CR,LF,0
;
sOmfExtension\
BYTE "   OMF Extension = [",0,"] ",0,CR,LF,0
;
sImpdefIntName\
BYTE "   Internal Name = ",0,CR,LF,0
;
sImpdefModName\
BYTE "   Module Name   = ",0,CR,LF,0
;
sImpdefEntryId\
BYTE "   Entry ID      = ",0,CR,LF,0
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
ModuleName_	equ	PATH_LENGTH
ModuleName	equ	$  + XX
XX		=	XX + ModuleName_
;
;------------------------------------------------------------------------------
;
NameTable	equ	$  + XX
XX		=	XX + SYMBOL_TABLE_
;
SegmentTable	equ	$  + XX
XX		=	XX + SYMBOL_TABLE_
;
GroupTable	equ	$  + XX
XX		=	XX + SYMBOL_TABLE_
;
ExternalTable	equ	$  + XX
XX		=	XX + SYMBOL_TABLE_
;
;------------------------------------------------------------------------------
;
SegmentData	equ	$  + XX
XX		=	XX + SEGMENT_DATA_
;
GroupData	equ	$  + XX
XX		=	XX + GROUP_DATA_
;
;------------------------------------------------------------------------------
;
MAX_NAMES	equ	1024
MAX_SEGMENTS	equ	1024
MAX_GROUPS	equ	1024
MAX_EXTERNALS	equ	1024
;
NameArray_	equ	MAX_NAMES * 2
NameArray	equ	$  + XX
XX		=	XX + NameArray_
;
SegmentArray_	equ	MAX_SEGMENTS * 2
SegmentArray	equ	$  + XX
XX		=	XX + SegmentArray_
;
GroupArray_	equ	MAX_GROUPS * 2
GroupArray	equ	$  + XX
XX		=	XX + GroupArray_
;
ExternalArray_	equ	MAX_EXTERNALS * 2
ExternalArray	equ	$  + XX
XX		=	XX + ExternalArray_
;
;------------------------------------------------------------------------------
;
InputFile_	equ	PATH_LENGTH
InputFile	equ	$  + XX
XX		=	XX + InputFile_
;
HexBuffer_	equ	8+1
HexBuffer	equ	$  + XX
XX		=	XX + HexBuffer_
;
StringBuffer_	equ	256
StringBuffer	equ	$  + XX
XX		=	XX + StringBuffer_
;
FileBuffer_	equ	2000h
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

