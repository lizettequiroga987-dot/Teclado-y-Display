LIST P=16F887
    #include <P16F887.INC>
    __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _LVP_OFF
    __CONFIG _CONFIG2, _WRT_OFF
;-----------------------------
; VARIABLES
DIG0     EQU 0x21
DIG1     EQU 0x22
DIG2     EQU 0x23
DIG3     EQU 0x24
ACTUAL   EQU 0x25
W_TEMP   EQU 0x26
S_TEMP   EQU 0x27
;-----------------------------
; Calculo Timer0 para 5ms @ 4MHz:
; Fosc/4 = 1MHz -> 1 tick = 1us
; Prescaler 1:32 -> 1 tick = 32us
; 5ms / 32us = 156 cuentas
; Precarga = 256 - 156 = 100
; 4 displays x 5ms = 20ms = 50Hz
;-----------------------------
    ORG 0x00
    GOTO INICIO

    ORG 0x04
    GOTO ISR

    ORG 0x05
TABLA:
    ADDWF PCL, F
    RETLW 0x3F          ; 0
    RETLW 0x06          ; 1
    RETLW 0x5B          ; 2
    RETLW 0x4F          ; 3
    RETLW 0x66          ; 4
    RETLW 0x6D          ; 5
    RETLW 0x7D          ; 6
    RETLW 0x07          ; 7
    RETLW 0x7F          ; 8
    RETLW 0x6F          ; 9

;-----------------------------
INICIO:
    BSF STATUS, RP0
    BCF STATUS, RP1
    CLRF TRISD
    CLRF TRISB
    CLRF ANSEL

    ; Timer0: Fosc/4, prescaler 1:32
    ; PS2:PS0 = 100
    MOVLW B'00000100'
    MOVWF OPTION_REG

    BSF STATUS, RP1
    CLRF ANSELH

    BCF STATUS, RP0
    BCF STATUS, RP1
    CLRF PORTD
    CLRF PORTB
    CLRF ACTUAL

    ; Precarga = 256 - 156 = 100 -> 5ms
    MOVLW D'100'
    MOVWF TMR0

    MOVLW B'10100000'   ; GIE=1, T0IE=1
    MOVWF INTCON

    ; --- Mostrar 2025 ---
    MOVLW D'2'
    MOVWF DIG0
    MOVLW D'0'
    MOVWF DIG1
    MOVLW D'2'
    MOVWF DIG2
    MOVLW D'5'
    MOVWF DIG3

;-----------------------------
LOOP:
    GOTO LOOP

;-----------------------------
ISR:
    MOVWF W_TEMP
    SWAPF STATUS, W
    MOVWF S_TEMP  ;se guarda status y w

    BTFSS INTCON, T0IF ;se verifica que proviene de timer0
    GOTO  FIN_ISR ;sale si no

    ; recargar TMR0 para proximos 5ms
    MOVLW D'100'
    MOVWF TMR0
    BCF   INTCON, T0IF

    ; PASO 1: apagar transistores
    CLRF  PORTB

    ; PASO 2: cargar segmentos
    MOVF  ACTUAL, W
    XORLW D'0'
    BTFSC STATUS, Z
    GOTO  DISP0

    MOVF  ACTUAL, W
    XORLW D'1'
    BTFSC STATUS, Z
    GOTO  DISP1

    MOVF  ACTUAL, W
    XORLW D'2'
    BTFSC STATUS, Z
    GOTO  DISP2

    GOTO  DISP3

DISP0:
    MOVF  DIG0, W
    CALL  TABLA
    MOVWF PORTD
    BSF   PORTB, 0      ; PASO 3: encender transistor
    GOTO  AVANZAR

DISP1:
    MOVF  DIG1, W
    CALL  TABLA
    MOVWF PORTD
    BSF   PORTB, 1
    GOTO  AVANZAR

DISP2:
    MOVF  DIG2, W
    CALL  TABLA
    MOVWF PORTD
    BSF   PORTB, 2
    GOTO  AVANZAR

DISP3:
    MOVF  DIG3, W
    CALL  TABLA
    MOVWF PORTD
    BSF   PORTB, 3

AVANZAR:
    INCF  ACTUAL, F
    MOVF  ACTUAL, W
    SUBLW D'4'
    BTFSC STATUS, Z
    CLRF  ACTUAL

FIN_ISR:
    SWAPF S_TEMP, W
    MOVWF STATUS
    SWAPF W_TEMP, F
    SWAPF W_TEMP, W
    RETFIE
;-----------------------------
    END