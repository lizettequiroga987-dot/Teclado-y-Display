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
; Calculo Timer0 para 5ms = 4MHz:
; Fosc/4 = 1MHz  1 ciclo = 1us
; Prescaler 1:32  1 ciclo  = 32us
; 5ms / 32us = 156 cuentas
; Precarga = 256 - 156 = 100 aca arranca el timer0
; 4 displays x 5ms = 20ms = 50Hz
;-----------------------------
    ORG 0x00
    GOTO INICIO
    ORG 0x04
    GOTO INTER
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
    RETLW 0xF3          ; A
    RETLW 0xFF          ; B
    RETLW 0x39          ; C
    RETLW 0xBF          ; D
    RETLW 0x76          ;#
    RETLW 0x80          ;Punto
;-----------------------------
INICIO:
    BSF STATUS, RP0
    BCF STATUS, RP1 ;al banco 1
    CLRF TRISD ; salidas todas del puerto d 
    MOVLW b'11110000'
    MOVWF TRISB ; rb0 - rb3 como salidas, las demas como entradas
    ;CLRF ANSEL ;
    ;prescalamos a 1:32
    ; PS2 PS1 PS0 = 100
    MOVLW B'00000100'
    MOVWF OPTION_REG
    MOVLW B'11110000'
    MOVWF WPUB
    BSF STATUS, RP1 ; 11 vamos al banco 3
    CLRF ANSELH
    BCF STATUS, RP0 
    BCF STATUS, RP1 ; al banco 0
    CLRF PORTD
    CLRF PORTC
    CLRF PORTB; ponemos en 0 los puertos b,c y d
    CLRF ACTUAL ; empezamos por el display 0 
    MOVLW D'100'  ; Precarga = 256 - 156 = 100 osea  5ms
    MOVWF TMR0 ;tmr0 vale 100
    MOVLW B'10101000'   ; GIE=1, T0IE=1,RBIE=1
    MOVWF INTCON
    ;-----
    CLRF DIG0
    CLRF DIG1
    CLRF DIG2
    CLRF DIG3
;-----------------------------
LOOP:
    BTFSS INTCON, 0
    GOTO LOOP ; entra en el bucle hasta los 5ms de la inter
    GOTO INTER
    ;-----------------------------
    
INTER:
    MOVWF W_TEMP ;aca guardamos los temporales
    SWAPF STATUS, W    ;el orofe dijo que usabamos swapf para que no se modifiquen las banderas
    MOVWF S_TEMP
   ; BTFSS INTCON, 2 ;se fija si el t0if es 1 (sig que hubo overflow)
   ; GOTO  FIN_INTER
    ; recargar TMR0 para proximos 5ms
    MOVLW D MOVWF W_TEMP
    SWAPF STATUS, W    ;el orofe dijo que usabamos swapf para que no se modifiquen las banderas
    MOVWF S_TEMP
   ; BTFSS INTCO'100'
    MOVWF TMR0
    BCF   INTCON, 2; ponemos en 0 
    ; ponemoss en 0 los transistores
    CLRF  PORTB
    ;elije los segmentos
    MOVF  ACTUAL, W
    XORLW 0x00 ; xor si valen lo mismo sale 0, sino 1
    BTFSC STATUS, Z ; se fija si z es 0
    GOTO  DISP0
    MOVF  ACTUAL, W
    XORLW 0x01
    BTFSC STATUS, Z
    GOTO  DISP1
    MOVF  ACTUAL, W
    XORLW 0x02
    BTFSC STATUS, Z
    GOTO  DISP2
    GOTO  DISP3
DISP0:
    MOVF  DIG0, W   ;DIG0 valia 2
    CALL  TABLA     ; vamos a la tabla para buscar el 2 hexa
    MOVWF PORTD     ; mandamos el 2 por los puertos d
    BSF   PORTC, 0  ; le damos el 1 en el PB0
    GOTO  AVANZAR
DISP1:
    MOVF  DIG1, W
    CALL  TABLA
    MOVWF PORTD
    BSF   PORTC, 1
    GOTO  AVANZAR
DISP2:
    MOVF  DIG2, W
    CALL  TABLA
    MOVWF PORTD
    BSF   PORTC, 2
    GOTO  AVANZAR
DISP3:
    MOVF  DIG3, W
    CALL  TABLA
    MOVWF PORTD
    BSF   PORTC, 3
AVANZAR:
    INCF  ACTUAL, F
    MOVF  ACTUAL, W
    SUBLW D'4'  
    BTFSC STATUS, Z  ;si Actual llega a ser 4 sig que nos pasamos y volvemos al display0
    CLRF  ACTUAL
FIN_INTER: ; volvemos a todo como estaba
    SWAPF S_TEMP, W
    MOVWF STATUS
    SWAPF W_TEMP, F
    SWAPF W_TEMP, W
    RETFIE ; volvemos al loop , se libera el stack aca y activa el gie devuelta
;-----------------------------
COLUMNAS:
    ;columna1
    MOVLW B'00000111'
    MOVWF PORTB,1
    BTFSS PORTB,4
    delay
    ;boton 
    BTFSS PORTB,5
    ;boton 
    BTFSS PORTB,6
    ;boton 
    BTFSS PORTB,7
    ;boton 
    
    ;columna2
    MOVLW B'00001011'
    MOVWF PORTB,1
    BTFSS PORTB,4
    ;boton 
    BTFSS PORTB,5
    ;boton 
    BTFSS PORTB,6
    ;boton 
    BTFSS PORTB,7
    ;boton 
    ;columna3
    MOVLW B'00001101'
    MOVWF PORTB,1
    BTFSS PORTB,4
    ;boton 
    BTFSS PORTB,5
    ;boton 
    BTFSS PORTB,6
    ;boton 
    BTFSS PORTB,7
    ;boton 
    ;columna4
    MOVLW B'00001110'
    MOVWF PORTB,1
    BTFSS PORTB,4
    ;boton 
    BTFSS PORTB,5
    ;boton 
    BTFSS PORTB,6
    ;boton 
    BTFSS PORTB,7
    ;boton 
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    END


