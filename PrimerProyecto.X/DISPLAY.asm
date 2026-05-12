 MAIN_PROG CODE  
LIST P=16F887
#include "p16f887.inc"
CONTADOR EQU 0x21
REG2 EQU 0x22
REG3 EQU 0x23
REG4 EQU 0x24
ESTADO EQU 0x25
ORG 0X00
GOTO _INICIO

ORG 0X05
_INICIO:
    ; Banco 1
    BCF STATUS, RP1
    BSF STATUS, RP0; seleccion del banco de registros

    CLRF TRISD   ; configracion de puertos d como salida(display)
    BSF TRISB,0 ; pone el el puerto BR0 como entrada (pulsador)
 

    ; Banco 0 (CORREGIDO)
    BCF STATUS, RP0
    BCF STATUS, RP1;Vuelve al banco 0 porque ahi estan los registros de este programa(21h en adelante)
    CLRF ESTADO
    RUTINA_PRINCIPAL:  
    MOVLW 0;
    MOVWF CONTADOR ;En la posicion marcada del contador se alamecena el 0
    
    BUCLE
    CALL PULSADOR   ;
    MOVF CONTADOR,W;
    CALL TABLA 
    MOVWF PORTD; mostrar en el display
    CALL DELAY ;
    MOVF ESTADO,W;frenar si el contador esta detenido
    BTFSS STATUS,Z
    GOTO BUCLE 
    INCF CONTADOR,1 ;Incrementa en un el contador y lo almacena en el mismo lugar
    MOVF CONTADOR, W; trae el valor incrementado a W
    SUBLW 0X0A; RESTA 10-W
    BTFSC STATUS,Z;chequeo de que el vaor sea = o no
    GOTO RUTINA_PRINCIPAL;cuando Z=1
    GOTO BUCLE;mientras Z=0            ; SI EL CONTADOR ES 0, ME LLEVA AL INICIO PARA REESTABLECER, SINO EMPIEZA DEVUELTA EL BUCLE
    
    TABLA:
    ADDWF PCL,F;
    RETLW 0x3F ;0
    RETLW 0X03 ;1
    RETLW 0X57 ;2
    RETLW 0X4F ;3
    RETLW 0X66 ;4
    RETLW 0X67 ;5
    RETLW 0X7D ;6
    RETLW 0X07 ;7
    RETLW 0X7F ;8
    RETLW 0X6F ;9

    DELAY:
    MOVLW   D'7'
    MOVWF   REG4

BUCLE1
    MOVLW   D'200'
    MOVWF   REG3

BUCLE2
    MOVLW   D'250'
    MOVWF   REG2

BUCLE3
    DECFSZ  REG2,1
    GOTO    BUCLE3

    DECFSZ  REG3,1
    GOTO    BUCLE2

    DECFSZ  REG4,1
    GOTO    BUCLE1

    RETURN

PULSADOR:
    BTFSC   PORTB,0
    GOTO    FIN_PULSADOR

ESPERA_SUELTE
    BTFSC   PORTB,0
    GOTO    ESPERA_SUELTE

    MOVF    ESTADO,W
    XORLW   0x01
    MOVWF   ESTADO

    CALL    DELAY   ; antirrebote

FIN_PULSADOR
    RETURN

END