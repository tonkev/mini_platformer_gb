INCLUDE "src/utilities.asm"
INCLUDE "src/metasprites.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/input.asm"
INCLUDE "src/collision.asm"

PLAYER_GND_ACC SET 1
PLAYER_AIR_ACC SET 1

PLAYER_JMP_GRAVITY SET 1
PLAYER_AIR_GRAVITY SET 2

PLAYER_GND_DEACC SET 1
PLAYER_AIR_DEACC SET 1

PLAYER_MAX_GND_SPEED SET 8
PLAYER_MAX_AIR_SPEED SET 8

PLAYER_TERMINAL_SPEED SET 8
PLAYER_JUMP_SPEED SET 16

PLAYER_STAND_TILE SET 0
PLAYER_RUN_TILE_0 SET 0
PLAYER_RUN_TILE_1 SET 1
PLAYER_JUMP_TILE SET 2
PLAYER_FALL_TILE SET 3

SECTION "Player Tiles", ROM0

PlayerTiles:
INCLUDE "spr/player.z80"
PlayerTilesEnd:

SECTION "Player Tiles RAM", VRAM[$8000]

PlayerTilesVRAM:
DS PlayerTilesEnd - PlayerTiles

SECTION "Player Vars", WRAM0

PlayerState:
DS 1
PlayerVY:
DS 1
PlayerVX:
DS 1
PlayerY:
DS 1
PlayerX:
DS 1

SECTION "Player Setup", ROM0

PlayerSetup:
	
	ld hl, PlayerTilesVRAM
	ld de, PlayerTiles
	ld bc, PlayerTilesEnd - PlayerTiles
	call CopyMemory
	
	xor a
	ld [PlayerState], a
	ld [PlayerVY], a
	ld [PlayerVX], a
	
	ld a, $20
	ld [PlayerY], a
	ld [PlayerX], a
	
	ld c, 1
	call NewMetasprite
	
	ld e, b
	ld a, $20
	call SetMetaspriteAnimationState	
	
	ld hl, PlayerUpdate
	;ld e, b
	call RegisterUpdateCall
	
	ret

SECTION "Player Update", ROM0

;e - MetaspriteID

PlayerUpdate:

	ld a, [PlayerState]
	cp $01
	jr z, .running
	cp $02
	jr z, .jumping
	cp $03
	jr z, .jumping
	cp $04
	jr z, .falling
	cp $05
	jr z, .falling
	
.standing:
	ld a, PLAYER_STAND_TILE
	ld b, PLAYER_GND_ACC
	ld c, PLAYER_MAX_GND_SPEED
	ld h, PLAYER_AIR_GRAVITY
	jr .exit_state
	
.running:
	call GetMetaspriteAnimationFrame
	add PLAYER_RUN_TILE_0
	ld b, PLAYER_GND_ACC
	ld c, PLAYER_MAX_GND_SPEED
	ld h, PLAYER_AIR_GRAVITY
	jr .exit_state
	
.jumping:
	ld a, [IsPressed]
	bit 0, a
	jr z, .prefalling

	ld a, PLAYER_JUMP_TILE
	ld b, PLAYER_AIR_ACC
	ld c, PLAYER_MAX_AIR_SPEED
	ld h, PLAYER_JMP_GRAVITY
	jr .exit_state
	
.prefalling:
	ld a, $04
	ld [PlayerState], a	

.falling:
	ld a, PLAYER_FALL_TILE
	ld b, PLAYER_AIR_ACC
	ld c, PLAYER_MAX_AIR_SPEED
	ld h, PLAYER_AIR_GRAVITY

.exit_state:
	
	ld l, e	
	call SetMetaspriteTile
	
	ld a, [PlayerVY]
	ld d, a
	ld a, [PlayerVX]
	ld e, a
	
	ld a, [IsPressed]
	bit 5, a
	jr z, .notPressingLeft
	
	;2s complement of max speed
	ld a, c
	xor $FF
	inc a
	ld c, a
	
	ld a, e
	sub b
	cp c
	jr nc, .dontClampRunLeft
	
	ld a, c
	
.dontClampRunLeft:

	push de
	ld c, a
	ld e, l
	ld a, $20
	call SetMetaspriteOAMFlag
	pop de
	ld a, c
	
	jr .afterPressedLeft
	
.notPressingLeft:

	bit 4, a
	jr z, .notPressingRight
	
	ld a, e
	add b
	cp c
	jr c, .dontClampRunRight
	
	ld a, c
	
.dontClampRunRight:

	push de
	ld c, a
	ld e, l
	xor a
	call SetMetaspriteOAMFlag
	pop de
	ld a, c
	
.afterPressedLeft
	
	ld c, a
	ld a, [PlayerState]
	or $01
	ld [PlayerState], a
	ld a, c
	
	jr .notStill
	
.notPressingRight:

	ld a, e
	bit 7, a
	jr nz, .positive
	
	add b
	bit 7, a
	jr nz, .dontZeroRun
	
	jr .zeroRun
	
.positive:

	sub b
	bit 7, a
	jr z, .dontZeroRun
	
.zeroRun:
	
	xor a
	
.dontZeroRun:

	ld c, a
	ld a, [PlayerState]
	and $FE
	ld [PlayerState], a
	ld a, c

.notStill

	ld e, a
	
	ld a, h
	add d
	bit 7, a
	jr nz, .dontClampFall
	cp PLAYER_TERMINAL_SPEED
	jr c, .dontClampFall
	ld a, PLAYER_TERMINAL_SPEED
	
.dontClampFall
	
	ld d, a
	
	ld a, [PlayerState]
	and $FE
	jr nz, .notOnGround
	ld a, [JustPressed]
	bit 0, a
	jr z, .jumpNotPressed
	
	ld d, -PLAYER_JUMP_SPEED
	
	ld a, $02
	ld [PlayerState], a
	
.notOnGround
.jumpNotPressed

	ld a, d
	ld [PlayerVY], a
	ld a, e
	ld [PlayerVX], a
	
	sra d
	sra d
	sra e
	sra e
	
	ld a, [PlayerY]
	add d
	ld b, a
	
	ld a, [PlayerX]
	add e
	ld c, a
	
	push hl	
	push bc
	
	ld hl, $0808
	ld e, d
	call ResolveYMovementAgainstMap	
	
	ld a, [PlayerVX]
	ld e, a
	ld hl, $0808
	call ResolveXMovementAgainstMap
	
	pop de
	push de
	ld a, d
	sub b	
	ld b, d
	ld e, a
	
	ld hl, $0808
	call ResolveYMovementAgainstMap	
	
	pop de
	push de
	ld a, e
	sub c	
	ld c, e
	ld e, a
	
	ld hl, $0808
	call ResolveXMovementAgainstMap
	
	pop de
	ld a, b
	cp d	
	ld a, [PlayerVY]
	jr nz, .hit
	
	bit 7, a
	jr z, .setFalling
	
.notFalling
	ld a, [PlayerState]
	and %11111011
	jr .skipFalling
	
.hit

	bit 7, a
	jr z, .notFalling
	
	xor a
	ld [PlayerVY], a

.setFalling	

	ld a, $04

.skipFalling

	ld [PlayerState], a
	
	pop hl
	
	ld a, b
	ld [PlayerY], a
	
	ld a, c
	ld [PlayerX], a

	;ld l, b
	call MoveMetasprite

	ret