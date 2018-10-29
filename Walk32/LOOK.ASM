;	ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;	³                                                    ³
;	³             (c) 1994 Sven B. Schreiber             ³
;	³               Textsuchprogramm, V1.2               ³
;	³            02.06.1994 Sven B. Schreiber            ³
;	³                                                    ³
;	ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾
;
;
;==============================================================================
;
;	Zu bersetzen mit MASM 5.10
;	~~~~~~~~~~~~~~~~~~~~~~~~~~~
;	masm look,look,nul.lst,nul.crf
;	link look,look,nul.map,,
;	exe2bin look look.com
;
;------------------------------------------------------------------------------
;
;	Screen messages translated to english: 03-16-1996 Sven B. Schreiber
;
;==============================================================================
;
;				  konstanten
;
;------------------------------------------------------------------------------
;
dta		equ	0080h			;datentransferadresse
base		equ	0100h			;programmanfang
;
kbd		equ	16h			;tastatur-interrupt
dos		equ	21h			;dos-interrupt
;
character	equ	02h			;zeichen anzeigen
setdrive	equ	0eh			;laufwerk w„hlen
getdrive	equ	19h			;laufwerk abfragen
setdta		equ	1ah			;datentransferadresse setzen
setdir		equ	3bh			;verzeichnis w„hlen
create		equ	3ch			;datei einrichten
open		equ	3dh			;datei ”ffnen
close		equ	3eh			;datei schlieáen
read		equ	3fh			;datei lesen
write		equ	40h			;datei schreiben
delete		equ	41h			;datei l”schen
move		equ	42h			;dateizeiger setzen
getdir		equ	47h			;verzeichnis ermitteln
terminate	equ	4ch			;programm beenden
findfirst	equ	4eh			;erste datei suchen
findnext	equ	4fh			;n„chste datei suchen
rename		equ	56h			;datei umbenennen
;
wildcard	equ	'?'			;wildcard-zeichen
prefiller	equ	'>'			;vorspann-fllzeichen
postfiller	equ	'<'			;nachspann-fllzeichen
;
lf		equ	0ah			;line feed
cr		equ	0dh			;carriage return
escape		equ	1bh			;escape
;
;==============================================================================
;
;				 hauptprogramm
;
;------------------------------------------------------------------------------
;
code	segment
	assume	cs:code,ds:code,es:code,ss:code
	org	base
start:
	jmp	main
	dw	freememory
;
	db	     '           '
	db	'                '
	db	'================'
	db	' LOOK      V1.2 '
	db	' 06-02-1994 SBS '
	db	'================'
	db	'    This is     '
	db	' Public Domain  '
	db	'    Software    '
	db	'================'
	db	' S.B. Schreiber '
	db	' CIS 100557,177 '
	db	' Herzogenaurach '
	db	'    Germany     '
	db	'================'
	db	'                '
stack:
;
;------------------------------------------------------------------------------
;
case?:
	db	 0			;groá-/kleinschreibung beachten
wildcard?:
	db	-1			;wildcard erlaubt
listall?:
	db	-1			;alle dateien auflisten
recursive?:
	db	0			;rekursive suche?
;
;==============================================================================
;
;				     code
;
;==============================================================================
;
main:
	mov	sp,offset stack			;internen stack w„hlen
	mov	si,offset signon		;startmeldung anzeigen
	call	display
	mov	si,offset dta+1			;kommandozeile laden
	call	loadparameters			;parameter laden
	jnb	main1
	mov	si,offset commandinfo		;infotext anzeigen
	call	display
	jmp	exit
main1:
	mov	di,offset startdir		;startverzeichnis merken
	call	savedir
	call	look				;dateien durchsuchen
	mov	si,offset startdir		;startverzeichnis w„hlen
	call	restoredir
exit:
	mov	al,0				;programm beenden
	mov	ah,terminate
	int	dos
;
;==============================================================================
;
;	>	si  -  kommandozeile
;
;	<	c   -  gesetzt falls fehler
;
;------------------------------------------------------------------------------
;
loadparameters:
	mov	di,offset namebuffer		;dateinamen analysieren
	mov	cx,offset namebuffer_
	call	parsefilename
	jb	loadparameters5			;pufferberlauf
	mov	word ptr filepath,di		;dateipfadadresse merken
	add	di,bx
	mov	word ptr filepattern,di		;dateimusteradresse merken
loadparameters1:
	mov	ah,byte ptr [si]		;delimiter suchen
	inc	si
	cmp	ah,cr				;zeilenende?
	jz	loadparameters5
	cmp	ah,0
	jz	loadparameters5
	cmp	ah,'"'				;delimiter?
	jz	loadparameters2
	cmp	ah,"'"
	jnz	loadparameters1
loadparameters2:
	mov	di,offset pattern		;suchmuster extrahieren
	mov	dx,offset pattern_
loadparameters3:
	mov	al,byte ptr [si]		;zeichen laden
	inc	si
	cmp	al,ah				;delimiter?
	jz	loadparameters4
	cmp	al,cr				;zeilenende?
	jz	loadparameters5
	cmp	al,0
	jz	loadparameters5
	cmp	dx,0				;zielpuffer voll?
	jz	loadparameters5
	mov	byte ptr [di],al		;zeichen kopieren
	inc	di
	dec	dx				;zeichen z„hlen
	jmp	loadparameters3			;kein abschlieáender delimiter
loadparameters4:
	mov	ax,offset pattern_		;suchmusterl„nge berechnen
	sub	ax,dx
	mov	word ptr patternlength,ax
	mov	ax,'cC'				;groá/kleinschreibung beachten?
	mov	di,offset case?
	call	checkoption
	mov	ax,'wW'				;wildcards erlauben?
	mov	di,offset wildcard?
	call	checkoption
	mov	ax,'aA'				;alle dateien auflisten?
	mov	di,offset listall?
	call	checkoption
	mov	ax,'rR'				;rekursive suche?
	mov	di,offset recursive?
	call	checkoption
	clc					;nc = ok
	ret
loadparameters5:
	stc					;c = fehler
	ret
;
;==============================================================================
;
;	>	si  -  kommandozeile
;		di  -  puffer
;		cx  -  pufferl„nge (min 7)
;
;	<	si  -  restliche kommandozeile
;		di  -  verzeichnisname
;		bx  -  offset des dateinamens
;		c   -  gesetzt falls pufferberlauf
;
;------------------------------------------------------------------------------
;
parsefilename:
	inc	si				;leerzeichen berspringen
	cmp	byte ptr [si-1],' '
	jz	parsefilename
	dec	si
	sub	cx,2+1+4			;zus„tzl. daten bercksichtigen
	add	di,2				;reservebytes berspringen
	mov	dx,di				;pufferanfang merken
parsefilename1:
	mov	byte ptr [di],0			;terminator anh„ngen
	mov	al,byte ptr [si]		;zeichen laden
	cmp	al,' '				;trenner?
	jz	parsefilename4
	cmp	al,cr				;zeilenende?
	jz	parsefilename4
	cmp	al,0
	jz	parsefilename4
	cmp	cx,0				;noch platz im puffer?
	jnz	parsefilename2
	inc	di				;leeren dateinamen anh„ngen
	mov	byte ptr [di],0
	mov	bx,di				;namensoffset berechnen
	sub	bx,dx
	stc					;pufferberlauf
	jmp	parsefilename14
parsefilename2:
	inc	si
	cmp	al,'a'				;in groábuchstaben wandeln
	jb	parsefilename3
	cmp	al,'z'
	ja	parsefilename3
	add	al,'A'-'a'
parsefilename3:
	mov	byte ptr [di],al		;zeichen kopieren
	inc	di
	dec	cx
	jmp	parsefilename1
parsefilename4:
	cmp	di,dx				;nichts angegeben?
	jz	parsefilename5
	cmp	byte ptr [di-1],':'		;nur laufwerk angegeben?
	jz	parsefilename5
	cmp	byte ptr [di-1],'\'		;nur verzeichnis angegeben?
	jz	parsefilename5
	push	si
	push	di
	push	dx
	mov	si,dx				;nach datei suchen
	call	checkfile
	pop	dx
	pop	di
	pop	si
	jnb	parsefilename6			;datei vorhanden
	push	si
	push	di
	push	dx
	mov	si,dx				;nach verzeichnis suchen
	call	checkdir
	pop	dx
	pop	di
	pop	si
	jb	parsefilename6			;verzeichnis nicht vorhanden
	mov	byte ptr [di],'\'		;verzeichnistrenner anh„ngen
	inc	di
parsefilename5:
	mov	byte ptr [di],'*'		;wildcards anh„ngen
	mov	byte ptr [di+1],'.'
	mov	byte ptr [di+2],'*'
	mov	byte ptr [di+3],0
parsefilename6:
	mov	di,dx				;pufferanfang laden
	mov	bx,0				;positionsmerker l”schen
parsefilename7:
	inc	di
	cmp	byte ptr [di-1],0		;ende?
	jz	parsefilename9
	cmp	byte ptr [di-1],':'		;laufwerkstrenner?
	jz	parsefilename8
	cmp	byte ptr [di-1],'\'		;verzeichnistrenner?
	jnz	parsefilename7
parsefilename8:
	mov	bx,di				;position merken
	jmp	parsefilename7
parsefilename9:
	cmp	bx,0				;trenner gefunden?
	jnz	parsefilename10
	sub	dx,2				;kein verzeichnis angegeben
	mov	di,dx
	mov	byte ptr [di],'.'		;home-verzeichnis eintragen
	mov	byte ptr [di+1],0
	mov	bx,2
	jmp	parsefilename13
parsefilename10:
	mov	di,dx				;pufferanfang laden
	sub	bx,dx				;namensoffset berechnen
	mov	al,0				;dateinamen abtrennen
	xchg	al,byte ptr [di+bx-1]
	cmp	al,':'				;laufwerksangabe davor?
	jnz	parsefilename13
	push	si
	mov	si,di				;laufwerksangabe verschieben
	sub	di,2
parsefilename11:
	mov	al,byte ptr [si]		;zeichen laden
	inc	si
	cmp	al,0				;ende?
	jz	parsefilename12
	mov	byte ptr [di],al		;zeichen kopieren
	inc	di
	jmp	parsefilename11
parsefilename12:
	pop	si
	mov	byte ptr [di],':'		;home-laufwerk anh„ngen
	mov	byte ptr [di+1],'.'
	sub	dx,2				;pufferanfang korrigieren
	add	bx,2				;namensoffset korrigieren
parsefilename13:
	clc					;ok
parsefilename14:
	mov	di,dx				;verzeichnisnamen laden
	ret
;
;==============================================================================
;
;	>	si  -  dateiname
;
;	<	c   -  gesetzt falls nicht vorhanden
;
;------------------------------------------------------------------------------
;
checkfile:
	push	si
	mov	dx,offset dosbuffer		;datentransferadresse setzen
	mov	ah,setdta
	int	dos
	pop	dx
	mov	cx,0027h			;nach datei suchen
	mov	ah,findfirst
	int	dos
	ret
;
;==============================================================================
;
;	>	si  -  verzeichnisname
;
;	<	c   -  gesetzt falls nicht vorhanden
;
;------------------------------------------------------------------------------
;
checkdir:
	mov	di,si				;verzeichnisnamen testen
checkdir1:
	inc	di				;n„chstes zeichen
	cmp	byte ptr [di-1],0		;ende?
	jz	checkdir3
	cmp	byte ptr [di-1],'?'		;wildcard?
	jz	checkdir2
	cmp	byte ptr [di-1],'*'
	jnz	checkdir1
checkdir2:
	stc					;c = kein verzeichnis
	jmp	checkdir5
checkdir3:
	push	si
	mov	dx,offset dosbuffer		;datentransferadresse setzen
	mov	ah,setdta
	int	dos
	pop	dx
	mov	cx,0037h			;nach datei/verzeichnis suchen
	mov	ah,findfirst
checkdir4:
	int	dos
	jb	checkdir5			;c = kein verzeichnis
	test	byte ptr dosbuffer+0015h,10h	;verzeichnis?
	mov	ah,findnext
	jz	checkdir4			;weitersuchen
	clc					;nc = ok
checkdir5:
	ret
;
;==============================================================================
;
;	>	si  -  kommandozeile
;		al  -  options-id
;		ah  -  options-id (alternativ)
;		di  -  optionsflag-adresse
;
;	<	si  -  kommandozeile
;
;------------------------------------------------------------------------------
;
checkoption:
	push	si
	mov	dl,1				;toggle-modus voreinstellen
checkoption1:
	cmp	byte ptr [si],cr		;zeilenende?
	jz	checkoption4
	cmp	byte ptr [si],0
	jz	checkoption4
	cmp	byte ptr [si],'+'		;flag setzen?
	mov	dh,-1
	jz	checkoption2
	cmp	byte ptr [si],'-'		;flag l”schen?
	mov	dh,0
	jz	checkoption2
	mov	dh,dl				;bisherigen modus laden
	cmp	byte ptr [si],al		;options-id gefunden?
	jz	checkoption3
	cmp	byte ptr [si],ah
	jz	checkoption3
checkoption2:
	mov	dl,dh				;modus laden
	inc	si				;n„chstes zeichen
	jmp	checkoption1
checkoption3:
	not	byte ptr [di]			;flag umschalten
	cmp	dl,1				;toggle-modus ok?
	jz	checkoption4
	mov	byte ptr [di],dl		;flag setzen bzw. l”schen
checkoption4:
	pop	si				;kommandozeile wiederherstellen
	ret
;
;==============================================================================
;
;	>	cx  -  verzeichnisnummer (1..n)
;
;	<	si  -  verzeichnisname (0 falls nicht vorhanden)
;
;------------------------------------------------------------------------------
;
finddir:
	push	cx
	mov	dx,offset dosbuffer		;datentransferadresse setzen
	mov	ah,setdta
	int	dos
	mov	dx,offset allfiles		;ersten eintrag suchen
	mov	cx,0037h
	mov	ah,findfirst
finddir1:
	int	dos				;eintrag suchen
	pop	cx
	jnb	finddir2
	mov	si,0				;nicht vorhanden
	ret
finddir2:
	mov	bx,offset dosbuffer		;datentransferadresse laden
	test	byte ptr [bx+0015h],10h		;verzeichnis?
	jz	finddir4
	cmp	byte ptr [bx+001eh],'.'		;aktuelles verzeichnis?
	jnz	finddir3
	cmp	byte ptr [bx+001eh+1],0
	jz	finddir4
	cmp	byte ptr [bx+001eh+1],'.'	;oberverzeichnis?
	jnz	finddir3
	cmp	byte ptr [bx+001eh+2],0
	jz	finddir4
finddir3:
	dec	cx				;verzeichnisse z„hlen
	jnz	finddir4
	lea	si,[bx+001eh]			;verzeichnisnamen adressieren
	ret
finddir4:
	push	cx
	mov	ah,findnext			;n„chsten eintrag suchen
	jmp	finddir1
;
;==============================================================================
;
;	>	si  -  neues verzeichnis
;		di  -  puffer fr neues verzeichnis
;		bx  -  puffer fr voriges verzeichnis
;
;------------------------------------------------------------------------------
;
changedir:
	mov	byte ptr [di],0			;puffer l”schen
	mov	byte ptr [bx],0
	cmp	byte ptr [si],0			;hauptverzeichnis?
	jz	changedir1
	cmp	byte ptr [si+1],':'		;laufwerk nicht angegeben?
	mov	dx,si				;nur verzeichnis w„hlen
	jnz	changedir2
	mov	dl,byte ptr [si]		;laufwerk laden
	sub	dl,'A'
	cmp	dl,26				;gltige nummer?
	jnb	changedir4
	push	si
	push	di
	push	bx
	push	dx
	mov	ah,setdrive			;laufwerk w„hlen
	int	dos
	mov	ah,getdrive			;laufwerk abfragen
	int	dos
	pop	dx
	pop	bx
	pop	di
	pop	si
	cmp	al,dl				;laufwerk gew„hlt?
	jnz	changedir4
	add	si,2				;laufwerk berspringen
	cmp	byte ptr [si],0			;hauptverzeichnis?
	mov	dx,si				;angegebenes verzeichnis w„hlen
	jnz	changedir2
changedir1:
	mov	dx,offset root			;hauptverzeichnis w„hlen
changedir2:
	push	di
	push	dx
	mov	di,bx				;aktuelles verzeichnis merken
	call	savedir
	pop	dx
	mov	ah,setdir			;neues verzeichnis w„hlen
	int	dos
	pop	di
	jb	changedir4			;fehler
	push	di
	call	savedir				;verzeichnis abfragen
	pop	di
	cmp	byte ptr [di],0			;gltige daten?
	jz	changedir4
changedir3:
	inc	di				;ende suchen
	cmp	byte ptr [di-1],0
	jnz	changedir3
	cmp	byte ptr [di-2],'\'		;pfadtrenner am ende?
	jz	changedir4
	mov	byte ptr [di-1],'\'		;pfadtrenner anfgen
	mov	byte ptr [di],0
changedir4:
	ret
;
;==============================================================================
;
;	>	di  -  puffer
;
;------------------------------------------------------------------------------
;
savedir:
	push	di
	mov	ah,getdrive			;laufwerk abfragen
	int	dos
	pop	di
	add	al,'A'				;in buchstaben wandeln
	mov	byte ptr [di],al		;laufwerk eintragen
	mov	byte ptr [di+1],':'
	mov	byte ptr [di+2],'\'
	add	di,3				;laufwerk berspringen
	mov	si,di				;verzeichnis abfragen
	mov	dl,0
	mov	ah,getdir
	int	dos
	ret
;
;==============================================================================
;
;	>	si  -  puffer
;
;------------------------------------------------------------------------------
;
restoredir:
	push	si
	mov	dx,si				;verzeichnis w„hlen
	mov	ah,setdir
	int	dos
	pop	si
	mov	dl,byte ptr [si]		;laufwerk w„hlen
	sub	dl,'A'
	mov	ah,setdrive
	int	dos
	ret
;
;==============================================================================
;
;	keine parameter
;
;------------------------------------------------------------------------------
;
look:
	mov	byte ptr outputflag,0		;anzeigeflag l”schen
	mov	word ptr filecount,0		;dateiz„hler l”schen
	mov	word ptr filecount+2,0
	mov	si,word ptr filepath		;angegebenes verzeichnis w„hlen
	mov	di,offset currentdir
	mov	bx,offset basedir
	call	changedir
	cmp	byte ptr currentdir,0		;ok?
	jnz	look1
	mov	si,offset invaliddir		;ungltiges verzeichnis
	jmp	display
look1:
	call	lookfiles			;dateien durchsuchen
	mov	si,offset basedir		;basisverzeichnis w„hlen
	call	restoredir
	cmp	byte ptr outputflag,0		;nichts angezeigt?
	jz	look2
	mov	si,offset newline		;neue zeile
	call	display
look2:
	ret
;
;==============================================================================
;
;	keine parameter
;
;------------------------------------------------------------------------------
;
lookfiles:
	mov	byte ptr breakflag,0		;abbruchsflag l”schen
lookfiles1:
	call	testfiles			;dateien testen
	cmp	byte ptr recursive?,0		;rekursive suche?
	jz	lookfiles3
	mov	cx,0				;verzeichnisz„hler l”schen
lookfiles2:
	cmp	byte ptr breakflag,0		;abbrechen?
	jnz	lookfiles3
	inc	cx				;verzeichnisse z„hlen
	push	cx
	call	finddir				;verzeichnis suchen
	pop	cx
	cmp	si,0				;gefunden?
	jz	lookfiles3
	push	cx
	mov	di,offset currentdir		;verzeichnis w„hlen
	mov	bx,offset lastdir
	call	changedir
	call	lookfiles1			;rekursiv weitersuchen
	mov	dx,offset parent		;oberverzeichnis w„hlen
	mov	ah,setdir
	int	dos
	pop	cx
	jmp	lookfiles2			;n„chstes verzeichnis
lookfiles3:
	ret
;
;==============================================================================
;
;	keine parameter
;
;------------------------------------------------------------------------------
;
testfiles:
	mov	dx,offset dosbuffer		;datentransferadresse setzen
	mov	ah,setdta
	int	dos
	mov	dx,word ptr filepattern		;erste datei suchen
	mov	cx,0027h
	mov	ah,findfirst
	int	dos
	jnb	testfiles1
	jmp	testfiles7			;keine dateien gefunden
testfiles1:
	mov	si,offset dosbuffer+001eh	;dateinamen kopieren
	mov	di,offset sourcename
	mov	cx,offset filename_
	cld
	rep	movsb
	cmp	byte ptr listall?,0		;alle dateien auflisten?
	jz	testfiles2
	call	displayfullname			;vollen dateinamen anzeigen
testfiles2:
	call	opensource			;quelldatei ”ffnen
	jb	testfiles6			;fehler
	mov	word ptr hitcount,0		;trefferz„hler l”schen
	mov	word ptr hitcount+2,0
	mov	si,offset pattern		;suchmuster auswerten
	mov	cx,word ptr patternlength
	mov	bp,offset positiontable
	call	inittable
	mov	bx,0				;statusmaske l”schen
	mov	di,0
testfiles3:
	push	ax
	push	bx
	push	dx
	push	di
	push	bp
	call	readsource			;quelldaten laden
	pop	bp
	pop	di
	pop	dx
	pop	bx
	pop	ax
	jb	testfiles5			;fehler
	jcxz	testfiles5			;dateiende
	call	checkbreak			;anzeigeunterbrechung behandeln
	jb	testfiles5
testfiles4:
	call	searchnextmatch			;n„chsten treffer suchen
	jz	testfiles3			;nichts gefunden
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	call	displayhit			;treffer anzeigen
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	call	checkbreak			;anzeigeunterbrechung behandeln
	jnb	testfiles4			;block weiterbearbeiten
testfiles5:
	mov	si,0				;anzeige beenden
	call	displayhit
	call	closesource			;quelldatei schlieáen
testfiles6:
	cmp	byte ptr breakflag,0		;abbrechen?
	jnz	testfiles7
	mov	ah,findnext			;n„chste datei suchen
	int	dos
	jb	testfiles7
	jmp	testfiles1
testfiles7:
	ret
;
;==============================================================================
;
;	<	c   -  gesetzt falls fehler
;
;------------------------------------------------------------------------------
;
opensource:
	mov	ax,offset databuffer		;pufferadresse definieren
	mov	word ptr sourcebuffer,ax
	mov	word ptr sourceblock,0		;blockl„nge l”schen
	mov	word ptr sourcepostblock,0	;nachspannl„nge l”schen
	mov	word ptr sourceoffset,0		;dateioffset l”schen
	mov	word ptr sourceoffset+2,0
	mov	dx,offset sourcename		;quelldatei zum lesen ”ffnen
	mov	al,0
	mov	ah,open
	int	dos
	mov	word ptr sourcehandle,ax	;ergebnis merken
	jb	opensource1			;ok
	mov	di,offset prebuffer		;puffer vorbelegen
	mov	cx,offset context_+databuffer_
	mov	al,prefiller
	cld
	rep	stosb
	mov	cx,offset context_		;nachspann definieren
	call	readblock
	mov	word ptr sourcepostblock,cx	;nachspannl„nge merken
	jnb	opensource2			;ok
	call	closesource			;quelldatei schlieáen
	stc					;fehler
	jmp	opensource2
opensource1:
	mov	si,offset erroropen		;fehlermeldung anzeigen
	call	display
	stc					;fehler
opensource2:
	ret
;
;==============================================================================
;
;	<	c   -  gesetzt falls fehler
;
;------------------------------------------------------------------------------
;
closesource:
	mov	bx,word ptr sourcehandle	;quelldatei schlieáen
	mov	ah,close
	int	dos
	jnb	closesource1			;ok
	mov	si,offset errorsclose		;fehlermeldung anzeigen
	call	display
	stc					;fehler
closesource1:
	ret
;
;==============================================================================
;
;	<	si  -  blockadresse
;		cx  -  blockl„nge (0 = dateiende)
;		c   -  gesetzt falls fehler
;
;------------------------------------------------------------------------------
;
readsource:
	mov	si,offset postbuffer-context_	;ende an den anfang kopieren
	mov	di,offset prebuffer
	mov	cx,offset 2*context_
	cld
	rep	movsb
	mov	cx,offset databuffer_		;datenblock lesen
	call	readblock
	pushf
	mov	dx,cx				;nachspann vorhanden?
	sub	dx,offset databuffer_-context_
	mov	ax,offset databuffer_
	jnb	readsource1
	mov	dx,0				;letzter block
	mov	ax,word ptr sourcepostblock
	add	ax,cx
readsource1:
	mov	word ptr sourcepostblock,dx	;nachspannl„nge merken
	xchg	word ptr sourceblock,ax		;blockl„nge laden/merken
	add	word ptr sourceoffset,ax	;datenblockoffset berechnen
	adc	word ptr sourceoffset+2,0
	popf
	mov	si,word ptr sourcebuffer	;blockadresse laden
	mov	cx,word ptr sourceblock		;blockl„nge laden
	ret
;
;==============================================================================
;
;	>	di  -  pufferadresse
;		cx  -  pufferl„nge
;
;	<	cx  -  blockl„nge
;		c   -  gesetzt falls fehler
;
;------------------------------------------------------------------------------
;
readblock:
	push	cx
	push	di
	mov	bx,word ptr sourcehandle	;datenblock lesen
	mov	dx,di
	mov	ah,read
	int	dos
	jnb	readblock1			;nc = ok
	mov	si,offset errorread		;fehlermeldung anzeigen
	call	display
	mov	ax,0				;nichts gelesen
	stc					;c = fehler
readblock1:
	pop	di
	pop	cx
	pushf
	push	ax
	add	di,ax				;puffer auffllen
	sub	cx,ax
	mov	al,postfiller
	cld
	rep	stosb
	pop	cx				;blockl„nge laden
	popf
	ret
;
;==============================================================================
;
;	>	   si  -  muster
;		   cx  -  musterl„nge
;		   bp  -  tabelle
;
;	<	dx:ax  -  endmaske
;		   bp  -  tabelle
;
;------------------------------------------------------------------------------
;
inittable:
	push	cx
	mov	di,bp				;positionstabelle l”schen
	mov	cx,offset positiontable_
	mov	al,0
	cld
	rep	stosb
	pop	cx
	mov	ax,0				;bitmaske l”schen
	mov	dx,0
	jcxz	inittable6			;keine zeichen vorhanden
	cmp	cx,offset pattern_		;musterl„nge beschr„nken
	jna	inittable1
	mov	cx,offset pattern_
inittable1:
	stc					;1 in die bitmaske schieben
inittable2:
	rcl	ax,1				;bitmaske weiterschieben
	rcl	dx,1
	cmp	byte ptr wildcard?,0		;wildcard erlaubt?
	jz	inittable4
	cmp	byte ptr [si],wildcard		;wildcard?
	jnz	inittable4
	push	cx
	mov	bx,bp				;ganze tabelle bearbeiten
	mov	cx,offset chartable_
inittable3:
	or	word ptr [bx],ax		;positionsbit setzen
	or	word ptr [bx+2],dx
	add	bx,4
	loop	inittable3
	pop	cx
	jmp	inittable5			;n„chstes zeichen
inittable4:
	mov	bl,byte ptr [si]		;zeichen laden
	mov	bh,0
	shl	bx,1				;tabelleneintrag adressieren
	shl	bx,1
	add	bx,bp
	or	word ptr [bx],ax		;positionsbit setzen
	or	word ptr [bx+2],dx
	cmp	byte ptr case?,0		;groá/kleinschreibung beachten?
	jnz	inittable5
	push	ax
	push	cx
	push	dx
	push	si
	push	bp
	mov	al,byte ptr [si]		;zeichen konvertieren
	call	swapcase
	mov	bx,ax
	pop	bp
	pop	si
	pop	dx
	pop	cx
	pop	ax
	cmp	bl,bh				;zeichen ge„ndert?
	jz	inittable5
	mov	bl,bh				;zeichen laden
	mov	bh,0
	shl	bx,1				;tabelleneintrag adressieren
	shl	bx,1
	add	bx,bp
	or	word ptr [bx],ax		;positionsbit setzen
	or	word ptr [bx+2],dx
inittable5:
	inc	si				;n„chstes zeichen
	clc					;0 in die bitmaske schieben
	loop	inittable2
inittable6:
	ret
;
;==============================================================================
;
;	>	dx:ax  -  endmaske
;		di:bx  -  aktuelle statusmaske (0 beim ersten aufruf)
;		   si  -  aktuelle textadresse
;		   cx  -  aktuelle textl„nge
;		   bp  -  tabelle
;
;	<	dx:ax  -  endmaske
;		di:bx  -  aktualisierte statusmaske
;		   si  -  aktualisierte textadresse
;		   cx  -  aktualisierte textl„nge
;		   bp  -  tabelle
;		   z   -  gesetzt falls kein treffer
;
;------------------------------------------------------------------------------
;
searchnextmatch:
	xchg	bx,cx
searchnextmatch1:
	or	bx,bx				;textende?
	jz	searchnextmatch2
	stc					;1 in die statusmaske schieben
	rcl	cx,1
	rcl	di,1
	push	bx
	mov	bl,byte ptr [si]		;zeichen laden
	mov	bh,0
	shl	bx,1				;tabelleneintrag adressieren
	shl	bx,1
	add	bx,bp
	and	cx,word ptr [bx]		;positionstreffer maskieren
	and	di,word ptr [bx+2]
	pop	bx
	inc	si				;n„chstes zeichen
	dec	bx
	test	cx,ax				;treffer an endposition?
	jnz	searchnextmatch2
	test	di,dx
	jz	searchnextmatch1
searchnextmatch2:
	xchg	bx,cx
	ret
;
;==============================================================================
;
;	>	al  -  zeichen
;
;	<	al  -  zeichen
;		ah  -  konvertiertes zeichen
;
;------------------------------------------------------------------------------
;
swapcase:
	mov	ah,al				;zeichen kopieren
	mov	bx,offset caselist		;umsetzungsliste laden
swapcase1:
	cmp	byte ptr [bx],0			;ende?
	jz	swapcase5
	mov	dl,byte ptr [bx]		;zeichen laden
	mov	dh,dl
	mov	cl,byte ptr [bx+1]		;komplement„rzeichen laden
	mov	ch,cl
	add	bx,2
	cmp	cl,'-'				;bereichsdefinition?
	jnz	swapcase2
	mov	dh,byte ptr [bx]		;obere schranke laden
	mov	cl,byte ptr [bx+1]		;untere komplement„rschranke
	mov	ch,dh				;obere komplement„rschranke
	sub	ch,dl
	add	ch,cl
	add	bx,2
swapcase2:
	cmp	al,dl				;zeichencode zu niedrig?
	jb	swapcase3
	cmp	al,dh				;zeichencode zu hoch?
	jna	swapcase4			;ok
swapcase3:
	xchg	cx,dx				;komplement testen
	cmp	al,dl				;zeichencode zu niedrig?
	jb	swapcase1
	cmp	al,dh				;zeichencode zu hoch?
	ja	swapcase1
swapcase4:
	sub	ah,dl				;zeichen konvertieren
	add	ah,cl
swapcase5:
	ret
caselist:
	db	"a-zA„”™š",0			;umsetzungsliste
;
;==============================================================================
;
;	>	si  -  trefferadresse (0 = tabellenende)
;
;------------------------------------------------------------------------------
;
displayhit:
	cmp	si,0				;tabellenende?
	jnz	displayhit2
	mov	ax,word ptr hitcount		;treffer vorhanden?
	or	ax,word ptr hitcount+2
	jz	displayhit1
	mov	si,offset bottom		;tabelle beenden
	call	display
displayhit1:
	jmp	displayhit7
displayhit2:
	push	si
	mov	ax,word ptr hitcount		;erster treffer?
	or	ax,word ptr hitcount+2
	jnz	displayhit4
	cmp	byte ptr listall?,0		;alle dateien auflisten?
	jnz	displayhit3
	call	displayfullname			;vollen dateinamen anzeigen
displayhit3:
	mov	si,offset top			;tabelle beginnen
	call	display
	add	word ptr filecount,1		;dateien z„hlen
	adc	word ptr filecount+2,0
displayhit4:
	mov	si,offset line1			;trenner #1
	call	display
	pop	si
	push	si
	mov	ax,word ptr sourceoffset	;trefferposition berechnen
	mov	dx,word ptr sourceoffset+2
	sub	si,word ptr sourcebuffer
	add	ax,si
	adc	dx,0
	sub	ax,word ptr patternlength
	sbb	dx,0
	call	displaydouble			;trefferposition anzeigen
	mov	si,offset line2			;trenner #2
	call	display
	pop	si
	mov	ax,word ptr patternlength	;kontextanfang berechnen
	shr	ax,1
	sub	si,ax
	sub	si,offset context_/2
	mov	cx,offset context_		;kontext anzeigen
displayhit5:
	push	cx
	push	si
	mov	dl,byte ptr [si]		;zeichen laden
	cmp	dl,20h				;sichtbares zeichen?
	jnb	displayhit6
	mov	dl,'.'				;ersatzdarstellung
displayhit6:
	mov	ah,character			;zeichen anzeigen
	int	dos
	pop	si
	pop	cx
	inc	si
	loop	displayhit5
	mov	si,offset line3			;trenner #3
	call	display
	add	word ptr hitcount,1		;treffer z„hlen
	adc	word ptr hitcount+2,0
displayhit7:
	ret
;
;==============================================================================
;
;	keine parameter
;
;------------------------------------------------------------------------------
;
displayfullname:
	mov	byte ptr outputflag,-1		;anzeigeflag setzen
	mov	si,offset filenametext		;dateinamen einleiten
	call	display
	mov	si,offset currentdir		;aktuelles verzeichnis anzeigen
	call	display
	mov	si,offset sourcename		;aktuelle datei anzeigen
	jmp	display
;
;==============================================================================
;
;	>	si  -  string
;
;	<	al  -  letztes zeichen
;
;------------------------------------------------------------------------------
;
display:
	mov	al,0				;letztes zeichen undefiniert
display1:
	mov	dl,byte ptr [si]		;zeichen laden
	inc	si
	cmp	dl,0				;endezeichen?
	jnz	display2
	ret
display2:
	push	dx
	push	si
	mov	ah,character
	int	dos
	pop	si
	pop	ax
	jmp	display1			;n„chstes zeichen
;
;==============================================================================
;
;	>	dx:ax  -  32-bit-zahl
;
;------------------------------------------------------------------------------
;
displaydouble:
	push	ax
	mov	ax,dx				;oberes wort anzeigen
	call	displayword
	pop	ax				;unteres wort anzeigen
	jmp	displayword
;
;==============================================================================
;
;	>	ax  -  16-bit-zahl
;
;------------------------------------------------------------------------------
;
displayword:
	push	ax				;16-bit-hex-anzeige
	mov	al,ah
	call	displayword1
	pop	ax
displayword1:
	push	ax				;8-bit-hex-anzeige
	mov	cl,4
	ror	al,cl
	call	displayword2
	pop	ax
displayword2:
	and	al,0fh				;4-bit-hex-anzeige
	cmp	al,10
	jb	displayword3
	add	al,'A'-('9'+1)
displayword3:
	add	al,'0'
	mov	dl,al				;zeichen anzeigen
	mov	ah,character
	int	dos
	ret
;
;==============================================================================
;
;	<	c  -  gesetzt falls abbruch
;
;	ax, bx, cx, dx, si, di, bp nicht ge„ndert
;
;------------------------------------------------------------------------------
;
checkbreak:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	mov	ah,1				;daten vorhanden?
	int	kbd
	clc
	jz	checkbreak3
	mov	ah,0				;daten abholen
	int	kbd
	cmp	al,cr				;unterbrechen?
	jnz	checkbreak2
checkbreak1:
	mov	ah,0				;auf taste warten
	int	kbd
	cmp	al,cr				;weiter?
	jz	checkbreak2
	cmp	al,escape			;abbrechen?
	jnz	checkbreak1
checkbreak2:
	sub	al,escape			;abbrechen?
	sub	al,1
checkbreak3:
	mov	al,0				;break-flag definieren
	rcr	al,1
	rol	al,1
	mov	byte ptr breakflag,al
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
;
;==============================================================================
;
;				     texte
;
;==============================================================================
;
signon:		;startmeldung
db cr,lf
db "SBS LOOK V1.2 ş 06-02-1994 Sven B. Schreiber ş This is Public Domain software",cr,lf
db 0
;
;------------------------------------------------------------------------------
;
filenametext:	;text vor dateinamen
db cr,lf
db "  "
db 0
;
;------------------------------------------------------------------------------
;
top:		;tabellenkopf
db cr,lf
db "ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿",cr,lf
db "³  Offset  ³                            Context                             ³",cr,lf
db "ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´"
db 0
;
line1:
db cr,lf
db "³ "
db 0
;
line2:
db " ³ "
db 0
;
line3:
db " ³"
db 0
;
bottom:
db cr,lf
db "ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[SBS]ÄÙ"
db 0
;
;------------------------------------------------------------------------------
;
commandinfo:	;info bei fehlerhafter kommandozeile
db cr,lf
db "ÚÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿",cr,lf
db '³ Command ³ LOOK <File> "<Text>" [<Options>]                     ³',cr,lf
db "³         ³ LOOK <File> '<Text>' [<Options>]                     ³",cr,lf
db "ÃÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´",cr,lf
db "³ Options ³ +c / -c : Case sensitive / Ignore case               ³",cr,lf
db "³         ³ +w / -w : Wildcard '?' recognized / ignored          ³",cr,lf
db "³         ³ +a / -a : List all files / matching files only       ³",cr,lf
db "³         ³ +r / -r : Recurse / don't recurse directories        ³",cr,lf
db "ÃÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´",cr,lf
db "³ Default ³ -c +w +a -r                                          ³",cr,lf
db "³         ³ A single +/- prefix can precede more than one option ³",cr,lf
db "³         ³ Omitting +/- inverts default settings                ³",cr,lf
db "ÀÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[SBS]ÄÙ",cr,lf
db 0
;
;------------------------------------------------------------------------------
;
invaliddir:	;ungltiges verzeichnis
db cr,lf
db "  Invalid directory",cr,lf
db 0
;
;------------------------------------------------------------------------------
;
erroropen:	;fehler beim ”ffnen
db "  -  Error opening file"
db 0
;
;------------------------------------------------------------------------------
;
errorread:	;fehler beim lesen
db "  -  Error reading file"
db 0
;
;------------------------------------------------------------------------------
;
errorsclose:	;fehler beim schlieáen
db "  -  Error closing file"
db 0
;
;------------------------------------------------------------------------------
;
newline:	;neue zeile
db cr,lf
db 0
;
;------------------------------------------------------------------------------
;
root:		;hauptverzeichnis
db "\"
db 0
;
;------------------------------------------------------------------------------
;
parent:		;bergeordnetes verzeichnis
db ".."
db 0
;
;------------------------------------------------------------------------------
;
allfiles:	;suchmuster fr alle dateien
db "*.*"
db 0
;
;==============================================================================
;
;				   variablen
;
;==============================================================================
;
filename_	equ	8 + 1 + 3 + 1		;maximale dateinamensl„nge
path_		equ	64			;maximale pfadl„nge
fullpath_	equ	3 + path_ + 1		;pfadl„nge incl. laufwerk
namebuffer_	equ	2 + fullpath_ + 4	;namenspufferl„nge
dosbuffer_	equ	43			;dos-pufferl„nge
;
pattern_	equ	32			;maximale suchmusterl„nge
chartable_	equ	256
positiontable_	equ	chartable_*(pattern_/8)	;positionstabellenl„nge
context_	equ	62			;l„nge des kontextbereichs
databuffer_	equ	0E000h			;datenpufferl„nge
variables1	equ	$
;
;------------------------------------------------------------------------------
;
breakflag	equ	variables1			;abbruchsflag
outputflag	equ	breakflag       + 1		;anzeigeflag
namebuffer	equ	outputflag      + 1		;namenspuffer
dosbuffer	equ	namebuffer      + namebuffer_	;dos-puffer
startdir	equ	dosbuffer       + dosbuffer_	;startverzeichnis
basedir		equ	startdir        + fullpath_	;basisverzeichnis
lastdir		equ	basedir         + fullpath_	;letztes verzeichnis
currentdir	equ	lastdir         + fullpath_	;aktuelles verzeichnis
filepath	equ	currentdir      + fullpath_	;dateipfadadresse
filepattern	equ	filepath        + 2		;dateimusteradresse
sourcename	equ	filepattern     + 2		;quelldateiname
sourcehandle	equ	sourcename      + filename_	;quelldateihandle
sourcebuffer	equ	sourcehandle    + 2		;quelldateipuffer
sourceblock	equ	sourcebuffer    + 2		;quellblockl„nge
sourcepostblock	equ	sourceblock     + 2		;nachspannl„nge
sourceoffset	equ	sourcepostblock + 2		;quelldateioffset
filecount	equ	sourceoffset    + 4		;dateiz„hler
hitcount	equ	filecount       + 4		;trefferz„hler
pattern		equ	hitcount        + 4		;suchmuster
patternlength	equ	pattern         + pattern_	;suchmusterl„nge
positiontable	equ	patternlength   + 2		;positionstabelle
variables2	equ	positiontable   + positiontable_
;
;------------------------------------------------------------------------------
;
prebuffer	equ	variables2			;vorspannpuffer
databuffer	equ	prebuffer       + context_	;datenpuffer
postbuffer	equ	databuffer      + databuffer_	;nachspannpuffer
variables3	equ	postbuffer      + context_
;
;------------------------------------------------------------------------------
;
freememory	equ	variables3			;freispeicher
;
;==============================================================================
;
code	ends
	end	start

