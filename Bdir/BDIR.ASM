; bdir.asm  --  browse directory
;
; written by John Heitmuller, 1990

init_alloc   equ     1000     ;initial amount of memory to reserve for bdir.exe in 16 byte paragraphs
c_return     equ     13       ;carriage return character is 13
line_feed    equ     10       ;line feed character is 10
video_pg     equ     0        ;use video page 0 on all writes to display
r_scr_col    equ     79       ;last video text column is 79
b_scr_row    equ     24       ;bottom screen row is 24
pad_char     equ     20h      ;use a blank space to pad strings


title        dbir.asm    ;designate title for source listing
dosseg                   ;use ms-dos segment convention
.8086                    ;enable assembly of 8086 instruction set only
.model       large       ;designate large memory model
.stack       100h        ;allocate 256 byte stack

;------------------------------------------------;
.data               ;begin data segment          ;
;------------------------------------------------;
box_table    db      "             "    ;box type 0
             db      "ÚÄ¿³³ÀÄÙÅÃ´ÂÁ"    ;box type 1
             db      "ÉÍ»ººÈÍ¼ÎÌ¹ËÊ"    ;box type 2
             db      "ÖÄ·ººÓÄ½×Ç¶ÒÐ"    ;box type 3
             db      "ÕÍ¸³³ÔÍ¾ØÆµÑÏ"    ;box type 4
             db      "ÜÜÜÞÝßßßÝÝÝÝÝ"    ;box type 5
             db      "ØÙÚÞÝÜßÛ     "    ;box type 6, used for redefinition

file_structure struc                    ;disk transfer area for file data
     reserved  db    21 dup (00h)       ;reserved by microsoft
     fattrib   db    00h                ;file attribute byte
     ftime     dw    0000h              ;file time last altered
     fdate     dw    0000h              ;flle date last altered
     fsize     dd    00000000h          ;file size in bytes
     fname     db    13 dup (00h)       ;file name and extension, terminated by 00h
file_structure ends
file_data file_structure <>             ;create file_data stucture type file_structure

dir_first    dw      0000h              ;address of first dir listing in linked list
dir_last     dw      0000h              ;address of last dir listing in linked list, also used as a work area while bulding list
tscr_file    dw      0000h              ;segment address of top file record on screen
bscr_file    dw      0000h              ;segment address of bottom file record on screen
             
file_spec    db      "*.*", 77 dup (00h);search file spec upto 80 characters, default
                                        ;  to all files with all extensions
header1      db      "                                           ", 00h
header_obj1  db      " - ", 00h
header_obj2  db      " BDIR.EXE ", 00h
header_obj3  db      " ", 00h
header2      db      " File(s):           Total Bytes:           ", 00h

byte_total   dd      00000000h          ;total number of bytes in all files found
file_total   dw      0000h              ;total number of files found

init_row     db      00h                ;initial cursor row at bdir start

top_row      db      00h                ;upper left corner of box
left_col     db      00h
bot_row      db      00h                ;lower right corner of box
right_col    db      00h
t_attrib     db      07h                ;text color attribute, default white on black

mesg_table   db      "Call to int 21h, 48h failed: could not allocate memory for dir entry.   ", 00h
             db      "Call to int 21h, 4ah failed: could not resize initial memory allocation.", 00h
             db      "No files found that match search criteria                               ", 00h
             
oldbitmaps   db      128 dup (00h)      ;old bit maps of redefined characters
chardef      db      10101010b          ;row 1, upper left corner
             db      01010101b          ;row 2
             db      10101010b          ;row 3
             db      01010101b          ;row 4
             db      10101010b          ;row 5
             db      01011111b          ;row 6
             db      10101000b          ;row 7
             db      01011000b          ;row 8
             db      10101000b          ;row 9
             db      01011000b          ;row 10
             db      10101000b          ;row 11
             db      01011000b          ;row 12
             db      10101000b          ;row 13
             db      01011000b          ;row 14
             db      10101000b          ;row 15
             db      01011000b          ;row 16

             db      10101010b          ;row 1, upper horizontal bar
             db      01010101b          ;row 2
             db      10101010b          ;row 3
             db      01010101b          ;row 4
             db      10101010b          ;row 5
             db      11111111b          ;row 6
             db      00000000b          ;row 7
             db      00000000b          ;row 8
             db      00000000b          ;row 9
             db      00000000b          ;row 10
             db      00000000b          ;row 11
             db      00000000b          ;row 12
             db      00000000b          ;row 13
             db      00000000b          ;row 14
             db      00000000b          ;row 15
             db      00000000b          ;row 16

             db      10101010b          ;row 1, upper right corner
             db      01010101b          ;row 2
             db      10101010b          ;row 3
             db      01010101b          ;row 4
             db      10101010b          ;row 5
             db      11110101b          ;row 6
             db      00011010b          ;row 7
             db      00010101b          ;row 8
             db      00011010b          ;row 9
             db      00010101b          ;row 10
             db      00011010b          ;row 11
             db      00010101b          ;row 12
             db      00011010b          ;row 13
             db      00010101b          ;row 14
             db      00011010b          ;row 15
             db      00010101b          ;row 16

             db      00010101b          ;row 1, lower right corner
             db      00011010b          ;row 2
             db      00010101b          ;row 3
             db      00011010b          ;row 4
             db      00010101b          ;row 5
             db      00011010b          ;row 6
             db      00010101b          ;row 7
             db      00011010b          ;row 8
             db      00010101b          ;row 9
             db      00011010b          ;row 10
             db      00010101b          ;row 11
             db      11111010b          ;row 12
             db      01010101b          ;row 13
             db      10101010b          ;row 14
             db      01010101b          ;row 15
             db      10101010b          ;row 16

             db      10101000b          ;row 1, lower left corner
             db      01011000b          ;row 2
             db      10101000b          ;row 3
             db      01011000b          ;row 4
             db      10101000b          ;row 5
             db      01011000b          ;row 6
             db      10101000b          ;row 7
             db      01011000b          ;row 8
             db      10101000b          ;row 9
             db      01011000b          ;row 10
             db      10101000b          ;row 11
             db      01011111b          ;row 12
             db      10101010b          ;row 13
             db      01010101b          ;row 14
             db      10101010b          ;row 15
             db      01010101b          ;row 16

             db      10101000b          ;row 1, right side bar
             db      01011000b          ;row 2
             db      10101000b          ;row 3
             db      01011000b          ;row 4
             db      10101000b          ;row 5
             db      01011000b          ;row 6
             db      10101000b          ;row 7
             db      01011000b          ;row 8
             db      10101000b          ;row 9
             db      01011000b          ;row 10
             db      10101000b          ;row 11
             db      01011000b          ;row 12
             db      10101000b          ;row 13
             db      01011000b          ;row 14
             db      10101000b          ;row 15
             db      01011000b          ;row 16

             db      00010101b          ;row 1, left side bar
             db      00011010b          ;row 2
             db      00010101b          ;row 3
             db      00011010b          ;row 4
             db      00010101b          ;row 5
             db      00011010b          ;row 6
             db      00010101b          ;row 7
             db      00011010b          ;row 8
             db      00010101b          ;row 9
             db      00011010b          ;row 10
             db      00010101b          ;row 11
             db      00011010b          ;row 12
             db      00010101b          ;row 13
             db      00011010b          ;row 14
             db      00010101b          ;row 15
             db      00011010b          ;row 16

             db      00000000b          ;row 1, lower horizonal bar
             db      00000000b          ;row 2
             db      00000000b          ;row 3
             db      00000000b          ;row 4
             db      00000000b          ;row 5
             db      00000000b          ;row 6
             db      00000000b          ;row 7
             db      00000000b          ;row 8
             db      00000000b          ;row 9
             db      00000000b          ;row 10
             db      00000000b          ;row 11
             db      11111111b          ;row 12
             db      10101010b          ;row 13
             db      01010101b          ;row 14
             db      10101010b          ;row 15
             db      01010101b          ;row 16

;------------------------------------------------;
.code               ;code segment begins         ;
;------------------------------------------------;
start:       mov     ah,4ah             ;release extra memory to ms-dos
             mov     bx,init_alloc      ;number of sixteen byte paragraphs to allocate
             int     21h                ;transfer to ms-dos, do memory adjustment
             jnc     mem_realloc        ;memory allocation adjusted without error
             mov     al,2               ;select message #2 from error_table
             call    terminate_bdir     ;terminate bdir because of memory allocation failure
mem_realloc:
	     mov     ax,@data		;load segment location
             mov     ds,ax              ;  into ds register
             mov     es,ax              ;initialize es to equal ds
             call    get_cursor_pos     ;get current cursor loacation data
             mov     init_row,dh        ;store the initial cursor row, will be used to position cursor when return to md-dos

;----------------------------------------------------------------------------;
; main - main program control procedure                                      ;
;----------------------------------------------------------------------------;
main         proc    near
             call    save_old_char_defs ;save char bit maps that will be over written when 'load_char_defs' redefines char bit maps
             call    load_char_defs     ;load custom character definition into character table
             call    load_file_list     ;load file info from disk into linked list
             call    sort_directory_list;sort dir filr info linked list by file name and extension
             call    initiate_display   ;draw initial browse directory on screen

read_loop:   mov     ah,00h             ;read keyboard character
             int     16h                ;transfer to rom-bios, read keyboard, no wait
             cmp     ah,80              ;was key down arrow?
             jne     check_next1        ;if not check next key type
             call    move_down_one      ;scroll display up and show next record on bottom
             jmp     read_loop          ;read next key
check_next1: cmp     ah,72              ;was key up arrow?
             jne     check_next2        ;if not check next key type
             call    move_up_one        ;scroll screen down and show next top record
             jmp     read_loop          ;read next key
check_next2: cmp     al,27              ;was key <esc>?
             jne     read_loop          ;if not read next char
             mov     al,00h             ;load bdir termination code, 00 = normal termination, no error
             call    terminate_bdir     ;terminate bdir
main      endp 

;----------------------------------------------------------------------------;
; load_file_list - load file information for all file entries that match on  ;
; file_spec into a dynamically allocated linked list                         ;
;                                                                            ;
;   linked list item format:                                                 ;
;              00-39  formatted file line item info, ready for display       ;
;              40,41  segmemt address of next item in list                   ;
;              42,43  segment address of previous item in list               ;
;                                                                            ;
;   variables: file_spec - the file specification of the files to match      ;
;   initiates: dir_first - the segment address of the first item in dir list ;
;              dir_last  - the segment address of the last item in dir list  ;
;              byte_total - total size in bytes of all files found           ;
;              file_total - total number of files found                      ;
;                                                                            ;
;   calls:   load_file_data, terminate_bdir                                  ;
;----------------------------------------------------------------------------;
load_file_list       proc     near
             pushf                      ;save flag values
             push    ax                 ;save registers
             push    bx
             push    cx
             push    dx
             push    ds
             push    es  
             push    di

             ; get first file listing in directory
             ;
             mov     ah,1ah                  ;establish the address of 'file_data'
             mov     dx,offset file_data     ;  as the disk transfer area
             int     21h                     ;transfer to ms-dos
             mov     ah,4eh                  ;find first occurrence of 'file_spec'
             mov     cx,0000h                ;search for normal file attributes only
             mov     dx,offset file_spec     ;load address of file_spec
             int     21h                     ;transfer to ms-dos
             jnc     file_found              ;file found, continue on
             mov     al,3                    ;file not found, move bdir termination code into al
             call    terminate_bdir          ;display file not found message and return to ms-dos
file_found:  inc     file_total              ;add 1 to file counter

             ; allocate memory for first file entry and
             ;    initialize first linked list ponters
             ;
             mov     ah,48h                  ;ms-dos allocate memory
             mov     bx,0003h                ;allocate 3 paragraphs, 48 bytes
             int     21h                     ;transfer to ms-dos
             jnc     first_mem_alloc_go      ;memory allocate without error
             mov     al,1                    ;select message #1 from error_table
             call    terminate_bdir          ;terminate bdir because of memory allocation failure
first_mem_alloc_go:        
             mov     es,ax                   ;point es at seg:address of new memory block
             mov     dir_first,ax            ;store loaction of first dir linked list entry
             mov     dir_last,ax             ;store current location in hold, this will be used by next entry to get addr of prev.
             mov     tscr_file,ax            ;store seg:address of first record on screen display
             xor     di,di                   ;point di at begining offset of new memory block
             mov     ax,0000h                ;initialize new memory block to zeros
             mov     cx,24                   ;count 24 words instead of 48 bytes
             rep     stosw                   ;initialize new memory block
find_next_loop:
             mov     ax, word ptr byte_total[0]      ;move old byte total into
             mov     cx, word ptr byte_total[2]      ;  cx:ax for 32-bit addition
             add     ax, word ptr file_data.fsize[0] ;  add low order 16-bits
             adc     cx, word ptr file_data.fsize[2] ;  all hight order 16-bits
             mov     word ptr byte_total[0], ax      ;update total
             mov     word ptr byte_total[2], cx
             clc                                     ;clear carry flag, just in case 32-bit add left it on
             call    load_file_data                  ;format and move data from dta to new mem block

             ; find next director entry to match file spec
             ;
             push    es                           ;store segment addr of current item on stack before getting next
             push    ds                           ;point es at the data segment
             pop     es
             mov     di,offset file_data.fname    ;point es:di at fname in prep for initialization
             mov     al,00h                       ;set initialization character to 0
             mov     cx,13                        ;count 24 words instead of 48 bytes
             rep     stosb                        ;initialize new memory block
             pop     es                           ;pop segment address of last allocated file info entry off stack

             mov     ah,4fh                       ;find next occurrence of 'file_spec'
             mov     dx,offset file_spec          ;load address of file_spec
             int     21h                          ;transfer to ms-dos
             jc      found_all                    ;if carry flag set no more file entries to find
             inc     file_total                   ;add 1 to file counter
             
             ; allocate memory for next directory entry
             ;
             mov     ah,48h                  ;ms-dos allocate memory
             mov     bx,0003h                ;allocate 3 paragraphs, 48 bytes
             int     21h                     ;transfer to ms-dos
             jnc     next_mem_alloc_go       ;memory allocate without error
             mov     al,1                    ;select message #1 from error_table
             call    terminate_bdir          ;terminate bdir because of memory allocation failure
next_mem_alloc_go:        
             mov     es:[40],ax              ;point next dir entry pointer of last mem block to address of this mem block
             mov     bx,es                   ;store current segment in dir_last
             mov     dir_last,es
             mov     es,ax                   ;point es at seg:address of new memory block
             xor     di,di                   ;point di at begining offset of new memory block
             mov     ax,0000h                ;initialize new memory block to zeros
             mov     cx,24                   ;count 24 words instead of 48 bytes
             rep     stosw                   ;initialize new memory block
             mov     es:[42],bx              ;set segment address of otem preious to this on in the list
             jmp     find_next_loop          ;carry not set,file found, loop thru and check for next

found_all:   pop     di            ;restore registers       
             pop     es
             pop     ds
             pop     dx
             pop     cx
             pop     bx
             pop     ax
             popf                  ;restore flags
             ret                   ;return to main
load_file_list       endp
 
;----------------------------------------------------------------------------;
; move_down_one - show next record in directory listing                      ;
;----------------------------------------------------------------------------;
move_down_one        proc     near
             push    ax                 ;save registers
             push    bx
             push    cx
             push    dx
             push    es

             ; check to see if at last file info block in linked list
             ;
             mov     es,bscr_file       ;move seg:address of info block of last file entry on screen
             mov     ax,es:[40]         ;move seg:address of next file info block to ax
             or      ax,ax              ;is ax 0, 0 means last file info block in list
             je      mdo_done           ;if yes, don't scroll

             ; scroll bdir display up one line
             ;
             mov     ah,6               ;scroll screen box up 
             mov     al,1               ;scroll up 1 line
             mov     bh,t_attrib        ;set color attribute of fill area
             mov     ch,3               ;set x, y coordinates of upper left
             mov     cl,38              ;  hand corner of scroll box
             mov     dh,23              ;set x, y coordinates of lower right
             mov     dl,78              ;  hand corner of scroll box
             int     10h                ;tranfer to rom-bios and scroll that baby
             
             ; display next file entry on bottom line
             ;
             mov     ax,es:[40]         ;move seg:address of next file info block to ax
             mov     es,ax              ;point es at next file info block
             xor     di,di              ;point di at first byte (0) of file info block
             mov     dh,23              ;write to line 23
             mov     dl,39              ;start writing at column 39
             call    write_string       ;write next file info line to bottom line of bdir display

             ; update linked list pointers to top and bottom screen records
             ;
             mov     bscr_file,es       ;store seg:address of new bottom screen file info block
             mov     es,tscr_file       ;right now tscr_file is pointing to line just scrolled off the screen
             mov     ax,es:[40]         ;point ax at seg:address of file info line that is new top line
             mov     tscr_file,ax       ;store seg:address of new top dir listing line on screen

mdo_done:    pop     es                 ;restore registers
             pop     dx
             pop     cx
             pop     bx
             pop     ax
             ret                        ;return to caller
move_down_one        endp

;----------------------------------------------------------------------------;
; move_up_one - show previous record in directory listing                    ;
;----------------------------------------------------------------------------;
move_up_one        proc     near
             push    ax                 ;save registers
             push    bx
             push    cx
             push    dx
             push    es

             ; check to see if at first file info block in linked list
             ;
             mov     es,tscr_file       ;move seg:address of info block of first file entry on screen
             mov     ax,es:[42]         ;move seg:address of previous file info block to ax
             or      ax,ax              ;is ax 0, 0 means last file info block in list
             je      muo_done           ;if yes, don't scroll

             ; scroll bdir display up one line
             ;
             mov     ah,7               ;scroll screen box down
             mov     al,1               ;scroll down 1 line
             mov     bh,t_attrib        ;set color attribute of fill area
             mov     ch,3               ;set x, y coordinates of upper left
             mov     cl,38              ;  hand corner of scroll box
             mov     dh,23              ;set x, y coordinates of lower right
             mov     dl,78              ;  hand corner of scroll box
             int     10h                ;tranfer to rom-bios and scroll that baby
             
             ; display previos file entry on bottom line
             ;
             mov     ax,es:[42]         ;move seg:address of previos file info block to ax
             mov     es,ax              ;point es at previous file info block
             xor     di,di              ;point di at first byte (0) of file info block
             mov     dh,3               ;write to line 3
             mov     dl,39              ;start writing at column 39
             call    write_string       ;write next file info line to bottom line of bdir display

             ; update linked list pointers to top and bottom screen records
             ;
             mov     tscr_file,es       ;store seg:address of new top screen file info block
             mov     es,bscr_file       ;right now bscr_file is pointing to line just scrolled off the screen
             mov     ax,es:[42]         ;point ax at seg:address of file info line that is new bottom line
             mov     bscr_file,ax       ;store seg:address of new top dir listing line on screen

muo_done:    pop     es                 ;restore registers
             pop     dx
             pop     cx
             pop     bx
             pop     ax
             ret                        ;return to caller
move_up_one        endp

;----------------------------------------------------------------------------;
; initiate_display - display initial bdir screen                             ;
;----------------------------------------------------------------------------;
initiate_display     proc     near
             push    ax                 ;save all registers
             push    bx
             push    cx
             push    dx
             push    ds
             push    es
             push    si
             push    di
             pushf                      ;save flags

             ; settup and display headers
             ;
             mov     bx,ds                   ;point es at data segment
             mov     es,bx    

             mov     di,offset header1       ;draw header line 1 background
             mov     dh,0
             mov     dl,37
             mov     t_attrib,31
             call    write_string          

             mov     di,offset header_obj1
             mov     dh,0
             mov     dl,37
             mov     t_attrib,112
             call    write_string          

             mov     di,offset header_obj2
             mov     dh,0
             mov     dl,53
             mov     t_attrib,7
             call    write_string          

             mov     di,offset header_obj3
             mov     dh,0
             mov     dl,77
             mov     t_attrib,112
             call    write_string          

             mov     di,offset header2 + 10
             mov     si,offset file_total    ;point si at file_total counter
             mov     ax,[si]                 ;load low order word into ax for 32-bit div 
             mov     cx,6                    ;length of decimal file_total in bytes
             mov     bl,' '                  ;pad left side with blanks
             call    cvt_word_to_dec_string  ;convert file count to dec string 

             mov     di,offset header2 + 32
             mov     si,offset byte_total    ;point si at byte_total counter
             mov     ax,[si+2]               ;load low order word into ax for 32-bit div 
             mov     dx,[si]                 ;load high order word into dx
             call    cvt_dw_to_dec_string    ;convert file count to dec string 

             mov     di,offset header2
             mov     dh,1
             mov     dl,37
             mov     t_attrib,48
             call    write_string          

             mov     top_row,2          ;define box deminsions
             mov     left_col,37 
             mov     bot_row,24
             mov     right_col,79
             mov     al,6               ;box type 
             mov     t_attrib,112       ;text attribute of box
             call    draw_box           ;draw a text box

             mov     bx,dir_first
             mov     dh,3
write_loop:
             mov     es,bx
             mov     di,00h
             mov     dl,39
             call    write_string          
             mov     bx,es:[40]
             inc     dh
             cmp     dh,24
             je      done
             or      bx,bx
             je      done
             jmp     write_loop    

done:        mov     bscr_file,es       ;store seg:address of last record on screen
             popf                       ;restore flags
             pop     di                 ;restore all registers
             pop     si
             pop     es
             pop     ds
             pop     dx
             pop     cx
             pop     bx
             pop     ax
             ret                        ;return to caller
initiate_display     endp

;----------------------------------------------------------------------------;
; sort_directory_list - bubble sort directory linked list in memory by file  ;
; name first then by file extension.                                         ;
;----------------------------------------------------------------------------;
sort_directory_list  proc     near
             push    ax                 ;save registers   
             push    bx
             push    cx
             push    dx
             push    bp
             push    ds
             push    si
             push    es
             push    di
             pushf

             cld                        ;clear direction flag, process strings in a forward manner
             mov     bp,dir_first       ;store segment addr of first entry in linked list in bp, because ds will be volatile
sdl_getfirst:mov     ds,bp              ;point ds to first entry in directory linked list
             xor     bl,bl              ;set bl = 0, if read thru whole dir list an bl still 0 then dir list sorted
sdl_getnext: xor     si,si              ;set offset into directory entry to 0           
             mov     es,ds:[40]         ;point es at next entry in directory entry
             xor     di,di              ;set offset into directroy entry to 0
             mov     cx,12              ;compare first 12 bytes. file name[8] + ' ' + file extension[3] = length[12] 
             repe    cmpsb              ;compare ds:si to ed:di, leave ds, si pointing at first byte after non-match
             dec     si                 ;point ds:si at non-matching character
             dec     di                 ;point es:di at non-matching character
             mov     ah,es:[di]         ;set ah for use in 'cmp' instruction
             cmp     byte ptr ds:[si],ah;compare non-matching bytes, since all dir file names are unique must be > or <, never will =
             jl      sdl_ds_less_than_es;jump if ds:si file name < es:di file name
             
             ; swap ds:si with es:di 
             ;
             mov     bl,1               ;set bl = 1, indicates a non-sorted entry found on this pass
             mov     cx,20              ;swap 20 words, 40 bytes
             xor     si,si              ;set offset into directory entry to 0          
             xor     di,di              ;set offset into directroy entry to 0
sdl_swaploop:mov     ax,ds:[si]         ;store ds:si word in ax
             mov     dx,es:[di]         ;store es:di word in dx
             mov     ds:[si],dx         ;retrieve es:di word stored in ax into ed:di
             mov     es:[di],ax         ;retrieve ds:si word stored in ax into ed:di
             add     si,2               ;point ds:si at next word in file name
             add     di,2               ;point es:di at next word in file name
             loop    sdl_swaploop       ;do it till 12 bytes swaped

             ; check for end of directory entry link list
             ;
sdl_ds_less_than_es:
             mov     ax,es:[40]         ;move segment address of next file entry info block into ax for 'or' instruction 
             or      ax,ax              ;if segment addr of next file entry in link list = 0, the end of list reached
             je      sdl_endlist        ;end of list has been reached, jump and check if entire list sorted yet

             ; not end of list yet, reset ds:si for next pass
             ;       
             mov     ax,es              ;point ds:si at es:di, next es:di
             mov     ds,ax              ;  wlll be set at top of loop
             jmp     sdl_getnext        ;jump to top of loop and compare next file name with the one in ds:si

             ; end of list, check bl non-sort found flag then loop or quit
             ;
sdl_endlist: or      bl,bl              ;is bl = 0?, if yes the entire file list is sorted...  say yea!
             jne     sdl_getfirst       ;if not, jump to top, reset ds:si to point to first file entry in list, and do it all again

             popf                       ;restor flags
             pop     di                 ;restore registers
             pop     es
             pop     si
             pop     ds
             pop     bp
             pop     dx
             pop     cx
             pop     bx
             pop     ax
             ret                        ;return to caller
sort_directory_list  endp

;----------------------------------------------------------------------------;
; load_file_data - decode, format and display the file data stored in a      ;
; struc of type file_structure.                                              ;
;----------------------------------------------------------------------------;
load_file_data   proc near
             push    ax                  ;save registers
             push    cx
             push    dx
             push    di
             push    si

             ; format file name and move to allocated memory segment
             ;
             mov     si,offset file_data.fname     ;load addr of source
             mov     di,0
             mov     cx,9                ;8 for file name + 1 for alignment
             mov     ah,'.'              ;'.' terminates file name in file_data.fname
             call    move_mem_pad        ;move file_data.fname to allocated memory segment
             inc     di                  ;add 1 to destination pointer to put a space between file name and extension

             ; format file extension and move to allocated memory segment
             ;
             inc     si                  ;still on '.' of file_data.fname inc to next
             mov     cx,4                ;3 for file extension + 1 for alignment
             mov     ah,00h              ;file extension terminated with 00h
             call    move_mem_pad        ;move file_data.fname to allocated memory segment

             ; format file size and move to allocated memory segment
             ;
             mov     si,offset file_data.fsize ;point si at file size for conversion
             mov     ax,[si+2]           ;load low order word into ax for 32-bit div 
             mov     dx,[si]             ;load high order word into dx for 32-bit div
             call    cvt_dw_to_dec_string;convert size to dec string in ffp_line

             ; format file date and move to allocated memory segment
             ;              
             mov     word ptr es:[di],'  ';put blank between file size and date
             add     di,2                ;point di to next character of ffp_line
             mov     dx,file_data.fdate  ;load 16 bit file date for conversion
             call    cvt_date_to_string  ;convert date in dx to string in di

             ; format file time and move to allocated memory segment
             ;              
             mov     word ptr es:[di],'  ';put blanks between file date and time
             add     di,2                ;point di to next character of ffp_line
             mov     dx,file_data.ftime  ;load 16 bit file time for conversion
             call    cvt_time_to_string  ;convert time in dx to string in di

             pop     si                  ;restore registers
             pop     di
             pop     dx
             pop     cx
             pop     ax
             ret                         ;return to caller
load_file_data   endp

;----------------------------------------------------------------------------;
; cvt_time_to_string - converts a 16 bit ms-dos file time to an ascii text   ;
; string of the format hh:mm(a/p) single character hours will be padded with ;
; a blank space.  single character minutes will be padded with a 0.  date    ;
; will be in a twelve hour format and will be followed with an 'a' for am    ;
; and a 'p' for pm.                                                          ;
;                                                                            ;
;    recieves: dx:  16 bit ms-dos file time                                  ;
;              di:  offset of begining of string destination                 ;
;----------------------------------------------------------------------------; 
cvt_time_to_string  proc near
          push ax                  ;save registers
          push bx
          push cx
          push dx

          ; calculate hours and move to string
          ;
          mov  cl,11               ;extract hour 16 bit time using the formula
          shr  dx,cl               ;  hour = time/2024
          push dx                  ;save hours in 24 hour format

          ; figure out if am or pm and store in bh
          ;
          cmp  dx,13               ;are hours greater or equal to twelve
          jl   cvd_am              ;if less than jump am
          sub  dx,12               ;subtract 12 hours from 24 hour format
          mov  bh,'p'              ;'p' for pm.
          jmp  cvd_pm
cvd_am:   mov  bh,'a'              ;'a' for am.

cvd_pm:   mov  ax,dx                    ;get ready to convert to char
          mov  cx,2                     ;number of characters = 2, 0-1
          mov  bl,' '                   ;if only 1 char pad left with blank
          call cvt_word_to_dec_string   ;do conversion

          ; do that colon thing
          ;
          inc  di                  ;point di to next character in string
          mov  byte ptr es:[di],':';put a colon on format line to separate hours from minutes
          inc  di                  ;point di to next character in string

          ; calculate minutes and move to string
          ;
          pop  ax                  ;fetch hours in 24 hour format off stack
          mov  dx,2048             ;extract minutes from time useing formula
          mul  dx                  ; minutes = ( time - ( hours * 2048 )) / 32
          pop  dx                  ;pop original time off of stack
          push dx                  ;stick a copy of time back on stack
          sub  dx,ax               ;subtract hour * 2048 from time
          mov  cl,5                ;divide result by 32
          shr  dx,cl               ;do divide
          
          mov  ax,dx                    ;get ready to convert to char
          mov  cx,2                     ;number of characters = 2, 0-1
          mov  bl,'0'                   ;if only 1 char pad left with blank
          call cvt_word_to_dec_string   ;do conversion

          ; write am or pm to string
          ;
          inc  di                  ;point di to next character in string
          mov  es:[di],bh          ;move am or pm to string

          pop  dx                  ;restore registers
          pop  cx
          pop  bx
          pop  ax
          ret                      ;return to caller
cvt_time_to_string  endp

;----------------------------------------------------------------------------;
; cvt_date_to_string - converts a 16 bit ms-dos file date to an ascii text   ;
; string of the format mm-dd-yy.  single character days will be padded with  ;
; a 0.  single character months will be padded with a blank space.           ;
;                                                                            ;
;    recieves: dx     16 bit ms-dos file date                                ;
;              es:di  offset of begining of string destination               ;
;----------------------------------------------------------------------------; 
cvt_date_to_string  proc near
          push ax                  ;save registers
          push bx
          push cx
          push dx

          mov  bx,dx     ;save original value of date in bx
          mov  ax,512    ;think ahead, mth=(date-((year-80)*512))/32

          mov  cl,9      ;extract year from file_data.fdate using the
          shr  dx,cl     ;  formula, year = (date/512)+50h.  shifting  
          push dx        ;save dx, mul will destroy
          mul  dx        ;to mul for month before add 80 for year
          sub  bx,ax     ;sub (year-80)*512 from original date
          mov  cl,5      ;prepare to shift bx to the right 5 times
          push bx        ;save month before division by 32
          shr  bx,cl     ;divide by 32, at this point month is in bx
          pop  cx        ;restore value of month before division by 32

          mov  ax,32     ;calculate day useing formula
          mul  bx        ;  day = cx - ( bx * 32 )
          sub  cx,ax     ;
          pop  dx        ;restore dx after mul
          add  dx,80     ;add 80 for year calculation

          ; at this point bx = month, cx = day, dx = year
          ;
          push dx        ;store year on stack
          push cx        ;store day on stack

          ; convert month in bx to string
          ;
          mov  ax,bx                    ;get ready to convert to char
          mov  cx,2                     ;number of characters = 2, 0-1
          mov  bl,' '                   ;if only 1 char pad left with blank
          call cvt_word_to_dec_string   ;do conversion
          inc  di                       ;point di at next character in string
          mov  byte ptr es:[di],'-'     ;do that dash thing to separate month from day

          ; convert day sitting in stack to string
          ; 
          inc  di                       ;point di to next character in string
          pop  ax                       ;pop day into ax
          mov  bl,'0'                   ;if only 1 char pad left with zero
          call cvt_word_to_dec_string   ;do conversion

          inc  di                       ;point di at next character in string
          mov  byte ptr es:[di],'-'     ;dash to separate day from year

          ; convert year sitting in stack to string
          ; 
          inc  di                       ;point di to next character in string
          pop  ax                       ;pop day into ax
          call cvt_word_to_dec_string   ;do conversion

          pop  dx                  ;restore registers
          pop  cx
          pop  bx
          pop  ax
          ret                      ;return to caller
cvt_date_to_string  endp

;----------------------------------------------------------------------------; 
; cvt_word_to_dec_string - converts a 16 bit word hex number to a right      ; 
; justified string cx bytes long.                                            ; 
;                                                                            ;
;    recieves: ax     16 bit integer to convert                              ;
;              bl     character used to pad to the right of number           ;
;              cx     number of bytes in string                              ;
;              es:di  offset of begining of string destination               ;
;----------------------------------------------------------------------------; 
cvt_word_to_dec_string    proc     near 
             pushf                      ;save registers used here 
             push    ax
             push    bx
             push    cx 
             push    dx 
             push    bp

             add     di,cx              ;add str length to address and work backwards
             dec     di                 ;backup 1, adjust for counting from 0, not 1
             push    di                 ;save position of di at right end of string
             mov     bp,10              ;set up to divide by 10 to covert to decimal
             xor     dx,dx              ;set dx to zero to accomadate 32-bit division
cw_not_zero: div     bp                 ;dx:ax/10, remainder will be a decimal digit
             add     dl,30h             ;add 30h to remainer yields the ascii code
             mov     es:[di],dl         ;move ascii character to destination string
             dec     di                 ;move back 1, writting str backwards
             xor     dx,dx              ;clear remainder from dx for next divide
             or      ax,ax              ;has division resulted in 0 yet?
             je      cw_ax_zero         ;yes, stop division and go pad string
             loop    cw_not_zero        ;not yet, continue
             jmp     cw_add_padding
cw_ax_zero:
             dec     cx                 ;drop count by one because we missed loop
                                        ;  instruction on jump
cw_add_padding:
             std                        ;set carry flag, process string in reverse order
             mov     al,bl              ;specify padding character
             rep     stosb              ;pad with blanks

cw_done:     pop     di                 ;restore altered registers 
             pop     bp
             pop     dx 
             pop     cx
             pop     bx 
             pop     ax 
             popf
             ret                        ;return 
cvt_word_to_dec_string   endp 

;----------------------------------------------------------------------------; 
; cvt_dw_to_dec_string - converts a 32 bit double word hex number to a right ; 
; justified string n bytes long.                                             ; 
;                                                                            ;
;    recieves: dx:ax  32 bit integer to convert, low order 16 bits in ax     ;
;                       high order 16 bits in dx                             ;
;              es:di  offset of begining of string destination               ;
;                                                                            ;
;       calls: calc_and_write                                                ;
;----------------------------------------------------------------------------; 
cvt_dw_to_dec_string    proc     near 
             push    ax                 ;save registers
             push    bx
             push    cx 
             push    dx 
             push    bp
             pushf                      ;save flags

             xor     bp,bp              ;set bp to 0, ds is set to 1 when first digit is written to string
             mov     bx,3b9ah           ;set cx:bx = 1,000,000,000
             mov     cx,0ca00h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,05f5h           ;set cx:bx = 100,000,000
             mov     cx,0e100h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0098h           ;set cx:bx = 10,000,000
             mov     cx,9680h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,000fh           ;set cx:bx = 1,000,000
             mov     cx,4240h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0001h           ;set cx:bx = 100,000
             mov     cx,86a0h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0000h           ;set cx:bx = 10,000
             mov     cx,10000
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0000h           ;set cx:bx = 1,000
             mov     cx,1000
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0000h           ;set cx:bx = 100
             mov     cx,100
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0000h           ;set cx:bx = 10
             mov     cx,10
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0000h           ;set cx:bx = 1
             mov     cx,1
             call    calc_and_write     ;determine value of first digit and write

             popf                       ;restore flags
             pop     bp                 ;restore altered registers 
             pop     dx
             pop     cx
             pop     bx 
             pop     ax 
             ret                        ;return 
cvt_dw_to_dec_string   endp 
;----------------------------------------------------------------------------;
; calc_and_write - called from cvt_dw_to_dec_string.  determines the value   ;
; of the next decimal digit to be written to es:di destination string        ;
;                                                                            ;
;    recieves: dx:ax  32 bit number under conversion by cvt_dw_to_dec_string ;
;              cx:bx  current decimal position looking for.                  ;
;              es:di  pointer to memory location to write decimal digit      ;
;     returns: es:di  memory location for next digit to be written           ;
;----------------------------------------------------------------------------;
calc_and_write       proc     near
             push    si            ;save registers

             ; get value of decimal digit
             ;
             mov     si,-1         ;really setting si to zero, si will be used to calc decimal digit value
caw_subloop: inc     si            ;count times through loop, this will be the value of the decimal digit
             sub     dx,cx         ;subtract high order word of decimal position from high order byte of value under conversion
             sbb     ax,bx         ;finish subtraction of cx:bx from dx:ax by subtracting low order words
             jnb     caw_subloop   ;checking carry flag. if set, we have subtracted this unsigned down passes 0 and is 'negative'
             add     dx,cx         ;add decimal position value back to dx:ax one time
             adc     ax,bx

             ; translate decimal digit to ascii and write to string
             ;
             or      bp,bp              ;is bp = 0?
             jne     caw_setdigit       ;if no, bp = 1, the first digit has been written no need for more string padding
             or      si,si              ;is value of decimal digit zero?
             je      caw_writepad       ;yes, write a pad_char instead of a 0
             inc     bp                 ;set bp to 1, indicates first digit has been written to string
caw_setdigit:mov     bx,si              ;move decimal digit value to a general purpose register
             add     bl,'0'             ;convert decimal value into ascii representation of decimal value
             jmp     caw_done           ;go write character
caw_writepad:mov     bl,pad_char        ;set character to write to pad_char
caw_done:    mov     byte ptr es:[di],bl;ship ascii value out to string current string location
             inc     di                 ;point es:di at next byte in string
             
             pop     si            ;restore registers
             ret                   ;return to cvt_dw_to_dec_string
calc_and_write       endp

;----------------------------------------------------------------------------;
; move_mem_pad - copies the source memory to destination until the           ;
; terminating character is incountered,  then pads with blanks until         ;
; string length (cx) is reached.                                             ;
;                                                                            ;
; recieves:    ah        ascii character that terminates string,             ;
;                          if other than a null 00h, else set to null 00h    ;
;              cx        string length                                       ;
;              ds:si     offset of source                                    ;
;              es:di     offset of destination                               ;
;                                                                            ;
; returns:     al        last character written                              ;
;              es:di     last character of destination written               ;
;              ds:si     last character of source written                    ;
;----------------------------------------------------------------------------;
move_mem_pad proc    near
             push    cx                 ;save register
             
mmp_next:    mov     al,[si]            ;get byte from source
             cmp     al,ah              ;check for terminating character
             je      mmp_end            ;terminating character found, stop copy
             or      al,al              ;check for terminating null 00h
             je      mmp_end            ;terminating character found, stop copy
             movsb                      ;move a byte from ds:si to es:di
             loop    mmp_next           ;check next byte
mmp_end:
             mov     al,' '             ;if not, pad destination w/ blanks
             rep     stosb              ;pad string with blanks

mmp_done:    dec     di                 ;backup pointer to source by 1
             pop     cx                 ;restore register before exit
             ret                        ;return to caller
move_mem_pad endp
;----------------------------------------------------------------------------;
; write_string - writes a null terminated character string to the video      ;
; display.                                                                   ;
;                                                                            ;
;     variables:     t_attrib                                                ;
;            dh      row coordinate of text starting position                ;
;            dl      column coordinate of text starting position             ;
;            es:di   offset offset of first character in string              ;
;                                                                            ;
;         calls:     write_char                                              ;
;----------------------------------------------------------------------------;
write_string proc    near
             push    ax            ;save registers
             push    di
             
             call    goto_xy       ;position cursor at starting x,y coordinates
sw_next_char:mov     al,es:[di]    ;load character from string into al
             or      al,al         ;check for terminating null character, 00h
             je      ws_done       ;string character = null, the job is done
             call    write_char    ;write character to screen
             inc     di            ;point di at next character in string
             jmp     sw_next_char  ;do it again

ws_done:     pop     di            ;restore registers
             pop     ax
             ret                   ;return to caller
write_string endp
;----------------------------------------------------------------------------;
; draw_box - draw a text box on screen                                       ;
;    variables: db top_row, db left_col, db bot_row, db right_col            ;
;         al:  box type, 0 thru 5.                                           ;
;         bl:  box color attribute                                           ;
;                                                                            ;
; calls:  write_char, write_char_n_times, vert_write_char_n_times            ;
;----------------------------------------------------------------------------;
draw_box  proc near
          push ax             ;save registers
          push cx
          push dx
          push si

          call clear_box      ;clear thearea box will be displayed in
          ;
          ; determine base offset into box_table for this box type 
          ;
          mov  si, offset box_table ;point si at box_table
          mov  dl,13          ;determine the offset into 'box_table' of this
          mul  dl             ;  box types characters, offset is in ax
          add  si,ax          ;add offset into table to beginning of table
          ;
          ; calculate width of box
          ;
          xor  cx,cx          ;set cx to 0, before calculating width
          mov  cl,right_col   ;load coordinate of left column into cl
          sub  cl,left_col    ;subtract left from right to get width
          sub  cl,1           ;subtract 2 from width to accomodate corners
          ;
          ; draw lower left hand corner
          ;
          mov  dh,bot_row          ;position cursor a lower, left hand corner 
          mov  dl,left_col         ;  of box load x,y text coordinates in dx
          call goto_xy             ;position cursor at (x dl, y dh)
          mov  al,[si+5]           ;load lower left corner character
          call write_char          ;write character in al to screen
          ;
          ; draw bottom bar of box
          ;
          mov  al,[si+6]           ;load bottom left corner character
          call write_char_n_times  ;write character in al to screen
          ;
          ; draw lower right hand corner
          ;
          mov  al,[si+7]           ;load lower right corner character
          call write_char          ;write character in al to screen
          ;
          ; draw upper left hand corner
          ;
          mov  dh,top_row          ;position cursor a top, left hand corner 
          mov  dl,left_col         ;  of box load x,y text coordinates in dx
          call goto_xy             ;position cursor at (x dl, y dh)
          mov  al,[si]             ;load upper left corner character
          call write_char          ;write character  in al to screen
          ;
          ; draw top bar of box
          ;
          mov  al,[si+1]           ;load upper left corner character
          call write_char_n_times  ;write character in al to screen
          ;
          ; draw upper right hand corner
          ;
          mov  al,[si+2]           ;load upper right corner character
          call write_char          ;write character in al to screen
          ;
          ; calculate height of box
          ;
          xor  cx,cx          ;set cx to 0, before calculating width
          mov  cl,bot_row     ;load coordinate of left column into cl
          sub  cl,top_row     ;subtract left from right to get width
          sub  cl,1           ;subtract 2 from width to accomodate corners
          ;
          ; draw right side bar of box
          ;
          mov  dh,top_row          ;position cursor a top, right hand corner 
          mov  dl,right_col        ;  of box load x,y text coordinates in dx
          inc  dh                  ;move cursor down 1 row
          call goto_xy             ;position cursor at (x dl, y dh)
          mov  al,[si+3]           ;load upper left corner character
          call vert_write_char_n_times  ;write character in al to screen
          ;
          ; draw left side bar of box
          ;
          mov  dh,top_row          ;position cursor a lower, left hand corner 
          mov  dl,left_col         ;  of box load x,y text coordinates in dx
          inc  dh                  ;move cursor down 1 row
          call goto_xy             ;position cursor at (x dl, y dh)
          mov  al,[si+4]           ;load upper left corner character
          call vert_write_char_n_times  ;write character in al to screen

          pop  si             ;restore registers before return
          pop  dx
          pop  cx
          pop  ax
          ret                 ;return to caller
draw_box  endp
;----------------------------------------------------------------------------; 
; Write more than one copy of a character                                    ; 
;    al   ascii code of character to write                                   ;
;    cx   number of times to write character                                 ;
;    dh   screen row coordinate                                              ;
;    dl   screen column coordinate                                           ;
;                                                                            ; 
; calls:  write_char                                                         ; 
;----------------------------------------------------------------------------; 
write_char_n_times  proc  near 
        push    cx            ;save register 
n_times: 
        call    write_char    
        loop    n_times       ;loop till cx equal zero 
        pop     cx            ;restore register 
        ret                   ;return to calling routine 
write_char_n_times  endp 
;----------------------------------------------------------------------------; 
; Write more than one copy of a character in a vertical row desending down   ; 
; from initial position in (dh row, dl col).                                 ;
;    al   ascii code of character to write                                   ;
;    cx   number of times to write character                                 ;
;    dh   screen row coordinate                                              ;
;    dl   screen column coordinate                                           ;
;                                                                            ; 
; calls:  write_char                                                         ; 
;----------------------------------------------------------------------------; 
vert_write_char_n_times  proc  near 
        push    cx            ;save register 
vert_n_times: 
        call    write_char    
        inc     dh            ;adjust row 1 down for next write
        call    goto_xy       ;position cursor at (x dl, y dh)
        loop    vert_n_times  ;loop till cx equal zero 
        pop     cx            ;restore register 
        ret                   ;return to calling routine 
vert_write_char_n_times  endp 

;----------------------------------------------------------------------------;
; write_char - this procedure writes a character to the video display at the ;
; current cursor position using the rom bios.  the cursor position is then   ;
; incremented 1 to the right.  if the end of line is reached the a carriage  ;
; return, line feed combination is issued.                                   ;
;                                                                            ;
;            al      character to write to video display                     ;
;                                                                            ;
;            calls:  cursor_right                                            ;
;----------------------------------------------------------------------------;
write_char   proc    near
             push    ax            ;save registers
             push    bx
             push    cx
             mov     ah,9          ;int 10h, func 9, write char/attrib to disp.
             mov     bh,video_pg        ;set video page to write to
             mov     bl,t_attrib   ;use global text color attribute        
             mov     cx,1          ;write character once
             int     10h           ;write char and attribute to video display
             call    cursor_right  ;move cursor right to next position

             pop     cx            ;restore registers
             pop     bx
             pop     ax
             ret                   ;return to caller
write_char   endp

;----------------------------------------------------------------------------;
; get_cursor_pos - gets the x, y coordinates of the cursor                   ;
;                                                                            ;
;  returns:  ch      starting line of cursor in char pixel box               ;
;            cl      ending line of cursor                                   ;
;            dh      row (y coordinate)                                      ;
;            dl      col (x coordinate)                                      ;
;----------------------------------------------------------------------------;
get_cursor_pos       proc     near
             push    ax                 ;save registers
             push    bx

             mov     ah,3               ;bios get cursor info function
             mov     bh,video_pg        ;set video page to read cursor info from
             int     10h                ;transfer to rom-bios, video functions

             pop     bx                 ;restore registers
             pop     ax
             ret                        ;return to caller
get_cursor_pos       endp

;----------------------------------------------------------------------------;
; cursor_right - move the cursor one column to the right of the current      ;
; cursor position.  if the new position is > 79 the a carriage return, line  ;
; feed combination is issued.                                                ;
;----------------------------------------------------------------------------;
cursor_right proc    near
             push    ax            ;save registers
             push    bx
             push    dx

             mov     ah,3          ;read current cursor position
             mov     bh,video_pg        ;set video page to read cursor position from
             int     10h           ;read cursor position

             dec     ah            ;set ah=2, set new cursor position
             inc     dl            ;add 1 to current column coordinate
             cmp     dl,r_scr_col  ;is column <= end of screen display
             jbe     cr_column_ok  ;yes, column <=79, carriage rtn not needed

             mov     dl,c_return   ;move carriage return character to dl
             int     21h           ;send carriage return to video display
             mov     dl,line_feed  ;move cursor down one line
;            int     21h           ;send line feed to video display
             jmp     cr_done       ;cursor already moved, no need for interupt
cr_column_ok:int     10h           ;update cursor position one to the write

cr_done:     pop     dx            ;restore registers
             pop     bx
             pop     ax
             ret                   ;return to caller
cursor_right endp

;----------------------------------------------------------------------------;
; moves cursor to text row, col screen position                              ;
;                                                                            ;
;       dh      row (y)                                                      ;
;       dl      column (x)                                                   ;
;----------------------------------------------------------------------------;
goto_xy         proc     near
        push    ax                      ;save registers
        push    bx

        mov     bh,video_pg             ;text display page 0       
        mov     ah,2                    ;call for set cursor position
        int     10h                     ;call video bios

        pop     bx                      ;restore registors
        pop     ax
        ret                             ;return to calling procedure
goto_xy         endp

;----------------------------------------------------------------------------;
; clear_box - clear a box on the video display and set the back ground color ;
;    variables: db top_row, db left_col, db bot_row, db right_col            ;
;----------------------------------------------------------------------------;
clear_box    proc    near
             push    ax            ;save registers
             push    bx
             push    cx
             push    dx

             mov     ax,0600h      ;clear window
             mov     ch,top_row    ;upper left hand corner
             mov     cl,left_col   ;
             mov     dh,bot_row    ;lower right hand corner
             mov     dl,right_col  ;
             mov     bh,t_attrib   ;color attribute to fill with
             int     10h           ;call video bios
             pop     dx            ;restore registers
             pop     cx
             pop     bx
             pop     ax
             ret                   ;return to calling procedure
clear_box    endp

;----------------------------------------------------------------------------;
; clears the screen in text modes                                            ;
;----------------------------------------------------------------------------;
clear_screen    proc     near
        push    ax                      ;save registers
        push    bx
        push    cx
        push    dx
        xor     al,al                   ;clear window
        xor     cx,cx                   ;upper left corner at (0,0)
        mov     dh,b_scr_row            ;last screen row
        mov     dl,r_scr_col            ;last screen column
        mov     bh,t_attrib             ;use white on black attribute
        mov     ah,6                    ;clear window
        int     10h                     ;call video bios

        pop     dx                      ;restore registers
        pop     cx
        pop     bx
        pop     ax
        ret                             ;return to calling procedure
clear_screen    endp

;----------------------------------------------------------------------------;
; save_old_char_defs - save the character bit maps that will be over written ;
; when 'load_char_def' redefines character bit maps in the ms-dos character  ;
; definition table                                                           ;
;                                                                            ;
;     variables: oldbitmaps
;----------------------------------------------------------------------------;
save_old_char_defs   proc     near
             push    ax                 ;save registers
             push    bx
             push    cx
             push    ds
             push    si
             push    es
             push    di
             push    bp

             ; get address of mcga/vga font table used by ms-dos
             ;
             mov     ax,1130h           ;video function/subfunction, get font table address
             mov     bh,06h             ;set for 8x16 mcga/vga font
             int     10h                ;call video bios, get font info
             
             ; copy bit-maps of chars d8 thru df to oldbitmaps
             ;
             mov     di, offset oldbitmaps ;point di at offset of oldbitmaps while ds still points at data segment
             push    ds                 ;save segment address of data segment
             mov     ax,es              ;point ds at font table segment address
             mov     ds,ax
             mov     si,bp              ;point si at font table offset
             add     si,3456            ;point si at char bit maps that will be altered by load_char_defs
             pop     es                 ;point es at data segment

             mov     cx,64              ;copy 64 word, 128 bytes
             rep     movsw

             pop     bp                 ;restore registers
             pop     di
             pop     es
             pop     si
             pop     ds
             pop     cx
             pop     bx
             pop     ax
             ret                        ;return to main
save_old_char_defs   endp

;----------------------------------------------------------------------------;
; load_char_defs - load cuatom character definitions to replace some line    ;
; draw characters for boxes                                                  ;
;                                                                            ;
;     variables:     chardef                                                 ;
;----------------------------------------------------------------------------;
load_char_defs       proc     near
             push    ax            ;save registers
             push    bx
             push    cx
             push    dx
             push    bp
             push    es

             mov     ax,1100h      ;function/subfunction
             mov     bx,1000h      ;16 bytes per character/write to table 0
             mov     cx,8          ;five characters to write
             mov     dx,0d8h       ;ascii code
             push    ds            ;point es:bp to bitmap
             pop     es
             mov     bp,offset chardef
             int     10h           ;load the bitmap

             pop     es            ;restore registers
             pop     bp
             pop     dx
             pop     cx
             pop     bx
             pop     ax
             ret                   ;return to caller
load_char_defs       endp

;----------------------------------------------------------------------------;
; restore_char_defs - restore character bit maps over written by bdir        ;
;                                                                            ;
;     variables:     oldbitmaps                                              ;
;----------------------------------------------------------------------------;
restore_char_defs       proc     near
             push    ax            ;save registers
             push    bx
             push    cx
             push    dx
             push    bp
             push    es

             mov     ax,1100h      ;function/subfunction
             mov     bx,1000h      ;16 bytes per character/write to table 0
             mov     cx,8          ;five characters to write
             mov     dx,0d8h       ;ascii code
             push    ds            ;point es:bp to bitmap
             pop     es
             mov     bp,offset oldbitmaps
             int     10h           ;load the bitmap

             pop     es            ;restore registers
             pop     bp
             pop     dx
             pop     cx
             pop     bx
             pop     ax
             ret                   ;return to caller
restore_char_defs       endp

;----------------------------------------------------------------------------;
; terminate_bdir - terminate bdir and display an informative message         ;
;                                                                            ;
;            al      # of message in the message table                       ;
;----------------------------------------------------------------------------;
terminate_bdir       proc     near
             ; display exit message if ah > 00h
             ;
             push    ax                      ;save termination code

             mov     bx,@data                ;reinit segment pointers in case an
             mov     ds,bx                   ;  error brought us here and left
             mov     es,bx                   ;  strange odities in segment regs

             call    restore_char_defs       ;restore dos font tables to its condition at entry
             or      al,al                   ;is ah (termination code) = 00h, no error
             je      bd_quit                 ;normal termination, no message to report
             mov     di, offset mesg_table   ;point di at mesg_table
             dec     al                      ;-1 from termination code to account for counting from 0
             mov     dl,73                   ;determine the offset into 'mesg_table' of this
             mul     dl                      ;  message, offset is in ax
             add     di,ax                   ;add offset into table to beginning of table
             mov     t_attrib,7              ;set text color to white on black
             mov     dh,init_row             ;set dh to cursor's initial row in bdir start
             inc     dh                      ;position cursor one row down

             cmp     dh,24                   ;make sure message will be on screen
             jle     db_mesg                 ;screen row is fine, write message
             mov     ah,2                    ;update cursor position
             mov     dh,24                   ;since row is > 24 set to 24
             mov     dl,c_return             ;move carriage return character to dl
             int     21h                     ;send carriage return to video display
             mov     dl,line_feed            ;move cursor down one line
             int     21h                     ;send line feed to video display
db_mesg:     mov     dl,0                    ;send cursor to left edge of screen
             call    write_string            ;display exit message

             pop     ax                      ;restore termination cade
bd_quit:     mov     ah,4ch                  ;load dos exit function (4ch) into ah
             int     21h                     ;call ms-dos
terminate_bdir       endp
             end     start
