IF !DEF(UI)
UI SET 1

INCLUDE "inc/hardware.inc"

SECTION "Clear Screen", ROM0

ClearScreen:

	ld hl, _SCRN0
	ld bc, _SCRN1 - _SCRN0
	xor a
	call ClearMemory
	
	ret
	
SECTION "Draw Text", ROM0

;parameters
;hl address to 0 terminated string
;de destination

DrawText:

.loop:
	ld a, [hli]
	cp 0
	ret z
	sub $20
	jr z, .space
	cp $21
	jr nc, .alpha
	sub $0F
	jr .numeric
.alpha:
	sub $16
.space:
.numeric:
	ld [de], a
	inc de
	jr .loop

SECTION "Clear Text", ROM0

;parameters
;hl address to 0 terminated string
;de destination

ClearText:

.loop:
	ld a, [hli]
	cp 0
	ret z
	xor a
	ld [de], a
	inc de
	jr .loop

ENDC