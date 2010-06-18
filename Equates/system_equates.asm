
;-- ROM / Bootcode related values ----------------------------------------------------

new_bootcode_location	equ $200	; bootcode 6.10+
new_bootcode_length		equ $DC0
new_rom_stack		equ $FFF

;-- OS related values ----------------------------------------------------------------

keymaps			equ $200		; "under" the video registers (to $37f)

host_device_hardware_info	equ $380		; "under" the video registers (to $3ff)

volume_mount_list		equ $400		; "under" the video registers (to $47f)

pointer_colours		equ $480		; "under" the video registers (to $48f)

sector_buffer		equ $800

irq_jp_inst		equ $a00		
irq_vector		equ $a01		; to $a02
nmi_jp_inst		equ $a03
nmi_vector		equ $a04		; to $a05
ide_status		equ $a06		; not used on v6z80p

scratch_pad		equ $a08		; general work RAM (WARNING: MAY APPROACH STACK)

stack			equ $aff		; max stack height = 250 byes
	
OS_variables		equ $b00		; max length = 256 bytes
OS_charmap		equ $c00		; 25 x 40 chars

OS_location		equ $1000

;-------------------------------------------------------------------------------------
