; TODO INSERT CONFIG CODE HERE USING CONFIG BITS GENERATOR
#include <p16f690.inc>
    __config (_HS_OSC & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_OFF & _IESO_OFF & _FCMEN_ON)
    
RES_VECT  CODE    0x0000            ; processor reset vector
    CLRF    INTCON		    ; disable interrupts
    GOTO    START                   ; go to beginning of program

Int_Handler CODE    0x0004
    RETFIE

PATTERN equ B'00000001'
SIZE_COL    equ .32
SIZE_B	    equ .8
MAX_COLORS  equ	0x0F		    ;0-15 = 16 colors MASQUING LOGIC
ARRAY_START	equ 0x20
;SECTION JUST USED WHEN PRINTING
;MAY BE REUSED ONLY FOR TEMPORAL USE
COLUMN_INDEX	equ 0x60
CURRENT_COLUMN	equ 0x61
CURRENT_COLUMN_INDEX	equ 0x62
TABLE_TEMPORAL	equ 0x63
CURRENT_COLOR	equ 0x64
INDEXED_COLOR	equ 0x65
TEMP_COLOR	equ 0x66
DISPLAY_COLOR	equ 0x67
CURRENT_DISPLAY_INDEX	equ 0x68
;REUSE FOR REVERSE
REVERSE_TEMP	equ 0x60
REVERSE_RET	equ 0x61
REVERSE_COUNT	equ 0x62
	
;COMMONS BECAUSE BETWEEN 0x70-0x7F
LAST_STATE  equ 0x7F
LAST_POS    equ 0x7E
PIECE_SIZE  equ	0x7D
PIECE_3	    equ	0x7C
PIECE_2	    equ	0x7B
PIECE_1	    equ	0x7A
PIECE_0	    equ	0x79
PIECE_TYPE  equ	0x78
PIECE_ROT   equ	0x77
  
  
;MAP OF DISPLAY MEMORY, MUST NOT REUSE
    cblock 0x20 ; 0x20 - 0x5F = 64 BYTES 
	B0,C0,B1,C1,B2,C2,B3,C3,B4,C4,B5,C5,B6,C6,B7,C7,
	B8,C8,B9,C9,B10,C10,B11,C11,B12,C12,B13,C13,B14,C14,B15,C15,
	B16,C16,B17,C17,B18,C18,B19,C19,B20,C20,B21,C21,B22,C22,B23,C23,
	B24,C24,B25,C25,B26,C26,B27,C27,B28,C28,B29,C29,B30,C30,B31,C31
    endc

;Paleta clonada de https://jonasjacek.github.io/colors/
COLORS_GREEN dt	0x00,0x20,0x00,0x00,0x20,0x20,0x00,0x20,0x10,0x00,0x00,0x10,0x10,0x00,0x20,0x00
COLORS_RED dt	0x00,0x00,0x20,0x00,0x20,0x00,0x20,0x20,0x00,0x10,0x00,0x10,0x00,0x10,0x10,0x10
COLORS_BLUE dt	0x00,0x00,0x00,0x20,0x00,0x20,0x20,0x20,0x00,0x00,0x10,0x00,0x10,0x10,0x00,0x20
COLOR_BLACK equ 0x00 ; POSITION OF BLACK
 
;LISTA DE BLOQUES
;NORMALIZADOS A TODOS 4 rotaciones
BLOCK_LINE_SIZE	    dt	0x01,0x04,0x01,0x04
BLOCK_LINE_ROT	    dt	0x0F, 0x01,0x01,0x01,0x01, 0x0F, 0x01,0x01,0x01,0x01
BLOCK_SQUARE_SIZE   dt	0x02, 0x02, 0x02, 0x02
BLOCK_SQUARE_ROT    dt	0x03,0x03, 0x03,0x03, 0x03,0x03, 0x03,0x03
BLOCK_L_SIZE	    dt	0x03,0x02,0x03,0x02
BLOCK_L_ROT	    dt	0x01,0x01,0x03, 0x04,0x07, 0x03,0x02,0x02, 0x07,0x01
BLOCK_IL_SIZE	    dt	0x03,0x02,0x03,0x02
BLOCK_IL_ROT	    dt	0x02,0x02,0x03, 0x07,0x04, 0x03,0x01,0x01, 0x01,0x07
BLOCK_T_SIZE	    dt	0x02,0x03,0x02,0x03
BLOCK_T_ROT	    dt	0x02,0x07, 0x02,0x03,0x02, 0x07,0x02, 0x01,0x03,0x01
BLOCK_Z_SIZE	    dt	0x02,0x03, 0x02,0x03
BLOCK_Z_ROT	    dt	0x03,0x06, 0x02,0x03,0x01, 0x03,0x06, 0x02,0x03,0x01
BLOCK_IZ_SIZE	    dt	0x02,0x03, 0x02,0x03
BLOCK_IZ_ROT	    dt	0x06,0x03, 0x01,0x03,0x02, 0x06,0x03, 0x01,0x03,0x02
	    
BLOCK_SIZES	dt
BLOCK_ROTATIONS	dt
 
REVERSE_BYTE
    MOVWF   REVERSE_TEMP
    MOVLW   0x08
    MOVWF   REVERSE_COUNT
    REVERSE_LOOP
	RRF	    REVERSE_TEMP,F
	RLF	    REVERSE_RET,F
	DECFSZ  REVERSE_COUNT,F
	GOTO REVERSE_LOOP
    MOVF    REVERSE_RET,W
    RETURN
    
    
GET_GREEN
    MOVWF   TABLE_TEMPORAL	;PUT INDEX OUT OF WAY
    MOVLW   HIGH COLORS_GREEN	;GET HIGH PART OF TABLE
    MOVWF   PCLATH		;SET PAG
    MOVF    TABLE_TEMPORAL,W	;RECOVER INDEX
    ANDLW   MAX_COLORS		;GET MAX 16
    ADDLW   COLORS_GREEN	;ADD LOW
    BTFSC   STATUS,C		;CHECK IF ROLLOVER, 1 MAX, table size 256 (0-255)
    INCF    PCLATH,F
    MOVWF   PCL
GET_RED
    MOVWF   TABLE_TEMPORAL	;PUT INDEX OUT OF WAY
    MOVLW   HIGH COLORS_RED	;GET HIGH PART OF TABLE
    MOVWF   PCLATH		;SET PAGE
    MOVF    TABLE_TEMPORAL,W	;RECOVER INDEX
    ANDLW   MAX_COLORS		;GET MAX 16
    ADDLW   COLORS_RED		;ADD LOW
    BTFSC   STATUS,C		;CHECK IF ROLLOVER, 1 MAX, table size 256 (0-255)
    INCF    PCLATH,F
    MOVWF   PCL
GET_BLUE
    MOVWF   TABLE_TEMPORAL	;PUT INDEX OUT OF WAY
    MOVLW   HIGH COLORS_BLUE	;GET HIGH PART OF TABLE
    MOVWF   PCLATH		;SET PAGE
    MOVF    TABLE_TEMPORAL,W	;RECOVER INDEX
    ANDLW   MAX_COLORS		;GET MAX 16
    ADDLW   COLORS_BLUE		;ADD LOW
    BTFSC   STATUS,C		;CHECK IF ROLLOVER, 1 MAX, table size 256 (0-255)
    INCF    PCLATH,F
    MOVWF   PCL
    
    
PRINT_SCREEN			    ; Only works on bank 0 or 2
    BSF	PORTC,RC7		    ; SET OUTPUT HIGH, START RESET
    MOVLW   .80
    MOVWF   CURRENT_COLUMN
    SEND_RESET_HIGH			    ; Reset >50 microseconds
	DECFSZ	CURRENT_COLUMN,F	    ; Tnstruction 0.4 * 3 (AMOUNT INST) 10MHz
	GOTO SEND_RESET_HIGH		    ;  = 1.2 microseconds
	
    BCF	PORTC,RC7		    ; SET OUTPUT LOW, START RESET
    MOVLW   .80
    MOVWF   CURRENT_COLUMN
    SEND_RESET			    ; Reset >50 microseconds
	DECFSZ	CURRENT_COLUMN,F	    ; Tnstruction 0.4 * 3 (AMOUNT INST) 10MHz
	GOTO SEND_RESET		    ;  = 1.2 microseconds
	
	
    ;BSF	PORTC,RC6
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP	   
    ;BCF	PORTC,RC6
	
	
    MOVLW   ARRAY_START		    ; START INDIRECT ACCES TO FIRST WORD
    MOVWF   FSR			    
    
    MOVLW   SIZE_COL
    MOVWF   COLUMN_INDEX
    COLUMN_LOOP
	MOVLW	SIZE_B
	MOVWF	CURRENT_COLUMN_INDEX
	
	MOVF	INDF,W
	MOVWF	CURRENT_COLUMN	    ;LED PATTERN
	INCF	FSR,F
	
	MOVF	INDF,W
	MOVWF	CURRENT_COLOR	    ;LED COLOR
	INCF	FSR,F
	
	COLUMN_BIT
	MOVF	CURRENT_COLOR,W
	BTFSS   CURRENT_COLUMN,7	; IF CURRENT POSITIOS IS ON
	MOVLW   COLOR_BLACK
	MOVWF   TEMP_COLOR
	    
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    ;GREEN
	    CALL    GET_GREEN
	    MOVWF   DISPLAY_COLOR
	    MOVLW   SIZE_B
	    MOVWF   CURRENT_DISPLAY_INDEX
	    GREEN_LOOP
		BTFSS   DISPLAY_COLOR,7	; IF 0 HIGHEST BIT
		GOTO    LOOP_GREEN_SHORT	; GO TO SHORT
		BSF	    PORTC,RC7		; LONG, 1
		NOP
		NOP
		NOP
		BCF	    PORTC,RC7
		GOTO    LOOP_GREEN_END
		LOOP_GREEN_SHORT
		BSF	    PORTC,RC7		; SHORT, 0
		BCF	    PORTC,RC7
		LOOP_GREEN_END
		RLF	DISPLAY_COLOR,F
		DECFSZ  CURRENT_DISPLAY_INDEX,F
		GOTO GREEN_LOOP
	    
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
		
	    ;RED
	    MOVF    TEMP_COLOR,W
	    CALL    GET_RED
	    MOVWF   DISPLAY_COLOR
	    MOVLW   SIZE_B
	    MOVWF   CURRENT_DISPLAY_INDEX
	    RED_LOOP
		BTFSS   DISPLAY_COLOR,7	; IF 0 HIGHEST BIT
		GOTO    LOOP_RED_SHORT	; GO TO SHORT
		BSF	    PORTC,RC7		; LONG, 1
		NOP
		NOP
		NOP
		BCF	    PORTC,RC7
		GOTO    LOOP_RED_END
		LOOP_RED_SHORT
		BSF	    PORTC,RC7		; SHORT, 0
		BCF	    PORTC,RC7
		LOOP_RED_END
		RLF	DISPLAY_COLOR,F
		DECFSZ  CURRENT_DISPLAY_INDEX,F
		GOTO RED_LOOP
	    
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
	    NOP
		
	    ;BLUE
	    MOVF    TEMP_COLOR,W
	    CALL    GET_BLUE
	    MOVWF   DISPLAY_COLOR
	    MOVLW   SIZE_B
	    MOVWF   CURRENT_DISPLAY_INDEX
	    BLUE_LOOP
		BTFSS   DISPLAY_COLOR,7	; IF 0 HIGHEST BIT
		GOTO    LOOP_BLUE_SHORT	; GO TO SHORT
		BSF	    PORTC,RC7		; LONG, 1
		NOP
		NOP
		NOP
		BCF	    PORTC,RC7
		GOTO    LOOP_BLUE_END
		LOOP_BLUE_SHORT
		BSF	    PORTC,RC7		; SHORT, 0
		BCF	    PORTC,RC7
		LOOP_BLUE_END
		RLF	DISPLAY_COLOR,F
		DECFSZ  CURRENT_DISPLAY_INDEX,F
		GOTO BLUE_LOOP
		
	    ;BSF	PORTC,RC6	   
	    ;BCF	PORTC,RC6
	    RLF	CURRENT_COLUMN,F
	    DECFSZ  CURRENT_COLUMN_INDEX,F
	    GOTO COLUMN_BIT

	DECFSZ	COLUMN_INDEX,F
	GOTO	COLUMN_LOOP

    ;BCF	PORTC,RC6
    BSF PORTC,RC7	
    RETURN

    
MAIN_PROG CODE                      ; let linker place main program

START
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH
    BANKSEL TRISC		    ; GOTO BANK
    BCF	TRISC,RC6	
    BCF	TRISC,RC7		    ; SET PINRC7 AS OUTPUT
    MOVLW   0xF0
    MOVWF   TRISB
    
    BANKSEL OSCCON
    clrf	OSCCON			; Internal clock to 31KHz & ext clock source
    
    BANKSEL OSCCON		    ; OSCILATOR CONFIG
    BSF	OSCCON,IRCF2
    BSF	OSCCON,IRCF1
    BCF	OSCCON,IRCF0		    ; SET OSCILATOR TO 4MHZ
    
    STABILIZATION
	BTFSS	OSCCON,HTS	    ; JUST WAIT UNTIL FLAG OF STABILIZATION
	GOTO STABILIZATION

	
    BANKSEL PORTC
    
    BSF PORTC,RC7		    ; SET OUTPUT HIGH
    CLRF    LAST_POS
    
    MOVLW   SIZE_COL		    ; LOAD COUNTER TO ACUM
    MOVWF   CURRENT_COLUMN	    ; ACUM TO RAM
    
    BCF	    STATUS,IRP		    ; INDIRECT BANK 0,1
    MOVLW   ARRAY_START			    ; GET START POSITION OF COLUMNS
    MOVWF   FSR			    ; INDIRECT ADDRESSING TO START
    
    INITIALIZE			    ; LOOP TO SET RAM
	MOVLW	0x00		    ; COLUMNS ON
	MOVWF	INDF		    ; FROM ACUM TO INDF COLUMNS ON AND OFF
	INCF	FSR,F		    ; INCREMENT INDIRECT TO INDIRECT
	
	MOVLW	0x01
	MOVWF	INDF		    ; FROM ACUM TO INDF	COLOR OF COLUMN
	INCF	FSR,F		    ; INCREMENT INDIRECT TO INDIRECT
	
	DECFSZ	CURRENT_COLUMN,F    ; DECREASE RAM COUNTER TO SELF
	GOTO	INITIALIZE

	
    LOGIC_LOOP
	BSF	PORTC,RC6	   
	BCF	PORTC,RC6

	CALL	PRINT_SCREEN
	
	MOVF	LAST_POS,W
	ADDLW	ARRAY_START
	MOVWF	FSR
	MOVF	PORTB,W
	
	BTFSS	LAST_POS,0x01
	CALL	REVERSE_BYTE
	
	MOVWF	INDF
	
	INCF	LAST_POS,F
	INCF	LAST_POS,W
	ANDLW	0x3F
	MOVWF	LAST_POS
	
	GOTO LOGIC_LOOP
END