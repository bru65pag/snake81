format zx81
;labelusenumeric


// hardware options to be set and change defaults in ZX81DEF.INC
MEMAVL	 =	   MEM_16K		  // can be MEM_1K, MEM_2K, MEM_4K, MEM_8K, MEM_16K, MEM_32K, MEM_48K
									// default value is MEM_16K
STARTMODE  EQU	 SLOW_MODE		// SLOW or FAST
DFILETYPE  EQU	 AUTO			 // COLLAPSED or EXPANDED or AUTO
STARTUPMSG EQU	'SNAKE V2 ASM'	   // any message will be shown on screen after loading, max. 32 chars

include 'SINCL-ZX\ZX81.INC'		 // definitions of constants
; THE DESIGN
; 3 levels: SLUG, WORM, PYTHON
; Score starts at 0 and increases each time the snake size increases
; The snake is represented by a black square.
; Initial move is random (left, right, up, down)
; Snake moves in the same direction until a key is hit
; If snake finds a pill, snake size grows by one black square
;
; V2: the logic is there.
;     Still missing: levels and best score

   1 REM SNAKE V2

   2 REM _asm

START:
; clear SBODY
	ld hl,SBODY
LOOP7:
	ld a,(hl)
	cp $FF
	jp z, END_CLEAR_SBODY
	ld (hl), $FF
	inc hl
	jp LOOP7
END_CLEAR_SBODY:

;  print string "SCORE=000" at 0,0
	ld  d,0
	ld  e,0
	ld hl,STR_SCORE
	call PRINT_STRING

;  print string "LEVEL=" at 0,24
	ld  d,0
	ld  e,24
	ld hl,STR_LEVEL
	call PRINT_STRING
; print level

; snake initial random position in HLINE, HCOL
; HLINE = 2+INT(RND*20), HCOL = 2+INT(RND*29)
	ld b,20
	call FUNC_RAND_NUM
	add a,2
	ld (HLINE),a
	ld b,29
	call FUNC_RAND_NUM
	add a,2
	ld (HCOL),a

; snake initial  direction in SDIR
; SDIR = (1=right, -1=left, 2=up, -2=down)
INIT_SNAKE_DIR:
	ld b,4
	call FUNC_RAND_NUM
	add a,1
DIR_RIGHT:
	cp 1
	jp nz, DIR_LEFT
	// right
	ld a,1
	ld (SDIR),a
;        ld (NDIR),a
	jp END_INIT_SNAKE_DIR
DIR_LEFT:
	cp 2
	jp nz, DIR_DOWN
	// left
	ld a,-1
	ld (SDIR),a
;        ld (NDIR),a
	jp END_INIT_SNAKE_DIR
DIR_DOWN:
	cp 3
	jp nz,DIR_UP
	ld a,2
	ld (SDIR),a
;        ld (NDIR),a
	jp END_INIT_SNAKE_DIR
DIR_UP:
;        cp 4
;        jp nz,INIT_SNAKE_DIR
	ld a,-2
	ld (SDIR),a
;        ld (NDIR),a

END_INIT_SNAKE_DIR:

; print snake
	call FUNC_ADD_HEAD

; print new pill
	call FUNC_NEW_PILL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN_LOOP:
; read keyboard, compute new direction (NDIR)
RIGHT_KEY_HIT:
	ld a,$FE
	in a,($FE)
	bit 1,a 	  // Z key ?
	jp nz,LEFT_KEY_HIT
	ld a,1
	ld (NDIR),a
	jp END_READ_KEYBOARD
LEFT_KEY_HIT:
	ld a,$FD
	in a,($FE)
	bit 0,a 	   // A key ?
	jp nz,DOWN_KEY_HIT
	ld a,-1
	ld (NDIR),a
	jp END_READ_KEYBOARD
DOWN_KEY_HIT:
	ld a,$BF
	in a,($FE)
	bit 1,a 	  //L key ?
	jp nz, UP_KEY_HIT
	ld a,2
	ld (NDIR),a
	jp END_READ_KEYBOARD
UP_KEY_HIT:
	ld a,$DF
	in a,($FE)
	bit 0,a 	  // P key ?
	jp nz,EXIT_KEY_HIT
	ld a,-2
	ld (NDIR),a
	jp END_READ_KEYBOARD
EXIT_KEY_HIT:
	ld a,$FE
	in a,($FE)
	bit 2,a 	  // X key ?
	ret z		  // leave game if X key hit
NO_KEY_HIT:
	ld a,(SDIR)
	ld (NDIR),a
END_READ_KEYBOARD:
;update snake dir, ignore if direction is opposite
	ld a,(NDIR)
	ld b,a
	ld a,(SDIR)
	add a,b
	jp z,SAME_DIR
NEW_DIR:
	ld a,(NDIR)
	ld (SDIR),a
	jp  END_UPDATE_SNAKE_DIR
SAME_DIR:
	ld a,(SDIR)
	ld(NDIR),a
END_UPDATE_SNAKE_DIR:


; compute new snake head in (HLINE,HCOL)
	ld a,(NDIR)
RIGHT_DIR:
	ld b,1
	cp b		 // right direction?
	jp nz,LEFT_DIR
	ld a,(HCOL)
	inc a
	ld (HCOL),a
	ld b,31
	cp b
	jp nz,END_DIR
	ld a,1
	ld (HCOL),a
	jp END_DIR
LEFT_DIR:
	ld b,-1
	cp b		 // left direction?
	jp nz,DOWN_DIR
	ld a,(HCOL)
	dec a
	ld (HCOL),a
	ld b,0
	cp b
	jp nz,END_DIR
	ld a,30
	ld (HCOL),a
	jp END_DIR
DOWN_DIR:
	ld b,2
	cp b		 // down direction?
	jp nz,UP_DIR
	ld a,(HLINE)
	inc a
	ld (HLINE),a
	ld b,23
	cp b
	jp nz,END_DIR
	ld a,1
	ld (HLINE),a
	jp END_DIR
UP_DIR:
	ld b,-2
	cp b		 // up direction?
	jp nz,END_DIR
	ld a,(HLINE)
	dec a
	ld (HLINE),a
	ld b,0
	cp b
	jp nz,END_DIR
	ld a,22
	ld (HLINE),a
END_DIR:
; check if new head is on existing snake body part
	ld hl,HLINE
	ld d,(hl)
	ld hl,HCOL
	ld e,(hl)
	call FUNC_IS_SBODY_PART
	cp 1
	ret z
; print new head
	call FUNC_ADD_HEAD
	ld b,2
	call FUNC_WAIT
; check if snake ate pill
	ld a,(PLINE)
	ld b,a
	ld a,(HLINE)
	cp b
	jp nz,NO_PILL
	ld a,(PCOL)
	ld b,a
	ld a,(HCOL)
	cp b
	jp nz,NO_PILL
; snake ate pill
	// update score
	ld de,STR_SCORE+6
	ld a,(SCORE)
	inc a
	ld (SCORE),a
	ld h,0
	ld l,a
	call FUNC_8BIT_TO_STRING
	ld d,0
	ld e,6
	ld hl, STR_SCORE+6
	call PRINT_STRING
	// print new pill on screen
	call FUNC_NEW_PILL
	// and loop
      jp MAIN_LOOP
NO_PILL:
; snake did not ate pill
	// erase tail
	call FUNC_ERASE_TAIL
	jp MAIN_LOOP

FUNC_NEW_PILL:
	// compute new pill location in (PLINE,PCOL)
	ld b,20
	call FUNC_RAND_NUM
	add a,2
	ld (PLINE),a
	ld b,29
	call FUNC_RAND_NUM
	add a,2
	ld (PCOL),a
	// make sure it's not a snake body part
	ld hl,PLINE
	ld d,(hl)
	ld hl,PCOL
	ld e,(hl)
	call FUNC_IS_SBODY_PART
	cp 1
	jp z,FUNC_NEW_PILL
	// print pill on screen
	ld a,(PLINE)
	ld d,a
	ld a,(PCOL)
	ld e,a
	call FUNC_GET_DFILE_ADDRESS
	ld (hl),$34
	ret

////////////////////////
FUNC_ERASE_TAIL:
; uses SBODY,SBODY+1 to erase tail on screen
	ld hl,SBODY
	ld d,(hl)
	ld hl,SBODY+1
	ld e,(hl)
	call FUNC_GET_DFILE_ADDRESS
	ld (hl), $00
;erase tail from SBODY at position (SBODY,SBODY+1)
	ld de,SBODY
	ld hl,SBODY+2
LOOP2:
	ld a,(hl)
	cp $FF
	ret z
	ld (de),a
	ld (hl),$FF
	inc de
	inc hl
	jp LOOP2
	ret

////////////////////////
FUNC_ADD_HEAD:
; head is in (HLINE,HCOL)
	ld hl,HLINE
	ld d,(hl)
	ld hl,HCOL
	ld e,(hl)
	call FUNC_GET_DFILE_ADDRESS
	ld (hl),$80
; add snake head to SBODY
	ld hl,SBODY-1
LOOP1:
	inc hl
	ld a,(hl)
	CP $FF
	jp nz,LOOP1
	ld a,(HLINE)
	ld (hl),a
	inc hl
	ld a,(HCOL)
	ld (hl),a
	ret

////////////////////////
FUNC_IS_SBODY_PART:
; check if line,col in reg d and e are an element of the snake
; returns 1 in a if found, 0 otherwise
	ld hl,SBODY
LOOP4:
	ld a,(hl)
	cp d
	jp z,LINE_FOUND
	inc hl
	inc hl
	ld a,(hl)
	cp $FF
	jp z,NOT_FOUND
	jp LOOP4
LINE_FOUND:
	inc hl
	ld a,(hl)
	cp e
	jp z,FOUND
NOT_FOUND:
	ld a,0
	ret
FOUND:
	ld a,1
	ret

////////////////////////
FUNC_WAIT:					  ;
; Input: B = number of 1/10 seconds
; Each innerloop takes 21 cycles, that is 21 * 0,3077 microseconds = 6.4617 microseconds
; repeated 2500 times gives approximately 1/10 sec
		ld hl,2500
WAIT_LOOP2:
	dec	 hl			  ; 6 cycles
	ld	  a,h			 ; 4 cycles
	or	  l			   ; 4 cycles
	jr	  nz,WAIT_LOOP2   ; 12 cycles if z=0, 7 otherwise
	dec	 b
	jr	  nz, FUNC_WAIT
	ret


////////////////////////
FUNC_RAND_NUM:
; Get a random 8-bit number within a range
; Call with B as the maximum value + 1
; example if B=4, returns a number between 0 and 3
	ld a, r
	ld hl, LMATH_GR_SEED
	add a, (hl)
	rrca
	ld (hl), a
RAND_NUM_LOOP:
	cp b
	ret c
	sub b
	jp RAND_NUM_LOOP
LMATH_GR_SEED:
	db 91

////////////////////////
FUNC_GET_DFILE_ADDRESS:
; return the adress of a position in the display memory
; in: line in register d, column in register e
; out: the address in register hl
	ld h, 0
	ld l, d
	add hl, hl	   // x2
	add hl, hl	   // x4
	add hl, hl	   // x8
	add hl, hl	   // x16
	add hl, hl	   // x32
	ld b, 0
	ld c, d
	add hl, bc	   // x33
; Add the column
	ld c, e
	add hl, bc
; Add to the base of the display memory (+1)
	ld de, (D_FILE)
	inc de
	add hl, de
	ret

////////////////////////
FUNC_8BIT_TO_STRING:
;INPUT  : hl = number to convert
;               : de = location of string
;OUTPUT : string at (de)
	ld	  bc,-100
	call	Num1
	ld	  c,-10
	call	Num1
	ld	  c,b
Num1:
	ld	  a,$1C-1				 ; chr$($1C) = '0'
Num2:
	inc	 a
	add	 hl,bc
	jr	  c,Num2
	sbc	 hl,bc

	ld	  (de),a
	inc	 de
	ret

////////////////////////
PRINT_STRING:
; INPUT  : - register d contains line location
;          - register e contains column location
;          - register hl contains address of string
; NOTE   : end of string is marked with $FF
	push hl
	call FUNC_GET_DFILE_ADDRESS	// returns print position in hl
	pop de
LBL1:
	ld a,(de)
	cp $FF
	ret z
	ld (hl),a
	inc hl
	inc de
	jp LBL1


////////////////////////
; data
HLINE:				       // snake head line position
	db $00
HCOL:				       // snake head column position
	db $00
SDIR:				       // snake direction
	db $01
NDIR:				       // snake new direction
	db $00
PLINE:				       // pill line position
	db $00
PCOL:				       // pill column position
	db $00
SBODY:				       // snake positions
				       // each position is stored with x and y coord
				       // 511 = max SLENGTH * 2 + one final FF
				       //
	db 511 dup ($FF)

LEVEL:		db $00
SCORE:		db $00

STR_SCORE:	dbzx 'SCORE=000'
		db $FF
STR_LEVEL:	dbzx 'LEVEL='
		db $FF
STR_LEVEL_1:	  dbzx 'SLUG'
		db $FF
STR_LEVEL_2:	  dbzx 'WORM'
		db $FF
STR_LEVEL_3:	  dbzx 'PYTHON'
		db $FF
END _asm


40 PRINT USR #START

include 'SINCL-ZX\ZX81DISP.INC' 	  ; include D_FILE and needed memory areas
VARS_ADDR:
		db $80
WORKSPACE:
assert ($-MEMST)<MEMAVL
// end of program