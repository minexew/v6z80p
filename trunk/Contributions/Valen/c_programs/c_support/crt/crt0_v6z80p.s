 ;; For now, $80 bytes are reserved  for HEADER area.
;; (see value l__HEADER in .map file of you project, it must be less than $5080)

 	;; Generic crt0.s for a V6Z80P
        .module crt0
       	.globl	_main
       	.globl	_own_sp

    .globl  l__INITIALIZER
    .globl  s__INITIALIZED
    .globl  s__INITIALIZER

	.area	_HEADER (ABS)
	;; 
	.org 	0x5000
	jp	init
        ;

init:
	ld (_flos_prog_vol),a                 ;when programs start, A = volume.
	ld (_flos_prog_dir),de                ;DE = dir cluster. store these values.
	
        ; save ptr to command line args (hl)
        push hl
        ld de,#0x5000             ; if being run from G command, HL which is normally
        xor a                     ; the argument string will be $5000
        sbc hl,de
        pop hl

        ld ix,#_flos_cmdline
        jr nz,cmdline_exist
        ld hl,#0
cmdline_exist:
        ld  (ix),l
        ld 1(ix),h


        ; save FLOS stack pointer
        ld hl,#0
        add hl,sp
        ld ix,#flos_sp
        ld  (ix),l
        ld 1(ix),h
	;; set our own stack
        ld ix,#_own_sp
        ld l, (ix)
        ld h,1(ix)
	ld sp,hl               

        ; init spawn cmd line
        ld ix,#_flos_spawn_cmd
        xor a
        ld  (ix),a

        ;; Initialise global variables
        call    gsinit
	call	_main
	jp	_exit

	;; Ordering of segments for the linker.
	.area	_HOME
	.area	_CODE
	.area	_INITIALIZER
	.area   _GSINIT
	.area   _GSFINAL

	.area	_DATA
	.area	_INITIALIZED
	.area	_BSEG
    .area   _BSS
    .area   _HEAP
    .area   _HEAP_END       ; workaround for heap (valen 7 jun 2010)

        .area   _CODE
__clock::
        ret
	;ld	a,#2
        ;rst     0x08

_exit::
        ld e,l  ; e = exit code for FLOS  (returned by  main() in L register)

        ld ix,#flos_sp
        ld l,  (ix)
        ld h,1 (ix)
        ld sp,hl

        ; hl = spawn cmd line 
        ld hl,#_flos_spawn_cmd

        xor a    ; set zero flag (exit to FLOS, with no error)  (zero flag will be checked by FLOS568+)
        ld a,e   ; a = exit code
        ret

flos_sp::
         .ds 2

_flos_cmdline::
         .ds 2
_flos_prog_vol::
	 .ds 1
_flos_prog_dir::
	 .ds 2


_flos_spawn_cmd::
        .ds 40
;;

        .area   _GSINIT
gsinit::
	ld	bc, #l__INITIALIZER
	ld	a, b
	or	a, c
	jr	Z, gsinit_next
	ld	de, #s__INITIALIZED
	ld	hl, #s__INITIALIZER
	ldir
gsinit_next:

        .area   _GSFINAL
        ret


