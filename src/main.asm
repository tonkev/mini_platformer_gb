INCLUDE "inc/hardware.inc"
INCLUDE "src/utilities.asm"
INCLUDE "src/metasprites.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/input.asm"
INCLUDE "src/map.asm"
INCLUDE "src/player.asm"

SECTION "V-Blank Interrupt", ROM0[$40]
	push bc
	push de
	push hl
	push af
	call FlushOAMBuffer
	pop af
	pop hl
	pop de
	pop bc
	reti

;SECTION "LCDC Interrupt", ROM0[$48]

;	reti

;SECTION "Timer Interrupt", ROM0[$50]
	
;	reti

SECTION "Serial Interrupt", ROM0[$58]

	reti

SECTION "P10-P13 Interrupt", ROM0[$60]

	reti
 
SECTION "Header", ROM0[$100]
 
EntryPoint:
	di
	jp Start


REPT $150 - $104
    db 0
ENDR

SECTION "Game code", ROM0

Start:
	call TurnOffLCD
	
	call UpdatesSetup
	call MetaspritesSetup
	call InputSetup
	call MapSetup
	call PlayerSetup
	
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a
	
	xor a
	ld [rSCY], a
	ld [rSCX], a
	
	; Turn off sound
	ld [rNR52], a

	ld [rIF], a
	; Enable Vblank interrupt
	ld a, %00000001
	ld [rIE], a
	
	ld a, %10000011
	ld [rLCDC], a
	
	ei

.main
	halt
	call UpdateAll
	jr .main