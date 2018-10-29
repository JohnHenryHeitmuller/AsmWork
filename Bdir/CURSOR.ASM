CR      EQU     13                      ;CARRIAGE RETURN CHARACTER
LF      EQU     10                      ;LINE FEED CHARACTER

CGROUP  GROUP   CODE_SEG
        ASSUME  CS:CGROUP

CODE_SEG        SEGMENT  PUBLIC

        PUBLIC  CLEAR_SCREEN
;----------------------------------------------------------------------------;
; CLEARS THE SCREEN IN TEXT MODES                                            ;
;----------------------------------------------------------------------------;
CLEAR_SCREEN    PROC     NEAR
        PUSH    AX                      ;SAVE REGISTERS
        PUSH    BX
        PUSH    CX
        PUSH    DX
        XOR     AL,AL                   ;CLEAR WINDOW
        XOR     CX,CX                   ;UPPER LEFT CORNER AT (0,0)
        MOV     DH,24                   ;BOTTOM LINE AT 24
        MOV     DL,79                   ;RIGHT COLUMN AT 79
        MOV     BH,7                    ;USE WHITE ON BLACK ATTRIBUTE
        MOV     AH,6                    ;CLEAR WINDOW
        INT     10H                     ;CALL VIDEO BIOS
        POP     DX                      ;RESTORE REGISTERS
        POP     CX
        POP     BX
        POP     AX
        RET                             ;RETURN TO CALLING PROCEDURE
CLEAR_SCREEN    ENDP

        PUBLIC  GOTO_XY
;----------------------------------------------------------------------------;
; MOVES CURSOR TO TEXT ROW, COL SCREEN POSITION                              ;
;                                                                            ;
;       DH      ROW (Y)                                                      ;
;       DL      COLUMN (X)                                                   ;
;----------------------------------------------------------------------------;
GOTO_XY         PROC     NEAR
        PUSH    AX                      ;SAVE REGISTERS
        PUSH    BX
        MOV     BH,0                    ;TEXT DISPLAY PAGE 0       
        MOV     AH,2                    ;CALL FOR SET CURSOR POSITION
        INT     10H                     ;CALL VIDEO BIOS
        POP     BX                      ;RESTORE REGISTORS
        POP     AX
        RET                             ;RETURN TO CALLING PROCEDURE
GOTO_XY         ENDP
        
        PUBLIC  SEND_CRLF
;----------------------------------------------------------------------------;
; THIS ROUTINE SENDS A CARRIAGE RETURN LINE FEED PAIR TO THE DISPLAY, USING  ;
; THE DOS ROUTINES SO THAT SCROLLING WILL BE HANDLED CORRECTLY.              ;
;----------------------------------------------------------------------------;
SEND_CRLF       PROC     NEAR
        PUSH    AX                      ;SAVE REGISTERS
        PUSH    DX
        MOV     AH,2                    ;INT 21H FUNCTION 2H
        MOV     DL,CR                   ;PLACE CARRIAGE RETURN CHAR IN DL
        INT     21H                     ;INVOKE INTERRUPT 21H
        MOV     DL,LF                   ;PLACE LINE FEED CHAR IN DL
        INT     21H                     ;INVOKE INTERRUPT 21H
        POP     DX                      ;RESTORE REGISTERS
        POP     AX
        RET                             ;RETURN TO CALLING FUNCTION
SEND_CRLF       ENDP

CODE_SEG        ENDS
        
        END
