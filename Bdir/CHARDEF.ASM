;----------------------------------------------------------------------------;
; chardef.Asm                                                                ;
;                                                                            ;
; character bitmap (16 bytes for a vga, which displays                       ;
; characters in a 9 x 16 matrix).                                            ;
;----------------------------------------------------------------------------;
Cgroup group    code_seg
        assume  cs:cgroup
;----------------------------------------------------------------------------;
;  code segment begins                                                       ;
;----------------------------------------------------------------------------;
code_seg  segment   public
          org  100h           ;set for .Com file
          public newchar
newchar   proc far
          mov  ax,1100h       ;function/subfunction
          mov  bx,1000h       ;16 bytes per character/write to table 0
          mov  cx,1           ;one character to write
          mov  dx,0c4h        ;ascii code
          push cs             ;point es:bp to bitmap
          pop  es
          mov  bp,offset chardef
          int  10h            ;load the bitmap
          int  20h
newchar   endp 
;----------------------------------------------------------------------------;
;  Character bit maps                                                        ;
;----------------------------------------------------------------------------;
chardef   db   11111111b      ;row 1 
          db   11111111b      ;row 2
          db   11000001b      ;row 3
          db   11000001b      ;row 4
          db   11000001b      ;row 5
          db   11000001b      ;row 6
          db   11000001b      ;row 7
          db   11000001b      ;row 8
          db   11000001b      ;row 9
          db   11000001b      ;row 10
          db   11000001b      ;row 11
          db   11000001b      ;row 12
          db   11000001b      ;row 13
          db   11000001b      ;row 14
          db   11111111b      ;row 15
          db   11111111b      ;row 16

code_seg  ends
     end  newchar