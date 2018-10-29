CODE_SEG       SEGMENT
          MOV       AH,02h    ;select DOS function 2, character output
          MOV       DL,02Ah   ;load the ascii code fo '*' to be printed
          INT       21h       ;print '*' with INT 21h
          INT       20h       ;exit to DOS
CODE_SEG       ENDS
          END