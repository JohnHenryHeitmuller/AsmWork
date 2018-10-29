CGROUP         GROUP     CODE_SEG       ;GROUP TWO SEGMENTS TOGETHER 
        ASSUME  CS:CGROUP 
 
CODE_SEG        SEGMENT  PUBLIC 
         
        PUBLIC  WRITE_PATTERN 
;----------------------------------------------------------------------------; 
; WRITES A LINE TO THE SCREEN BASED ON DATA IN THE FORM                      ; 
;                                                                            ; 
;       DB      (CHARACTER, NUMBER OF TIMES TO WRITE CHARACTER), 0           ; 
;               WHERE (X) MEANS THAT X CAN BE REPEATED ANY NUMBER OF TIMES   ; 
;       DS:DX   ADDRESS OF THE ABOVE DATA STATEMENT                          ; 
;                                                                            ; 
; USES: WRITE_CHAR_N_TIMES                                                   ; 
;----------------------------------------------------------------------------; 
WRITE_PATTERN   PROC     NEAR 
        PUSH    AX                      ;SAVE REGISTERS 
        PUSH    CX 
        PUSH    DX 
        PUSH    SI 
        PUSHF                           ;SAVE THE DIRECTION FLAG 
        CLD                             ;SET DIRECTION FLAG FOR INCREMENT 
        MOV     SI,DX                   ;MOVE OFFSET IN TO SI REG FOR LODSB 
PATTERN_LOOP: 
        LODSB                           ;PUT CHARACTER DATA INTO AL 
        OR      AL,AL                   ;IS IT THE END OF DATA ( 0H )? 
        JE      END_PATTERN             ;YES, RETURN 
        MOV     DL,AL                   ;NO, SET UP TO WRITE CHARACTER N TIMES 
        LODSB                           ;PUT REPEAT COUNT INTO AL 
        MOV     CL,AL                   ;AND PUT IN CX FOR WRITE_CHAR_N_TIMES 
        XOR     CH,CH                   ;ZERO OUT UPPER BYTE OF CX 
        CALL    WRITE_CHAR_N_TIMES 
        JMP     PATTERN_LOOP 
END_PATTERN: 
        POPF                            ;RESTORE DIRECTION FLAG 
        POP     SI                      ;RESTORE REGISTERS 
        POP     DX 
        POP     CX 
        POP     AX 
        RET                             ;RETURN TO CALLING ROUTINE 
WRITE_PATTERN   ENDP 
 
        PUBLIC  WRITE_CHAR_N_TIMES 
;----------------------------------------------------------------------------; 
; WRITE MORE THAN ONE COPY OF A CHARACTER                                    ; 
;                                                                            ; 
;       DL      CHARACTER CODE                                               ; 
;       CX      NUMBER OF TIMES TO WRITE THE CHARACTER                       ; 
;                                                                            ; 
; USES:  WRITE_CHAR                                                          ; 
;----------------------------------------------------------------------------; 
WRITE_CHAR_N_TIMES  PROC  NEAR 
        PUSH    CX                      ;SAVE REGISTER 
N_TIMES: 
        CALL    WRITE_CHAR               
        LOOP    N_TIMES                 ;LOOP TILL CX EQUAL ZERO 
        POP     CX                      ;RESTORE REGISTER 
        RET                             ;RETURN TO CALLING ROUTINE 
WRITE_CHAR_N_TIMES  ENDP 
 
        PUBLIC  WRITE_DECIMAL 
;----------------------------------------------------------------------------; 
; THIS PROCEDURE WRITES A 16-BIT, UNSIGNED NUMBER IN DECIMAL NOTATION.       ; 
;                                                                            ; 
;       DX      N : 16-BIT, UNSIGNED NUMBER.                                 ; 
;                                                                            ; 
; USES:         WRITE_HEX_DIGIT                                              ; 
;----------------------------------------------------------------------------; 
WRITE_DECIMAL   PROC     NEAR 
        PUSH    AX                      ;SAVE REGISTERS USED HERE 
        PUSH    CX 
        PUSH    DX 
        PUSH    SI 
        MOV     AX,DX                   ;MAKE COPY OF DX IN AX 
        MOV     SI,10                   ;WILL DIVIDE BY 10 USEING SI 
        XOR     CX,CX                   ;COUNT DIGITS PLACED ON STACK 
NON_ZERO: 
        XOR     DX,DX                   ;SET UPPER WORD OF N TO ZERO 
        DIV     SI                      ;CALCULATE N/10 AND (N MOD 10) 
        PUSH    DX                      ;PUSH ONE DIGIT ONTO THE STACK 
        INC     CX                      ;ONE MORE DIGIT ADDED 
        OR      AX,AX                   ;N = ZERO YET? 
        JNE     NON_ZERO                ;NO, CONTINUE 
WRITE_DIGIT_LOOP: 
        POP     DX                      ;GET DIGITS OFF STACK IN REVERSE ORDER 
        CALL    WRITE_HEX_DIGIT 
        LOOP    WRITE_DIGIT_LOOP 
END_DECIMAL: 
        POP     SI                      ;RESTORE ALTERED REGISTERS 
        POP     DX 
        POP     CX 
        POP     AX 
        RET                             ;RETURN 
WRITE_DECIMAL   ENDP 
 
        PUBLIC WRITE_HEX 
;----------------------------------------------------------------------------; 
; THIS PROCEDURE CONVERTS THE BYTE IN THE DL REGISTER TO HEX AND WRITES      ; 
; THE TWO HEX DIGITS AT THE CURRENT CURSOR POSITION.                         ; 
;                                                                            ; 
;       DL      BYTES TO BE CONVERTED TO HEX                                 ; 
;                                                                            ; 
; USES:         WRITE_HEX_DIGIT                                              ; 
;----------------------------------------------------------------------------; 
WRITE_HEX       PROC     NEAR           ;ENTRY POINT 
        PUSH    CX                      ;SAVE REGISTERS 
        PUSH    DX                       
        MOV     DH,DL                   ;MAKE A COPY OF BYTE 
        MOV     CX,4                    ;GET THE UPPER 4 BITS OF DL 
        SHR     DL,CL 
        CALL    WRITE_HEX_DIGIT         ;DISPLAY FIRST HEX DIGIT 
        MOV     DL,DH                   ;GET LPWER 4 OF DL 
        AND     DL,0FH                  ;REMOVE UPPER 4 BITS 
        CALL    WRITE_HEX_DIGIT         ;DISPLAY SECOND HEX DIGIT 
        POP     DX                      ;RESTORE REGISTERS 
        POP     CX 
        RET 
WRITE_HEX       ENDP 
 
        PUBLIC  WRITE_HEX_DIGIT 
;----------------------------------------------------------------------------; 
; THIS PROCEDURE CONVERTS THE LOWER 4 BITS OF DL TO A HEX DIGIT AND          ; 
; WRITES IT TO THE SCREEN                                                    ; 
;                                                                            ; 
;       DL      LOWER 4 BITS CONTAIN NUMBER TO BE PRINTED IN HEX             ; 
;                                                                            ; 
; USES:         WRITE_CHAR                                                   ; 
;----------------------------------------------------------------------------; 
WRITE_HEX_DIGIT PROC     NEAR 
        PUSH    DX                      ;SAVE REGISTER 
        CMP     DL,10                   ;IS THIS NIBBLE < 10 ? 
        JAE     HEX_LETTER              ;NO, CONVERT TO A LETTER A - F 
        ADD     DL,"0"                  ;YES, CONVERT TO A DIGIT  
        JMP     SHORT WRITE_DIGIT       ;NOW WRITE THIS CHARACTER 
 
HEX_LETTER: 
        ADD     DL,"A"-10               ;CONVERT TO HEX LETTER 
 
WRITE_DIGIT: 
        CALL    WRITE_CHAR              ;DISPLAY THE LETTER ON THE SCREEN 
        POP     DX                      ;RESTORE OLD VALUE OF AX 
        RET                             ;RETURN 
WRITE_HEX_DIGIT ENDP 
 
        PUBLIC  WRITE_CHAR 
;----------------------------------------------------------------------------; 
; THIS PROCEDURE PRINTS A CHARACTER ON THE SCREEN USING A DOS FUNCTION CALL. ; 
; WRITE_CHAR REPLACES THE CHARACTERS 0H THROUGH 1FH WITH A PERIOD '.'.       ; 
;                                                                            ; 
;       DL      BYTE TO PRINT ON SCREEN                                      ; 
;----------------------------------------------------------------------------; 
WRITE_CHAR      PROC     NEAR 
        PUSH    AX                      ;SAVE REGISTER 
        PUSH    DX 
        CMP     DL,32                   ;IS CHAR BEFORE A SPACE? 
        JAE     IS_PRINTABLE            ;NO, THEN PRINT AS IS 
        MOV     DL,'.'                  ;YES, REPLACE WITH PERIOD 
IS_PRINTABLE: 
        MOV     AH,2                    ;CALL FOR CHARACTER OUTPUT 
        INT     21H                     ;WRITE CHAR IN DL REGISTER TO SCREEN 
        POP     DX                      ;RESTORE REGISTER 
        POP     AX 
        RET                             ;RETURN 
WRITE_CHAR      ENDP 
 
CODE_SEG        ENDS 
 
        END