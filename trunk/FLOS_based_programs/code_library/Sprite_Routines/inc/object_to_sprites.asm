;
; object_to_sprites.asm for OSCA-based games - By Phil Ruston (This is not optimized at all)
;
;-----------------------------------------------------------------------------------------
; Game objects are built up from (multiple) component sprites with this routine.
; Each object has a data array holding the coordinate and definition offsets
; of each hardware sprite. 
;
; The routine does not waste sprite resources on sprites that are way (~256 pixels) outside
; the visible display window. However, if all allowed H/W registers are in use, a crude multiplexing
; feature can swap sprites on alternate frames. 
;
; Because the total number of sprites used can vary per frame (depending on the
; animation requirements), it is best to call the routine "clear_remaining_sprites"
; after all objects have been built so that no "debris" is left on screen.
; -----------------------------------------------------------------------------------------
;
;Data tables required:
;--------------------
;
; object_location_list	dw obj0, obj1, obj2, etc  - a list of pointers to each object's description
; 
; For each object:
; ----------------
;
; obj0	db $aa	- The number of hardware sprite resources (IE: registers) required by this object
;	dw $bbcc  - Definiton base for the sprite group 
;
;	db $xx	- x offset from origin for this sprite
;	db $yy	- y offset from origin for this sprite
;	db $dd 	- offset from definition base for this sprite
;	db $ef    - bits 7:4 = y height of sprite (in 16 line blocks) 3: X-Mirror, 2:0 = unused (set to 0)
;
;                   Repeat these four bytes for each sprite that object uses..
;
;
;---------------------------------------------------------------------------------------------------
; BUILD OBJECT FROM COMPONENT SPRITES ROUTINE
;---------------------------------------------------------------------------------------------------
;
; Input: IX = first sprite register for this object to use
;        HL = X origin coord of object ($100 = leftmost visible pixel of display, see "left_border")
;        DE = Y origin coord of object ($100 = topmost visible line of display, see "top_border")
;         A = object number
;
;      Optional variables: "sprite_max" - adjust to stop the sprites using higher sprite registers,
;                          "sprite_min" - wrap around point if spill-over from above
;
;                          "frame_counter" - increment this each frame if you want to use the crude
;                                            multiplexing feature
;
; Output: IX = sprite register location for next sprite (all other registers trashed)
;
;
;Requires Constants:
;-------------------
;
; top_border  	equ $29 ; The first line of the visible display (currently set for vreg_window x = $5x)
; left_border 	equ $7f ; The first visible leftmost pixel on the display (currently set for vreg_window x = $8x)
;
;-----------------------------------------------------------------------------------------------------


object_to_sprites

	
	ld bc,0-($100-left_border)	;sets origin $100,$100 at top left of display
	add hl,bc
	ld (origin_x),hl
	ex de,hl
	ld bc,0-($100-top_border)
	add hl,bc
	ld (origin_y),hl

	ld l,a
	ld h,0
	add hl,hl
	ld de,object_location_list 
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl
	
	ld a,(hl)			; A = number of sprites used by this object
	ld (spr_count),a		
	inc hl
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl		
	ld (def_base),de		; DE = sprite definition base
	ex de,hl
	
sproblp	push ix			; see if sprite max is above this sprite we're about to use
	pop hl
	ld bc,(sprite_max)
	xor a
	sbc hl,bc
	jr nz,sproktu		; sprite is OK to use
	ld a,1
	ld (spr_mux),a
	ld a,(frame_counter)	; if at sprite max, do a crude multiplex by wrapping 
	and 1			; around to first sprite resource on odd frames, and ditching 
	ret z			; the excess sprites on even frames
mplexs	ld ix,(sprite_min)

sproktu	ld hl,(origin_x)
	ld a,(de)			; x offset from origin
	bit 7,a
	jr z,spobadx	
	add a,l			; negetive offset
	jr c,spobno1
	dec h
	jp spobno1
spobadx	add a,l			; positive offset	
	jr nc,spobno1
	inc h
spobno1	ld (ix),a			; x coord LSB
	ld a,h
	and $fe			; if x > $200, dont bother plotting it
	jr nz,spr_ofsc1
	ld a,h
	and 1
	ld c,a			; C = x coord MSb

	inc de
	ld hl,(origin_y)
	ld a,(de)			; y offset from origin
	bit 7,a
	jr z,spobady	
	add a,l			; negetive offset
	jr c,spobno2
	dec h
	jp spobno2
spobady	add a,l			; positive offset
	jr nc,spobno2	
	inc h
spobno2	ld (ix+2),a		; y coord LSB
	ld l,a
	ld a,h
	or a
	jr z,spr_yok
	cp $ff
	jr z,spr_yok
	push bc
	ld bc,$120		; if y >= $0120 and < $ff00, dont bother plotting sprite
	xor a
	sbc hl,bc
	pop bc
	jr nc,spr_ofsc2
	ld a,1	
spr_yok	and 1
	sla a			; C = y coord MSb
	or c
	ld c,a
	
	inc de
	ld a,(de)			; a = definition offset
	ld hl,(def_base)
	add a,l
	jr nc,dmsbok
	set 2,c			; set definition number MSB if required
dmsbok	ld (ix+3),a		; write definition number LSB to H/W reg
	
	inc de
	ld a,(de)			; a = y height in bits 7:4, bit 3 = x mirror
	or c			; OR in the x/y MSBs
	ld (ix+1),a		; write y height, mirror, def MSb, X coord LSb, Y coord LSb to H/W reg
	
	inc de
	ld bc,4
	add ix,bc			; next hardware register

nxt_ofrag	ld hl,spr_count
	dec (hl)
	jp nz,sproblp
	ret
	

spr_ofsc1	inc de
spr_ofsc2	inc de
	inc de
	inc de
	ld (ix),0			;  make sure sprite is offscree
	ld (ix+1),0
	jr nxt_ofrag


origin_x		dw 0		; internal workings register
origin_y		dw 0		; ""
def_base		dw 0		; ""
spr_count		db 0		; ""
spr_mux		db 0		; ""

sprite_max	dw sprite_registers+$1fc
sprite_min	dw sprite_registers
frame_counter	db 0
		
;---------------------------------------------------------------------------------------------------

clear_remaining_sprites
	
	ld a,(spr_mux)
	or a
	jr z,nosprmux
	ld hl,(sprite_max)
	ld (prev_max),hl
	ret

nosprmux	ld hl,(prev_max)		;This removes all unused sprites from the display
	ld (prev_max),ix		;can be called after all objected have been built
	ld de,(prev_max)		;to remove sprite fragments from previous frame
	xor a
	sbc hl,de
	ret z
	ret c
	srl h
	rr l
	srl h
	rr l
	ld b,l			;number of sprite registers used compared to last frame
	push ix
	pop hl
	xor a
clspreglp	ld (hl),a			;clear x ccord
	inc l
	ld (hl),a			;clear x coord msb
	inc l
	inc l
	inc hl
	djnz clspreglp
	xor a
	ld (spr_mux),a
	ret

prev_max	dw sprite_registers

;---------------------------------------------------------------------------------------------------
	