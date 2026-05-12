LIST P=16F887
    #include <P16F887.INC>

    __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _LVP_OFF
    __CONFIG _CONFIG2, _WRT_OFF

;====================================================
; VARIABLES
;====================================================

DIG0     EQU 0x21
DIG1     EQU 0x22
DIG2     EQU 0x23
DIG3     EQU 0x24

ACTUAL   EQU 0x25

W_TEMP   EQU 0x26
S_TEMP   EQU 0x27

TECLA    EQU 0x28

REG2     EQU 0x29
REG3     EQU 0x2A
REG4     EQU 0x2B

;====================================================
; RESET / INTERRUPCIONES
;====================================================

    ORG 0x00
    GOTO INICIO

    ORG 0x04
    GOTO ISR

;====================================================
; TABLA 7 SEGMENTOS
;====================================================

    ORG 0x05

TABLA:
    ADDWF PCL,F

    RETLW 0x3F ;0
    RETLW 0x06 ;1
    RETLW 0x5B ;2
    RETLW 0x4F ;3
    RETLW 0x66 ;4
    RETLW 0x6D ;5
    RETLW 0x7D ;6
    RETLW 0x07 ;7
    RETLW 0x7F ;8
    RETLW 0x6F ;9

;====================================================
; INICIO
;====================================================

INICIO:

    BSF STATUS,RP0
    BCF STATUS,RP1

; PORTD salida
    CLRF TRISD
MOVLW B'11110000'
    MOVWF IOCB
; RB0-RB3 salida
; RB4-RB7 entrada
    MOVLW B'11110000'
    MOVWF TRISB

; PORTC salida
    CLRF TRISC

; pullups ON
; prescaler 1:32
    MOVLW B'00000100'
    MOVWF OPTION_REG

; banco 3
    BSF STATUS,RP1
    CLRF ANSELH

; banco 0
    BCF STATUS,RP0
    BCF STATUS,RP1

    CLRF PORTC
    CLRF PORTD

; filas inactivas
    MOVLW B'11110000'
    MOVWF PORTB

; timer0
    MOVLW D'100'
    MOVWF TMR0

; limpiar mismatch
    MOVF PORTB,W

; limpiar flags
    BCF INTCON,RBIF
    BCF INTCON,T0IF

; GIE T0IE RBIE
    MOVLW B'10101000'
    MOVWF INTCON

    CLRF DIG0
    CLRF DIG1
    CLRF DIG2
    CLRF DIG3

    CLRF ACTUAL

;====================================================
; LOOP VACIO
;====================================================

LOOP:
    GOTO LOOP

;====================================================
; ISR
;====================================================

ISR:

;--------------------------------
; GUARDAR CONTEXTO
;--------------------------------

    MOVWF W_TEMP

    SWAPF STATUS,W
    MOVWF S_TEMP

;--------------------------------
; INTERRUPCION RB
;--------------------------------

    BTFSC INTCON,RBIF
    GOTO INTERB

;--------------------------------
; TIMER0
;--------------------------------

    GOTO INTERT

;====================================================
; INTERRUPCION RB
;====================================================

INTERB:

; limpiar mismatch
    MOVF PORTB,W

; limpiar flag
    BCF INTCON,RBIF

; leer teclado
    CALL LEER_TECLADO

; tecla valida?
    MOVF TECLA,W
    SUBLW D'9'

    BTFSS STATUS,C
    GOTO FIN_INTER

; desplazar displays
    MOVF DIG1,W
    MOVWF DIG0

    MOVF DIG2,W
    MOVWF DIG1

    MOVF DIG3,W
    MOVWF DIG2

    MOVF TECLA,W
    MOVWF DIG3

    GOTO FIN_INTER

;====================================================
; LEER TECLADO
;====================================================

LEER_TECLADO:

    MOVLW 0xFF
    MOVWF TECLA

;--------------------------------
; FILA 0
;--------------------------------

    MOVLW B'00001110'
    MOVWF PORTB

    CALL DELAY_SCAN

    BTFSS PORTB,4
    GOTO TECLA_1

    BTFSS PORTB,5
    GOTO TECLA_2

    BTFSS PORTB,6
    GOTO TECLA_3

;--------------------------------
; FILA 1
;--------------------------------

    MOVLW B'00001101'
    MOVWF PORTB

    CALL DELAY_SCAN

    BTFSS PORTB,4
    GOTO TECLA_4

    BTFSS PORTB,5
    GOTO TECLA_5

    BTFSS PORTB,6
    GOTO TECLA_6

;--------------------------------
; FILA 2
;--------------------------------

    MOVLW B'00001011'
    MOVWF PORTB

    CALL DELAY_SCAN

    BTFSS PORTB,4
    GOTO TECLA_7

    BTFSS PORTB,5
    GOTO TECLA_8

    BTFSS PORTB,6
    GOTO TECLA_9

;--------------------------------
; FILA 3
;--------------------------------

    MOVLW B'00000111'
    MOVWF PORTB

    CALL DELAY_SCAN

    BTFSS PORTB,5
    GOTO TECLA_0

; ninguna tecla
CLRF PORTB
    RETURN

;====================================================
; TECLAS
;====================================================

TECLA_0:
    MOVLW D'0'
    GOTO GUARDA_TECLA

TECLA_1:
    MOVLW D'1'
    GOTO GUARDA_TECLA

TECLA_2:
    MOVLW D'2'
    GOTO GUARDA_TECLA

TECLA_3:
    MOVLW D'3'
    GOTO GUARDA_TECLA

TECLA_4:
    MOVLW D'4'
    GOTO GUARDA_TECLA

TECLA_5:
    MOVLW D'5'
    GOTO GUARDA_TECLA

TECLA_6:
    MOVLW D'6'
    GOTO GUARDA_TECLA

TECLA_7:
    MOVLW D'7'
    GOTO GUARDA_TECLA

TECLA_8:
    MOVLW D'8'
    GOTO GUARDA_TECLA

TECLA_9:
    MOVLW D'9'
    GOTO GUARDA_TECLA

;====================================================
; GUARDAR TECLA
;====================================================

GUARDA_TECLA:

    MOVWF TECLA

ESPERA_SOLTAR:

    MOVLW B'00000000'
    MOVWF PORTB

    CALL DELAY_SCAN

    MOVF PORTB,W
    ANDLW B'11110000'
    XORLW B'11110000'

    BTFSS STATUS,Z
    GOTO ESPERA_SOLTAR

    CALL ANTIRREBOTE

    MOVLW B'00001111'
    MOVWF PORTB

    RETURN

;====================================================
; DELAY
;====================================================

DELAY_SCAN:

    MOVLW D'1'
    MOVWF REG2

DS1:
    MOVLW D'100'
    MOVWF REG3

DS2:
    DECFSZ REG3,F
    GOTO DS2

    DECFSZ REG2,F
    GOTO DS1

    RETURN

;====================================================
; ANTIRREBOTE
;====================================================

ANTIRREBOTE:

    MOVLW D'1'
    MOVWF REG2

AR1:
    MOVLW D'100'
    MOVWF REG3

AR2:
    DECFSZ REG3,F
    GOTO AR2

    DECFSZ REG2,F
    GOTO AR1

    RETURN

;====================================================
; TIMER0 DISPLAY
;====================================================

INTERT:

    BCF INTCON,T0IF

    MOVLW D'100'
    MOVWF TMR0

; apagar displays
    CLRF PORTC

;--------------------------------
; DISPLAY 0
;--------------------------------

    MOVF ACTUAL,W
    XORLW D'0'

    BTFSC STATUS,Z
    GOTO DISP0

;--------------------------------
; DISPLAY 1
;--------------------------------

    MOVF ACTUAL,W
    XORLW D'1'

    BTFSC STATUS,Z
    GOTO DISP1

;--------------------------------
; DISPLAY 2
;--------------------------------

    MOVF ACTUAL,W
    XORLW D'2'

    BTFSC STATUS,Z
    GOTO DISP2

;--------------------------------
; DISPLAY 3
;--------------------------------

    GOTO DISP3

;====================================================

DISP0:

    MOVF DIG0,W
    CALL TABLA
    MOVWF PORTD

    BSF PORTC,0

    GOTO AVANZAR

;====================================================

DISP1:

    MOVF DIG1,W
    CALL TABLA
    MOVWF PORTD

    BSF PORTC,1

    GOTO AVANZAR

;====================================================

DISP2:

    MOVF DIG2,W
    CALL TABLA
    MOVWF PORTD

    BSF PORTC,2

    GOTO AVANZAR

;====================================================

DISP3:

    MOVF DIG3,W
    CALL TABLA
    MOVWF PORTD

    BSF PORTC,3

;====================================================

AVANZAR:

    INCF ACTUAL,F

    MOVF ACTUAL,W
    SUBLW D'4'

    BTFSC STATUS,Z
    CLRF ACTUAL

    GOTO FIN_INTER

;====================================================
; FIN ISR
;====================================================

FIN_INTER:

    SWAPF S_TEMP,W
    MOVWF STATUS

    SWAPF W_TEMP,F
    SWAPF W_TEMP,W

    RETFIE

;====================================================

END