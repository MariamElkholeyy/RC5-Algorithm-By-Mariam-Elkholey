; RC5 Algortithm
; Constants
.EQU R = 8        ; Number of rounds
.EQU T = 18       ; Size of S array (words)
.EQU W = 16       ; Word size (bits)
.EQU U = 2        ; Word size (bytes)
.EQU B = 12       ; Key length (bytes)
.EQU C = 6        ; Key words
.EQU N = 54       ; Key expansion iterations
.EQU PL = 0xe1    ; P low byte (0xb7e1)
.EQU PH = 0xb7    ; P high byte
.EQU QL = 0x37    ; Q low byte (0x9e37)
.EQU QH = 0x9e    ; Q high byte
.EQU S_PLACE = 0x0100 ; S array start
.EQU L_PLACE = 0x0124 ; L array start

; Macros
.MACRO SUB_WORD
    SUB @0, @2
    SBC @1, @3
.ENDMACRO

.MACRO COPY_WORD
    MOV @0, @2
    MOV @1, @3
.ENDMACRO

.MACRO XOR_WORD
    EOR @0, @2
    EOR @1, @3
.ENDMACRO

.MACRO ADD_WORD
    ADD @0, @2
    ADC @1, @3
.ENDMACRO

.MACRO PLAINTEXT_INPUT
    LDI AH, @0    ; A high byte
    LDI AL, @1    ; A low byte
    LDI BH, @2    ; B high byte
    LDI BL, @3    ; B low byte
.ENDMACRO


.MACRO ROTL_WORD
    TST @2
    BREQ ZEROL
    MOV R25, @2
ROTL:
    ROL @0              ; Rotate low byte first
    BST @1, 7           ; Store MSB of high byte
    ROL @1              ; Rotate high byte
    BLD @0, 0           ; Move MSB to LSB of low byte
    DEC R25
    BRNE ROTL
ZEROL:
    NOP
.ENDMACRO


.MACRO ROTR_WORD
    TST @2
    BREQ ZEROR
    MOV R25, @2
ROTR:
    ROR @1              ; Rotate high byte first
    BST @0, 0           ; Store LSB of low byte
    ROR @0              ; Rotate low byte
    BLD @1, 7           ; Move LSB to MSB of high byte
    DEC R25
    BRNE ROTR
ZEROR:
    NOP
.ENDMACRO
; ********* Intializing L-Array *********;
.MACRO SECRET_KEY
    LDI ZL, low(L_PLACE)
    LDI ZH, high(L_PLACE)
    LDI R20, @0
    ST Z+, R20
    LDI R20, @1                     
    ST Z+, R20
    LDI R20, @2
    ST Z+, R20
    LDI R20, @3
    ST Z+, R20
    LDI R20, @4
    ST Z+, R20
    LDI R20, @5
    ST Z+, R20
    LDI R20, @6                             
    ST Z+, R20
    LDI R20, @7
    ST Z+, R20
    LDI R20, @8
    ST Z+, R20
    LDI R20, @9
    ST Z+, R20
    LDI R20, @10
    ST Z+, R20
    LDI R20, @11
    ST Z+, R20
.ENDMACRO

.MACRO RC5_SETUP

    ; Initialize S array
    LDI ZL, low(S_PLACE)
    LDI ZH, high(S_PLACE)
    LDI R16, PL
    LDI R17, PH
    STS S_PLACE, R16
    STS S_PLACE+1, R17
    LDI R18, T-1
    LDI R16, QL
    LDI R17, QH
s_init_loop:
    LD R20, Z+
    LD R21, Z+
    ADD_WORD R20, R21, R16, R17         
    ST Z, R20
    STD Z+1, R21
    DEC R18
    BRNE s_init_loop

    ; ********* Mix S and L *********;
    CLR R0
    CLR R1
    CLR R2
    CLR R3
    LDI ZL, low(S_PLACE)
    LDI ZH, high(S_PLACE)
    LDI YL, low(L_PLACE)
    LDI YH, high(L_PLACE)
    LDI R20, N
mix_loop:                               
    ADD_WORD R0, R1, R2, R3
    LD R22, Z+
    LD R23, Z
    ADD_WORD R0, R1, R22, R23
    LDI R24, 3
    ROTL_WORD R0, R1, R24
    ST Z, R1
    ST -Z, R0
    RCALL i_reset
    ADD_WORD R2, R3, R0, R1
    LD R22, Y+
    LD R23, Y
    ADD_WORD R2, R3, R22, R23
    MOV R24, R2
    ANDI R24, 0x0F
    ROTL_WORD R2, R3, R24
    ST Y, R3
    ST -Y, R2
    RCALL j_reset
    DEC R20
    BRNE mix_loop
.ENDMACRO

.MACRO RC5_ENCRYPT
    ; Initial A/B addition
    LDI XL, low(S_PLACE)
    LDI XH, high(S_PLACE)
    LD R20, X+                  ; S[0] low
    LD R21, X+                  ; S[0] high
    ADD_WORD AL,AH, R20,R21     ; A += S[0]

    LD R20, X+                  ; S[1] low
    LD R21, X+                  ; S[1] high
    ADD_WORD BL,BH, R20,R21     ; B += S[1]
    

    LDI R20, R                  ; 8 rounds
encrypt_loop:
        ;Compute A
        LDI R22, 0x0F
		AND R22, BL

		LD R23, X+
		LD R24, X+
		XOR_WORD AH, AL, BH, BL
		ROTL_WORD AH, AL, R22  
		ADD_WORD AH, AL, R24, R23

		;Compute B
		LDI R22, 0x0F
		AND R22, AL

		LD R23, X+
		LD R24, X+
		XOR_WORD BH, BL, AH, AL
		ROTL_WORD BH, BL, R22  
		ADD_WORD BH, BL, R24, R23

		;Loop controling
		DEC R20
        BRNE encrypt_loop
.ENDMACRO

.MACRO RC5_DECRYPT
    LDI XL, low(S_PLACE + 36) ; Start at S[17] high byte
    LDI XH, high(S_PLACE + 36)
    LDI R20, R                ; 8 rounds

decrypt_loop:
    ;Compute B {
		LDI R22, 0x0F
		AND R22, AL

		LD R23, -X             
		LD R24, -X
		SUB_WORD BH, BL, R23, R24
		ROTR_WORD BH, BL, R22
		XOR_WORD BH, BL, AH, AL
		;}

		;Compute A {
		LDI R22, 0x0F
		AND R22, BL

		LD R23, -X
		LD R24, -X
		SUB_WORD AH, AL, R23, R24
		ROTR_WORD AH, AL, R22
		XOR_WORD AH, AL, BH, BL
		;}

    DEC R20
    BRNE decrypt_loop

    ; Final subtraction of S[0] and S[1]
    LDI XL, low(S_PLACE + 2) ; S[1] high
    LDI XH, high(S_PLACE + 2)
    LD R24, X+         ; S[1] high
    LD R25, X        ; S[1] low
    SUB_WORD BL, BH, R24, R25

    LDI XL, low(S_PLACE + 1) ; S[0] high
    LDI XH, high(S_PLACE + 1)
    LD R25, X         ; S[0] high
    LD R24, -X        ; S[0] low
    SUB_WORD AL, AH, R24, R25
.ENDMACRO

main:
    ; Set stack pointer
    LDI R20, high(RAMEND)
    OUT SPH, R20
    LDI R20, low(RAMEND)
    OUT SPL, R20

    ; Input secret key
    SECRET_KEY 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C

    ; Perform key expansion
    RC5_SETUP

    ; Define registers for plaintext
    .DEF AH = R17
    .DEF AL = R16
    .DEF BH = R19
    .DEF BL = R18

    ; Test case 1: A=0x1234, B=0x5678
    PLAINTEXT_INPUT 0x12, 0x34, 0x56, 0x78
    RC5_ENCRYPT
    RC5_DECRYPT

    ; Test case 2: A=0x2233, B=0x6688
    PLAINTEXT_INPUT 0x22, 0x33, 0x66, 0x88
    RC5_ENCRYPT
    RC5_DECRYPT
    PLAINTEXT_INPUT 0x22, 0x33, 0x66, 0x88

    ; Test case 3:    M    E      R    O   
    PLAINTEXT_INPUT 0x4D, 0x45, 0x52, 0x4F
    RC5_ENCRYPT
    RC5_DECRYPT

    ;Uselless Just to verify that the decryption works
    PLAINTEXT_INPUT 0x22, 0x33, 0x66, 0x88
done:
    RJMP done

; Subroutine: Reset Z pointer for S array
i_reset:
    INC ZL
    INC ZL
    CPI ZL, low(S_PLACE + 36)
    BRNE i_reset_done
    LDI ZL, low(S_PLACE)
    LDI ZH, high(S_PLACE)
i_reset_done:
    RET

; Subroutine: Reset Y pointer for L array
j_reset:
    INC YL
    INC YL
    CPI YL, low(L_PLACE + 12)
    BRNE j_reset_done
    LDI YL, low(L_PLACE)
    LDI YH, high(L_PLACE)
j_reset_done:
    RET