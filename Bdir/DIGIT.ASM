code_seg       segment
          assume    CS:code_seg
          mov       AH,1h          ;select DOS function 1, char input
          int       21h            ;read a char, return ascii code in AH
          mov       DL,AL          ;move ascii code into DL
          sub       DL,30h         ;subtract 30h to convert digit to 0 - 9
          cmp       DL,9h          ;was it a digit between 0 and 9?
          jle       DIGIT1         ;yes, we have the first digit (four bits)
          sub       DL,7h          ;no, subtract 7h to convert letter A - F
DIGIT1:
          mov       CL,4h          ;prepare to multiply by 16
          shl       DL,CL          ;multiply by shifting, becomes upper four bits
          int       21h            ;get next char
          sub       DL,30h         ;subtract 30h to convert digit to 0 - 9
          cmp       DL,9h          ;was it a digit between 0 and 9?
          jle       DIGIT2         ;yes, we have the first digit (four bits)
          sub       DL,7h          ;no, subtract 7h to convert letter A - F
DIGIT2:
          add       DL,AL          ;add second digit
          int       20h            ;exit to DOS
code_seg       ends
          end
                    