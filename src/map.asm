IF !DEF(MAP)
MAP SET 1

SECTION "Map", ROM0

MapTiles:
INCLUDE "spr/ground.z80"
MapTilesEnd:

Map:
INCLUDE "map/map.z80"
MapEnd:

SECTION "Map Tiles VRAM", VRAM[$9010]

MapTilesVRAM:
DS MapTilesEnd - MapTiles

SECTION "Map VRAM", VRAM[$9800]

MapVRAM:
DS MapEnd - Map



SECTION "MapSetup", ROM0

MapSetup:

	ld hl, MapTilesVRAM
	ld de, MapTiles
	ld bc, MapTilesEnd - MapTiles
	call CopyMemory
	
	ld hl, MapVRAM
	ld de, Map
	ld bc, MapEnd - Map
	call CopyMemory

	ret
	
ENDC