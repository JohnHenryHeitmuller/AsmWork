; tcvt.asm  --  test driver for cvt_dw_to_dec_string
;
pad_char     equ     20h ;use a blank space to pad strings

title     tcvt.asm  ;designate title for source listing
dosseg              ;use ms-dos segment convention
.8086               ;enable assembly of 8086 instruction set only
.model    large     ;designate large memory model
.stack    100h      ;allocate 256 byte stack

;------------------------------------------------;
.data               ;begin data segment          ;
;------------------------------------------------;
str_length   db      00h

buffer1      db      40 dup(00h)
buffer2      db      40 dup(00h)
buffer3      db      40 dup(00h)
buffer4      db      40 dup(00h)

;------------------------------------------------;
.code               ;code segment begins         ;
;------------------------------------------------;
main:        mov     ax,@data           ;load segment location
             mov     ds,ax              ;  into ds register
             mov     es,ax              ;initialize es to point at ds

             ; test max value
             ;
             mov     di,offset buffer1  ;point es:di at 1st byte of buffer
             mov     ax,0ffffh          ;initialize dx:ax for conversion
             mov     dx,0ffffh           
             call    cvt_dw_to_dec_string    ;do it!

             ; test min value
             ;
             mov     di,offset buffer2  ;point es:di at 1st byte of buffer
             mov     ax,0000h           ;initialize dx:ax for conversion
             mov     dx,0004h           
             call    cvt_dw_to_dec_string    ;do it!

             ; test mid value
             ;
             mov     di,offset buffer3  ;point es:di at 1st byte of buffer
             mov     ax,0000h           ;initialize dx:ax for conversion
             mov     dx,0ffffh           
             call    cvt_dw_to_dec_string    ;do it!

             ; test another mid value
             ;
             mov     di,offset buffer4  ;point es:di at 1st byte of buffer
             mov     ax,0ffffh          ;initialize dx:ax for conversion
             mov     dx,0000h           
             call    cvt_dw_to_dec_string    ;do it!

             mov     ax,4c00h           ;load dos exit function 4e into ah and 
                                        ;  exit status 0 into al
             int     21h                ;call ms-dos
;----------------------------------------------------------------------------; 
; cvt_dw_to_dec_string - converts a 32 bit double word hex number to a right ; 
; justified string n bytes long.                                             ; 
;                                                                            ;
;    recieves: dx:ax  32 bit integer to convert, low order 16 bits in ax     ;
;                       high order 16 bits in dx                             ;
;              es:di  offset of begining of string destination               ;
;                                                                            ;
;       calls: calc_and_write, write_comma                                      ;
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
             call    write_comma        ;write comma to string if last ascii character written not equal pad_char

             mov     bx,05f5h           ;set cx:bx = 100,000,000
             mov     cx,0e100h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0098h           ;set cx:bx = 10,000,000
             mov     cx,9680h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,000fh           ;set cx:bx = 1,000,000
             mov     cx,4240h
             call    calc_and_write     ;determine value of first digit and write
             call    write_comma        ;write comma to string if last ascii character written not equal pad_char

             mov     bx,0001h           ;set cx:bx = 100,000
             mov     cx,86a0h
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0000h           ;set cx:bx = 10,000
             mov     cx,10000
             call    calc_and_write     ;determine value of first digit and write

             mov     bx,0000h           ;set cx:bx = 1,000
             mov     cx,1000
             call    calc_and_write     ;determine value of first digit and write
             call    write_comma        ;write comma to string if last ascii character written not equal pad_char

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
; write_comma - write a comma, ascii (2ch), to destination string is the     ;
; character immediately preceding the comma position is not equal to         ;
; pad_char, else write a pad_char.                                           ;
;                                                                            ;
;   variables:  pad_char - ascii character used to pad strings               ;
;    receives:  es:di - pointer into string where comma will go              ;
;     returns:  es:di - pointing to next postion for write into string       ;
;----------------------------------------------------------------------------;
write_comma  proc    near
             push    bx                      ;save registers

             mov     bl,es:[di-1]            ;move byte preceding comma target area to bl for comparison
             cmp     bl,pad_char             ;is char preceding comma postion a pad_char
             je      wc_another_pad          ;yes, write another pad_char instead of a comma
             mov     byte ptr es:[di],','    ;no, write comma to destination string
             jmp     wc_done                 ;finished
wc_another_pad:
             mov     byte ptr es:[di],bl     ;write a pad_char to destination string instead of a comma
wc_done:     inc     di                      ;point es:di at next byte in destination string
             
             pop     bx                      ;restore registers
             ret                             ;return to caller
write_comma  endp
             end     main


