;----------------------------------------------------------------------------;
; wait_for_key - pauses program until a key is presses                       ;
;----------------------------------------------------------------------------;
wait_for_key   proc near
check_key:mov  ah,1           ;look for key press in keyboard buffer
          int  16h            ;call bios interupt 16h, keyboard functions
          jz   check_key      ;if key not pressed loop to check_key
          sub  ah,ah          ;if key pressed, clear key from buffer
          int  16h            ;call bios interupt 16h, keyboard functions
          ret                 ;return to calling procedure
wait_for_key   endp
