;----------------------------------------------------------------------------;
; reset.asm                                                                  ;
;                                                                            ;
; resets the video mode to 03h 80x25 16 color, text                          ;
;----------------------------------------------------------------------------;
Cgroup group    code_seg
        assume  cs:cgroup

code_seg  segment   public
          org  100h           ;set for .Com file
          public main
main      proc 

          mov  ax,0003h       ;int 10h function 00h, set video mode
                              ;select video mode 03h, 80x25 16 color, text
          int  10h            ;call interupt 10h, video bios functions
          int  20h
main      endp 

code_seg  ends
     end  main