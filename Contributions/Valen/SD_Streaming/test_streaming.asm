
;---Standard header for V6Z80P and OS -------------------------------------------------

include "kernal_jump_table.asm"
include "OSCA_hardware_equates.asm"
include "system_equates.asm"

;--------------------------------------------------------------------------------------
req_hw_version	equ $638
;--------------------------------------------------------------------------------------


SYSBANK_FOR_LIST_SOUND1 equ $1          ; bank for list (buffer) of sound1
PTR_LIST_SOUND1         equ $8000       ; ptr to list (buffer) of file blocks 

SYSBANK_FOR_LIST_VIDEO1 equ $1          ; bank for list (buffer) of video1
PTR_LIST_VIDEO1         equ $8000+$4000 ; ptr to list (buffer) of file blocks 

; ---
SYSBANK_FOR_DECODEBUF   equ %00000100   ; bank for decode buffer (in this test we use sound RAM bank 0)
SND_DECODE_BUF          equ $8000       ; ptr to sound decode buffer (512*5 byte)
                                        ; (address for CPU)
SND_CHANNEL_NUMBER      equ 3           ; [0..3]  sound channel for playing sound stream
;--------------------------------------------------------------------------------------

	org $5000
        jp start
include	"lib1.asm"

include	"60Hz_related.asm"
include	"struct_related.asm"
include	"mmc_sdc_code.asm"		;
include	"streamed_file.asm"
include	"streamed_file_sound.asm"

include	"myvideo.asm"


start
        call check_V6Z80P_hardware_revision
        ld a,0
        ret nc          ;  return to OS, if was error

        call init_all_instances_of_StreamedFile

        ld hl,struct__stream_file_sound1                        ; ptr to struct
        call StreamedFile__build_sectors_list_for_sound_file
        ld a,0
        ret nc          ; return to OS, if was error

        ld hl,struct__stream_file_video1                        ; ptr to struct
        call StreamedFile__build_sectors_list_for_sound_file
        ld a,0
        ret nc          ; return to OS, if was error

;        xor a
;        ret

;-------- Initialize video --------------------------------------------------------------------
        call init_video_mode
        call clear_video_memory


wvrtstart	ld a,(vreg_read)		; wait for VRT
	and 1
	jr z,wvrtstart
wvrtend	ld a,(vreg_read)
	and 1
	jr nz,wvrtend
	


	call vrt_routines

;        call is_this_frame_can_be_omitted
;        jr c,can_be_omitted2
	
	ld hl,counter                          
	inc (hl)
;can_be_omitted2
	ld hl,counter_all                      
	inc (hl)

        call advance_60Hz_to_50Hz_counter
	
	in a,(sys_keyboard_data)
	cp $76
	jr nz,wvrtstart		;loop if ESC key not pressed

	xor a
	ld a,$ff			;quit (restart OS)
	ret


vrt_routines

        call setup_video_fetch_start_address    ; call video module to handle page flipping
        call setup_palette                      ;                      handle palette flipping

      	ld hl,$000               ; black
        call mark_frame_time


        call wait_for_display_window_part_of_scan_line  ; seems i need call it twice or some glith will appear in sound output (at least then i use VGA output)
        call wait_for_display_window_part_of_scan_line




;        call is_this_playercall_must_be_proccessed
;        ld a,1
;        jr nc,this_frame_can_be_omitted
;        ld a,0
;this_frame_can_be_omitted
;        ld (is_this_frame_can_be_omitted_var),a
  
      
;        call is_this_frame_can_be_omitted
;        jr c,can_be_omitted1

        call proccess_sound_file
        call proccess_video_file


;      	ld hl,$f0f               ; pink
;        call mark_frame_time
        ret
;can_be_omitted1
        ;call mmc_wait_4ms
;	ld a,%00000000			
;	out (sys_audio_enable),a		
;        ret







init_video_mode
	ld hl,0
	ld (palette),hl
	ld a,%00000100
	ld (vreg_vidctrl),a		; disable video whilst setting up
	
	ld a,%00000000		; select y window pos register
	ld (vreg_rasthi),a		; 
	ld a,$3d       ;$2e			; set 240 line display
	ld (vreg_window),a
	ld a,%00000100		; switch to x window pos register
	ld (vreg_rasthi),a		
	ld a,$f7       ;$bb
	ld (vreg_window),a		; set 128 pixels wide window

	ld hl,colours;
	ld de,palette		; upload palette;
	ld bc,512;
	ldir

        ; start address
	ld ix,bitplane0a_loc	; Show video buffer 0 or 1 
	ld hl,0			; Video window start address		
	ld a,0 
set_vaddr	ld (ix),l			;\ 
	ld (ix+1),h		;- Video fetch start address for this frame
	ld (ix+2),a		;/
	
		
	ld a,%10000000
	ld (vreg_vidctrl),a		; Set bitmap mode (bit 0 = 0) + chunky pixel mode (bit 7 = 1)	
        ret

init_all_instances_of_StreamedFile
        ld ix,struct__stream_file_sound1; instance of StreamedFile
        ld hl,filename_sound1           ; ptr to filename of streamed file   
        ld de,PTR_LIST_SOUND1           ; ptr to buffer for list of file blocks numbers   
        ld a,SYSBANK_FOR_LIST_SOUND1    ; a  = system bank for list    
        call StreamedFile__init

        ld ix,struct__stream_file_video1; instance of StreamedFile
        ld hl,filename_video1           ; ptr to filename of streamed file   
        ld de,PTR_LIST_VIDEO1           ; ptr to buffer for list of file blocks numbers   
        ld a,SYSBANK_FOR_LIST_VIDEO1    ; a  = system bank for list    
        call StreamedFile__init

        ret





;
; instance of StreamedFile
struct__stream_file_sound1   defs structsize__StreamedFile           ; just reserve space, no any init here
struct__stream_file_video1   defs structsize__StreamedFile           ; just reserve space, no any init here

filename_sound1              db "SND1.BIN",0
filename_video1              db "VID1.BIN",0
counter                      db 0
counter_all                  db 0

;sound1_buff
;incbin	"one.raw"		

colours		              ds 512
;incbin "vidpal.bin"

; -----------------------------------------------------

