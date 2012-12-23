;----------------------------------------------------------------------------------------
; Z80 Generic Protracker Music Player - V5.07
; By Phil Ruston 2008-2012
; http://www.retroleum.co.uk
;
; NOT OPTIMIZED AT ALL!
;----------------------------------------------------------------------------------------
;
;
; Z80 Code to process 31-instrument Protracker and 15-instrument Soundtracker modules.
;
; The code has been designed to be hardware agnostic, IE: the player itself
; does not write to any hardware registers. It uses "stand-in" variables for the
; Amiga hardware registers but still uses the Amiga values that would be written
; to them. Therefore it is up to a seperate "update_sound_hardware" routine to read these
; variables and adapt/convert the values therein to whatever hardware is being used to
; output the sound. 
;
;
; **********************
; External requirements:
; **********************
;
; The code uses faux-24 bit addressing internally, this allows a module of any size to be
; played (as long as it fits in memory!) As the module can be located anywhere in system RAM
; whenever the player needs to read pattern (or header) data, a call to a hardware-specific
; routine needs to be made allowing the appropriate page settings and offset to be computed and
; set/restored around the call. (The Z80 stack pointer SP should be in unpaged memory). 
;
;  Equates:
;  -------
;
;  "pt_module_loc_lo" = lower 16 bits of location of Protracker module (must be located at a word address boundary).
;  "pt_module_loc_hi" = upper 8 bits of location of protracker module.
;
;  Routines:
;  --------
;
;   pt_read_module_byte - a routine to return a byte in A from start of module data + DE
;
;   pt_get_note_row - a routine to read 16 bytes from address A:HL to internal variable array: pt_note_row
;   (this array needs to be in unpaged RAM).
;
;   pt_zero_byte - a routine to write zero to address in A:HL
;
;  ALL ROUTINES MUST PUSH AND POP ANY AFFECTED REGISTERS!
;
;  (If the module is located fully within simple 64K address space ($0-$FFFF) no paging is required
;  so these routines become trivial and pt_module_loc_hi can be set at 0)
;
;
;******************
; TO PLAY A MODULE
;******************
;
; Call "pt_init" to initialize/reset tune. Returns with ZF set if OK, not set if unplayable
; mod type (IE: Not Soundtracker 15 and I.D. word is not listed in "pt_idlist")
;
; Every frame, Call "pt_play" to update the tracker parameters and then call your custom
; routine to update the sound registers of your target hardware using data from the "fake
; Amiga registers" (see below for details).
;
; OPTIONAL: Call "pt_set_sample_base" to specify that samples are located separately.
;           (At A:HL - this address must be even. If this routine is called with an odd
;           value in A:HL, the samples are assumed to follow the song data - as a
;           normal part of the module)
;
;
; ********************************************
; Adapting output of player to custom hardware
; ********************************************
;
; Replacing the Amiga hardware registers is a list of variables starting at
; "channel_data"  There are 4 channels and "vars_per_channel" number of bytes
; used per channel. The offsets of the registers required (within each channel
; block) needed for playback on a given piece of audio hardware are as follows:
;
; samp_loc_00          ; LSB of 24 bit register - source location when starting new a sample (flat address)
; samp_loc_01          ;
; samp_loc_02          ; MSB
;
; samp_len_lo          ; LSB of 16 bit register - sample length, IN WORDS *
; samp_len_hi       
;
; samp_loop_loc_00     ; LSB of 24 bit register - location that the sample loops back to (flat address)
; samp_loop_loc_01 
; samp_loop_loc_02     ; MSB 
;         
; samp_loop_len_lo     ; LSB of 16 bit register - length to use when sample loops, IN WORDS *
; samp_loop_len_hi  
;
; period_lo            ; (LSB of 16 bit register) - Amiga Period register (frequency)
; period_hi
;
; volume               ; 8 bit register, values: - Loudness: $40:max - $0: min)
;
; control_bits         ; 8 bit register, see below:
;
; "control_bits" replaces the Amiga's DMA sound channel start/stop control.
; When bit 0 of each channel's "control_bits" variable has been set to 1, the
; hardware conversion routine should trigger a sample (ie: load its
; loc/len/loop_loc/loop_len hardware registes). The conversion routine
; should clear bit 0 of this byte after triggering a sample.
;
; * The Amiga hardware stipulates samples must be an even number of bytes long
; Therefore using 16bit variables allows a max sample size of 128KB instead of 64KB.
; Simply multiply values by 2 if your audio hardware requires sample length in bytes.
;
;
; Other variables: 
; ----------------
;
;"filter_on_off" (BYTE) reads ONE if player has enabled the filter with FX E0,
; zero if not. (Whether or not this is of any use depends on target hardware)
;
;
; Revisions:
; ----------
;
; v5.07 - Module is located with a flat address pointer and pattern data can cross Z80 pages.
;       - Each sample's Loc/len/finetune/vol/looploc/looplen data is copied to
;         a data table upon pt_init. Previously, only the location was precalculated,
;         the other data was obtained from the module on the fly. However, this would be slow
;         now that paging is involved.
;
;       - SOME basic adaptations for Soundtracker 15 sample mods
;
;       - Modified Pattern Break (Effect D) and Delay Loop (Effect EE) 
;
;	- If vol slide (Effect $A) has both up and down nybbles set (illegal) "volume up" now has priority (Spaceballs State-Of-The-Art module)
;
;       - Clears first two bytes of each sample (mainly for old Soundtracker tunes which sometimes have unwanted no-loop noise here)
;
; V5.06 - Location registers expanded to 24 bit
;         Location registers now return regular byte-addresses.
;         multiply_30 table removed: Values are computed instead.
;
; V5.05 - If a pattern note entry is blank, clear the previous FX number
;
; V5.04 - Fixed note triggering -  a bug in the target hardware conversion routine
;         was masking the incorrect retrigging (where a zero/same instrument or zero
;         period is specified)
; 
;
; Known limitations:
; ------------------
;
; $EF - invert loop is not implemented (rarely used anyway..)
;
; BPM speed settings are ignored. 
;
;========================================================================================
; IF USING MODS IN PAGED MEMORY KEEP THE FOLLOWING CODE IN UNPAGED MEMORY
;========================================================================================

pt_set_sample_base

          ld (force_sample_base),hl
          ld (force_sample_base+2),a
          ret

;----------------------------------------------------------------------------------------

pt_init   ld a,6                        	; default speed setting
          ld (songspeed),a
          xor a                         	; clear various flags and variables
          ld (ticker),a
          ld (songpos),a
          ld (patindex),a
          ld (arpeggio_counter),a
          ld (pattloop_pos),a
          ld (pattloop_count),a
          ld (pattdelay_count),a
	  ld (patt_break),a
          ld (ptfr_count),a
          ld hl,channel_data
          ld b,vars_per_channel*4
clchdlp   ld (hl),a
          inc hl
          djnz clchdlp

	  ld ix,20+(15*30)			; offset to pattern max (Soundtracker 15 samples)
	  ld iy,20+(15*30)+1+1+128		; offset 1st pattern (Soundtracker 15 samples)
	  ld c,0				; My Soundtracker (15 samples) ID
	  ld de,1080				; Is the M.K. ID present for Protracker?
	  ld b,4
pt_scanid call pt_read_module_byte
	  cp $20
	  jr c,pt_modst				; if a byte at 1080-1083 is not ascii it will be a Soundtracker mod
	  cp $60
	  jr nc,pt_modst
	  inc de
	  djnz pt_scanid
	  
	  ld ix,pt_idlist			; The 4 ID bytes are ASCII, find what type of 31 instrument module it is..
pt_idlp	  ld de,1080	
	  ld a,(ix)				; first byte of each entry is my ID (if zero, last entry of list)
	  or a
	  jr nz,pt_idok
	  inc a
	  ret				        ;return with ZF not set, unknown ID
pt_idok	  ld c,a				;C = ID (1 = M.K. assuming Protracker)
	  push ix
	  pop hl
	  inc hl
	  ld b,4
pt_chkid  call pt_read_module_byte
	  cp (hl)
	  jr z,pt_idmch
	  ld de,5
	  add ix,de
	  jr pt_idlp	  
pt_idmch  inc hl
	  inc de
	  djnz pt_chkid
	  ld ix,20+(31*30)			; Offset to pattern max (Protracker 31 samples)
	  ld iy,20+(31*30)+1+1+128+4		; Offset to 1st pattern (""              "")
	  
pt_modst  ld a,c
	  ld (pt_pattsmax_loc),ix		; set pattern count location		
	  ld (pt_patterns_loc),iy       	; set offset to pattern data
	  ld (pt_modtype),a			; set type of module 0 = ST, 1 = PT   
 	  
	  ld de,(pt_pattsmax_loc)		
	  call pt_read_module_byte
	  ld (max_pattern),a
	  inc de
	  inc de				; DE = offset to pattern list
	  ld b,128                      	
          ld h,0				
	  
ptfhplp   call pt_read_module_byte		 ; find highest used pattern in order to locate the address where samples start
          cp h
          jr c,patlower
          ld h,a
patlower  inc de
          djnz ptfhplp
          inc h					; each pattern is 1024 bytes long
	  xor a
	  ld l,a
	  add hl,hl
	  rla
	  add hl,hl
	  rla					; A:HL = total size of pattern data
	  
	  ld bc,(pt_patterns_loc)
	  add hl,bc				; add on variable size of header (depends on Protracker/Soundtracker)
	  adc a,0				
	  	  
	  ld bc,pt_module_loc_lo		; add on the base location of the module
     	  add hl,bc
	  adc a,pt_module_loc_hi		; A:HL = flat sysram address of first sample

          ld de,(force_sample_base)		; check to see if samples have been moved to a fixed
          bit 0,e				; location. If so "force_sample_base" bit 0 will be clear.
          jr nz,usenormsb
          ld hl,(force_sample_base)     
          ld a,(force_sample_base+2)
          
usenormsb 
          push af
	  ld b,15
	  ld a,(pt_modtype)
	  or a
	  jr z,st_mod
	  ld b,31				; number of sample info entries
st_mod	  pop af
	  ld ix,pt_sample_data_list		; build sample data list
          ld de,42				; offset from start of module for first length of sample
			  
bsstlp    push bc  
	  push de
	  ld (ix+pt_sampdata_loc),l           	; put location of sample [7:0] in table 
          ld (ix+pt_sampdata_loc+1),h          	; put location of sample [15:8] in table 
          ld (ix+pt_sampdata_loc+2),a          	; put location of sample [23:16] in table 
	  
	  call pt_zero_byte			; make sure first two bytes of each sample are zero (used for non-repeat silence)
	  inc hl
	  call pt_zero_byte
	  dec hl
	  
	  push af
	  call pt_read_module_byte		; read sample length [16:8] (big endian format in module)
	  ld (ix+pt_sampdata_len+1),a		; put length of sample in words [15:8] in table
	  inc de
	  ld b,a				; read sample length [7:0]
	  call pt_read_module_byte
	  ld (ix+pt_sampdata_len),a		; put length of sample in words [7:0] in table 
	  inc de
	  ld c,a				
	  pop af
	  add hl,bc				; add length of sample for next sample location
	  adc a,0
	  add hl,bc				; add again as length is in words
	  adc a,0				
	  push af				; stash A:HL
	  push hl
	 
	  call pt_read_module_byte		; read sample's fine tune value
	  inc de
	  and $f
	  ld (ix+pt_sampdata_ft),a		; put fine tune value in table
	  
	  call pt_read_module_byte		; read sample's default volume
	  inc de
	  ld (ix+pt_sampdata_vol),a		; put sample's default volume value in table
	  
	  call pt_read_module_byte		; read sample's repeat offset (hi) (big endian format in module)
	  inc de
	  ld b,a
	  call pt_read_module_byte		; read sample's repeat offset (lo)	
	  inc de	
	  ld c,a
	  ld a,(pt_modtype)			; if mod type is Sountracker, adjust from BYTE offset to standard WORD offset
	  or a
	  jr nz,pt_nstro
	  srl b
	  rr c
pt_nstro  ld (ix+pt_sampdata_loopoffset),c	; put sample's repeat offset (words) in table (hi)	
	  ld (ix+pt_sampdata_loopoffset+1),b	; put sample's repeat length (words) in table (lo)
	   	   
	  call pt_read_module_byte		; read sample's default repeat length 
	  inc de
	  ld h,a				; first byte is MSB (Big endian in module)
	  call pt_read_module_byte		
	  inc de	
	  ld l,a				; second bye is LSB
	  or h			
	  jr nz,pt_replok			; if replen = 0 (Taketracker mods do this) fix it to $0001		
	  ld l,1
pt_replok ld (ix+pt_sampdata_looplen),l		; put sample's default repeat length (words) in table (lo)
	  ld (ix+pt_sampdata_looplen+1),h	; put sample's default repeat length (words) in table (hi)	
	
	  pop hl				; retrieve A:HL (sample location tally)
	  pop af
	  
	  pop de				; advance module index (DE) to next sample_data entry in module
	  ex de,hl				; (30 bytes of data per sample)
	  ld bc,30
	  add hl,bc
	  ex de,hl				 
	  
	  ld bc,11				; 11 bytes per sample info table entry
	  add ix,bc
	  
	  pop bc 
          djnz bsstlp
          
	  xor a					; return ZF set, init OK
	  ret

;--------------------------------------------------------------------------------------

pt_play   call testtick0                         
          jp nz,not_new_line

	  ld a,(pattdelay_count)	; don't get new note data if pattern delay (from effect EE) > 0
	  or a				; just process existing effects
	  jp nz,not_new_line
 
	  xor a
          ld (arpeggio_counter),a       ; zero arpeggio counter on tick 0 (?)
	  
	  ld hl,(pt_pattsmax_loc)	; tick 0, so get a new line of note data 
	  inc hl
	  inc hl			; pattern list offset (variable for Soundtracker/Protracker)
	  ld a,(songpos)			
	  ld e,a
	  ld d,0
	  add hl,de
	  ex de,hl			; DE = offset of desired pattern into module data
	  call pt_read_module_byte	; A = pattern number required (multiply this by 1024 to locate pattern)
	  ld h,a
	  ld l,0
	  ld c,l
	  add hl,hl
	  rl c
	  add hl,hl
	  rl c				; C:HL = offset from first pattern to this pattern's base
	  push hl  			; push pattern offset lo
	  
	  ld a,(patindex)               ; multiply in-pattern line index by 16 
          ld h,0                        ; (4 bytes per note x 4 tracks)         
          ld l,a
          add hl,hl
          add hl,hl
          add hl,hl
          add hl,hl            	; hl = line offset
          ld de,(pt_patterns_loc)
	  add hl,de			; add on offset from start of module data to pattern data
	  ex de,hl
	  
	  ld a,pt_module_loc_hi		; A:HL = start of module
	  ld hl,pt_module_loc_lo
	  add hl,de			; Add on in-pattern index (plus offset from mod start)
	  adc a,0
	  pop de			; retrieve pattern offset lo
	  add hl,de
	  adc a,c			; A:HL = flat memory address of row of notes
	  call pt_get_note_row		; copy 16 bytes from the module's note row to "pt_note_row"
	  
          ld iy,channel_data  
	  ld ix,pt_note_row
          ld b,4                        ; 4 channels to do
chan_loop push bc
          ld a,(ix)                     ; any data on the note bytes?
          or (ix+1)
          or (ix+2)
          or (ix+3)
          jr nz,parse_dat
          ld (iy+fx_number),$ff         ; if all zeros clear the chan's previous fx number (v5.05)
          jr skipchan         
parse_dat call new_note_data  
skipchan  ld bc,vars_per_channel                  
          add iy,bc                     ; move to next channel's data table
          ld bc,4
          add ix,bc                     ; move next channel in song pattern
          pop bc
          djnz chan_loop
          jp tick_advance


;----- New note routines -------------------------------------------------------------------

new_note_data
          
          ld (iy+instrument_waiting),0
          ld a,(ix)                     ; get new instrument (sample) number in A
          and $f0
          ld b,(ix+2)
          srl b
          srl b
          srl b
          srl b
          or b                          
          jp z,no_new_instrument        ; dont get values when there's no new instrument specified

          ld (iy+instrument_waiting),a
          dec a
          ld c,a
	  ld b,0
	  ld l,a
	  ld h,b
	  add hl,hl
	  add hl,hl
	  add hl,hl			; 8 * n
	  add hl,bc			; + n
	  add hl,bc			; + n
	  add hl,bc			; + n 
          ld bc,pt_sample_data_list
          add hl,bc			; move to this sample's entry in sample info table (sample*11)
          ld e,(hl)
          ld (iy+samp_loc_00),e         ; start location of this sample (7:0)
          inc hl
          ld d,(hl)
          ld (iy+samp_loc_01),d         ; start location of this sample (15:8)
          inc hl
          ld a,(hl)
          ld (iy+samp_loc_02),a         ; start location of this sample (23:16)
	  push af
	  push de			; stash location A:DE
	  
          inc hl
	  ld a,(hl)
	  ld (iy+samp_len_lo),a		; set sample length (in WORDS) of this instrument (lo)
	  inc hl			; (assuming an non looping sample at this point)
	  ld a,(hl)
	  ld (iy+samp_len_hi),a		; set sample length (in WORDS) of this instrument (hi)

	  inc hl
	  ld a,(hl)
	  ld (iy+finetune),a		; set the fine tune value of this instrument
	  
	  inc hl
	  ld a,(hl)
	  ld (iy+volume_waiting),a	; note the volume value of this instrument
	  
	  inc hl
	  ld c,(hl)			
	  inc hl
	  ld b,(hl)			; BC = Repeat offset (always in words, pt_init converts ST mod byte offsets)  
	  
	  inc hl
	  ld e,(hl)
	  inc hl
	  ld d,(hl)			; DE = Repeat length (in words)	0 = no repeat.	
	  
	  ld a,d			; if DE > 1 this is a looping sample, we must adjust (1st pass) play length
	  or a				; It will play from start to reploc+replen, (then loop from start+reploc, using replen words)
	  jr nz,pt_repsam
	  ld a,e
	  cp 2
	  jr c,pt_nals			
pt_repsam ld h,d			
	  ld l,e			
	  add hl,bc
	  ld (iy+samp_len_lo),l
	  ld (iy+samp_len_hi),h
	  	  
pt_nals	  ld (iy+samp_loop_len_lo),e	; set sample loop length in WORDs (lo)
	  ld (iy+samp_loop_len_hi),d	; set sample loop length in WORDS (hi)

	  pop hl			; retrieve sample location in A:HL
	  pop af
          add hl,bc			; add repeat offset to original location (twice as offset is in WORDS)
	  adc a,0
st_mod2   add hl,bc
          adc a,0
	  ld (iy+samp_loop_loc_00),l    ; set sample loop loc for this instrument (23:16)
          ld (iy+samp_loop_loc_01),h    ; set sample loop loc for this instrument (15:8)
          ld (iy+samp_loop_loc_02),a    ; set sample loop loc for this instrument (7:0)
	
	
	
	  ld a,(pt_modtype)		; For Soundtracker, looping samples always go from Start+Loop_loc
	  or a				; even on the first pass..
	  jr nz,no_new_instrument
	  ld a,d			; is this a repeating sample (repeat length > 1) ?
	  or a
	  jr nz,stloop
	  ld a,e
	  cp 2
	  jr c,no_new_instrument
stloop	  ld l,(iy+samp_loc_00)
	  ld h,(iy+samp_loc_01)
	  ld a,(iy+samp_loc_02)
	  add hl,bc
	  adc a,0
	  add hl,bc
	  adc a,0
	  ld (iy+samp_loc_00),l
	  ld (iy+samp_loc_01),h
	  ld (iy+samp_loc_02),a

	  ld (iy+samp_len_lo),e
	  ld (iy+samp_len_hi),d
	  
	  
	  

no_new_instrument   

          ld a,(ix)                     ; get new period
          and $f
          ld b,a
          ld c,(ix+1)                   ; bc = new note's period
                    
          ld a,(ix+3)                   ; get new effect args
          ld (iy+fx_args),a             ; store
          ld a,(ix+2)                   ; get new effect number
          and $f                        ; store
          ld (iy+fx_number),a

          cp 3                          ; if fx = tone portamento (or tone portamento+volside)
          jp z,set_portadest            ; then period (if >0) goes to slide destination
          cp 5                          
          jr z,set_portadest

          cp $e                         ; check for e5 "fine tune override" command
          jr nz,no_ftoveride
          ld a,(iy+fx_args)
          and $f0
          cp $50
          jr nz,no_ftoveride
          ld a,(iy+fx_args)
          and $f
          ld (iy+finetune),a            ; overwrite instruments normal tuning value

no_ftoveride

          res 3,(iy+control_bits)       ; clear "new period" bit
          ld a,b                        ; bc = period
          or c                          ; if period = 0, dont write to frequency settings
          jr z,nonewp1

          set 3,(iy+control_bits)       ; allows ED command to know if a new period was specified   
          push bc
          ld (iy+arp_base_period_lo),c  ; store untuned version of note for arpeggio 
          ld (iy+arp_base_period_hi),b  ; which post converts to tuned values itself
          call finetune_bc_period
          ld (iy+period_for_fx_lo),c    ; store tuned version for other fx
          ld (iy+period_for_fx_hi),b
          pop bc
          
nonewp1   ld a,(iy+fx_number)
          cp $e                         ; if fx = $ed: delayed trig - dont trigger note now
          jr nz,not_ed                   
          ld a,(iy+fx_args)
          and $f0
          cp $d0
          jp z,check_more_fx
          
not_ed    ld a,b                        ; is a new period given?
          or c                          
          jr z,nonewp2
          ld c,(iy+period_for_fx_lo)    ; if so lock new period into actual playing freq 
          ld b,(iy+period_for_fx_hi)
          ld (iy+period_lo),c
          ld (iy+period_hi),b
          set 0,(iy+control_bits)       ; a new period always retriggers the note
          ld a,(iy+instrument_waiting)  
          or a
          jp z,check_more_fx
          jr do_vol                     ; update the volume too unless instrument is zero
          
nonewp2   ld a,(iy+instrument_waiting)  ; if there's a new instrument and its different
          or a                          ; to the current instrument, that'll also trigger the note
          jp z,check_more_fx
          cp (iy+instrument)                      
          jr z,do_vol
          set 0,(iy+control_bits)

do_vol    ld (iy+instrument),a
          ld a,(iy+volume_waiting)      ; new instrument = set volume 
          ld (iy+volume),a    
          ld (iy+volume_for_fx),a       ; lock in new instrument's volume
          jp check_more_fx
          

set_portadest

          ld a,b                        ; if period=0, dont change portamento destination
          or c                          
          jr z,spd_same                           
          call finetune_bc_period
          ld (iy+portamento_dest_lo),c  
          ld (iy+portamento_dest_hi),b
          
spd_same  ld a,(iy+instrument_waiting)  ; check for new instrument - if zero, no new volume or any trigger
          or a                          
          ret z
          cp (iy+instrument)            ; same instrument? if so, do not retrigger just reset volume
          jr z,skiptrig
          set 0,(iy+control_bits)       ; different instrument so set retrigger.
          ld (iy+instrument),a
skiptrig  ld a,(iy+volume_waiting)
          ld (iy+volume),a    
          ld (iy+volume_for_fx),a       
          ret
          


finetune_bc_period

          ld a,(iy+finetune)            ; nothing to do if finetune = 0 
          or a
          ret z
          sla a
          ld hl,tuning_table_list       
          ld e,a                        
          ld d,0
          add hl,de
          ld e,(hl)
          inc hl    
          ld d,(hl)                     ; de = start addr of relevent tuning table
          ld hl,period_lookup_table-113
          add hl,bc
          ld a,(hl)                     ; a = period index 0 - 36
          sla a
          add a,e
          jr nc,ttmok
          inc d
ttmok     ld e,a                        
          ex de,hl                      ; hl =addr of index in crrect tuing table
          ld c,(hl)
          inc hl
          ld b,(hl)                     ; bc = new tuned value
          ret
          
          
;-------- "FX during line" routines ---------------------------------------------------


not_new_line

          ld iy,channel_data            ; not a new line of notes so just update
          ld b,4                        ; any playing notes using the fx set up when
chanfxlp  push bc                       ; the line started (if channel is enabled.)
          call check_fx                 
          ld bc,vars_per_channel
          add iy,bc
          pop bc
          djnz chanfxlp

;--------- Finish up, update counters for next frame ---------------------------------
          
tick_advance

          ld hl,arpeggio_counter        ; arpeggio counter always cycles 0,1,2..0,1,2..
          inc (hl)
          ld a,(hl)
          cp 3
          jr nz,arp_ok
          ld (hl),0
arp_ok    
	  ld hl,ticker                  ; inc ticker
          inc (hl)
          ld a,(songspeed)    
          cp (hl)                       ; reached speed count?
          jr nz,nspwrap
          xor a
          ld (hl),a                     ; reset ticker                
          
	  ld b,0			; work around odd quirk, pattern delay causes pattern break to skip the target by 1 line
	  ld hl,pattdelay_count         ; any pattern delay? (from FX "EE" command)
          or (hl)
          jr z,nopatdel
          dec (hl)                      ; decrement delay and stay at same note if still > 0
          jr nz,nspwrap
	  inc b
	  
nopatdel  ld hl,patindex
	  ld a,(patt_break)		; if a pattern break (FX: "D") has been set, immediately go to next pattern and use the index supplied
          or a
	  jr z,nopbrk	  
	  add a,b			; add on pattern delay compensation
	  and $3f
	  ld (hl),a
	  xor a
	  ld (patt_break),a		; clear pattern break
	  jr npatset
	  
nopbrk	  inc (hl)                      ; next line in pattern 
          ld a,(hl)
          cp 64                         ; last line of pattern?
          jr nz,nspwrap
          xor a
	  ld (hl),a

npatset   xor a
	  ld (pattloop_pos),a           ; clear pattern loop pos (for "e6" command)
          ld (pattloop_count),a         ; clear pattern loop count "" ""
          
	  call pt_inc_songpos
nspwrap	  ret
	  
	  

	  
pt_inc_songpos
  
	  ld hl,songpos                 
          inc (hl)                      ; inc song position
          ld a,(max_pattern)
	  cp (hl)                       ; last song pos?
          ret nz

	  ld a,(pt_modtype)		; if mod type is Soundtracker, just set song pos to 0 (loop to back start).
	  or a				; (ID byte is BPM timing which isn't supported here)
	  jr z,pt_lpts

          ld de,(pt_pattsmax_loc)	; What's the loop byte?
	  inc de
	  call pt_read_module_byte
	  cp $7f			; $7f+ normally means stop playing tune, but we'll use it for wrap to start
	  jr nc,pt_lpts
	  ld (hl),a			; Otherwise assume it is a loop position
	  ret
	  
pt_lpts	  ld (hl),0
	  ret


;--------------------------------------------------------------------------------
; These fx are processed during the non-zero ticks of each line.   
;--------------------------------------------------------------------------------

check_fx  ld a,(pt_modtype)		
	  or a
	  jr nz,pt_ptfx
          ld a,(iy+fx_number)		; Soundtracker type FX
	  cp 1
	  jp z,arpeggio
	  cp 2
	  ret nz
	  ld b,0
	  ld a,(iy+fx_args)
	  and $f
	  ld c,a
	  jp nz,pt_pbup
	  ld a,(iy+fx_args)
	  rrca
	  rrca
	  rrca
	  rrca
	  and $f
	  ld c,a
	  jp pt_pbdown


pt_ptfx	  ld a,(iy+fx_number) 		; Protracker type FX
          or a                          
          jp z,arpeggio                 
          cp 1
          jp z,portamento_up
          cp 2
          jp z,portamento_down
          cp 3
          jp z,tone_portamento
          cp 4
          jp z,vibrato
          cp 5
          jp z,tone_portamento_volslide
          cp 6
          jp z,vibrato_volslide
          cp 7
          jp z,tremolo
          cp $a
          jp z,volslide
          cp $e
          jp z,extended_fx
          ret


check_more_fx

          ld a,(iy+fx_number)           ; effects called at the start of lines (tick 0)
          cp 9
          jp z,sample_offset
          cp $b                         
          jp z,position_jump
          cp $d
          jp z,pattern_break
          cp $e
          jp z,extended_fx
          cp $f
          jp z,set_speed
          cp $c
          jp z,set_volume
          ret
                    

;------- FX $00 -----------------------------------------------------------------------

arpeggio  ld a,(iy+fx_args)             ; dont do arpeggio if fx args = $00
          or a
          ret z
          ld c,(iy+arp_base_period_lo)  ; untuned "step 0" period of the arp chord
          ld b,(iy+arp_base_period_hi)
          ld a,(arpeggio_counter)       
          ld e,0
          or a      
          jr z,doarp                    
          cp 2
          jr z,arptwo
arpone    ld e,(iy+fx_args)
          srl e
          srl e
          srl e
          srl e                         ; E = "half-steps" to reach 2nd note of chord
          jr doarp
arptwo    ld a,(iy+fx_args)
          and 15
          ld e,a                        ; E = "half-steps" to reach 3rd note of chord     
doarp     ld hl,period_lookup_table-113
          add hl,bc
          ld a,(hl)                     ; note base
          add a,e                       ; add on arp offset
          sla a
          ld hl,period_table_p0
          add a,l
          jr nc,alumok
          inc h
alumok    ld l,a
          ld c,(hl)
          inc hl
          ld b,(hl)
          call finetune_bc_period
          ld (iy+period_lo),c
          ld (iy+period_hi),b
          ret


;-------- FX $01 ---------------------------------------------------------------------

portamento_up

          ld b,0                        ; subtract fx arg byte from period
          ld c,(iy+fx_args)             ; min value = 113
pt_pbup   ld l,(iy+period_for_fx_lo)
          ld h,(iy+period_for_fx_hi)
          xor a
          sbc hl,bc
          jr c,portumin
          or h
          jr nz,portugnp
          ld a,l
          cp 113
          jr nc,portugnp
portumin  ld hl,113
portugnp  ld (iy+period_for_fx_lo),l
          ld (iy+period_for_fx_hi),h
          ld (iy+period_lo),l
          ld (iy+period_hi),h
          ret

          
;--------- FX $02 -------------------------------------------------------------------

portamento_down                         

          ld b,0                        ; add fx arg byte to period
          ld c,(iy+fx_args)             ; max value = 907
pt_pbdown ld l,(iy+period_for_fx_lo)
          ld h,(iy+period_for_fx_hi)
          add hl,bc
          ld a,h
          cp 3
          jr c,portdgnp
          jr nz,portdmax
          ld a,l
          cp 139
          jr c,portdgnp
portdmax  ld hl,856
portdgnp  ld (iy+period_for_fx_lo),l
          ld (iy+period_for_fx_hi),h
          ld (iy+period_lo),l
          ld (iy+period_hi),h
          ret


;--------- FX $03 --------------------------------------------------------------------

tone_portamento

          ld c,(iy+portamento_rate)     ; if args = 0, use existing portamento rate
          ld a,(iy+fx_args)
          or a
          jr z,uexistpr
          ld c,a
          ld a,(iy+fx_number)
          cp 3                          ; only if fx = 3 set this as portamento rate
          jr nz,uexistpr
          ld (iy+portamento_rate),c     
uexistpr  ld e,(iy+portamento_dest_lo)  ; de = destination period
          ld d,(iy+portamento_dest_hi)
          ld l,(iy+period_for_fx_lo)    ; hl = current period
          ld h,(iy+period_for_fx_hi)
          xor a
          sbc hl,de                     ; compare hl / de
          ret z                         ; if same, nothing to do
          jr c,tp_peru                  ; if de is higher, period requires increasing

tp_perd   ld l,(iy+period_for_fx_lo)    ; decrease period by portamento rate
          ld h,(iy+period_for_fx_hi)
          ld b,0
          xor a
          sbc hl,bc                     ; subtact portamento rate from current period
          jr nc,tp_dnw                  ; make sure it hasnt been pulled below zero
          ld hl,0
tp_dnw    ld c,l                        ; store result in bc
          ld b,h
          xor a
          sbc hl,de                     ; compare with destination
          jr nc,chk_gliss
          ld c,e
          ld b,d
          jr tp_end                     ; if dest now bigger fix period at destination              

tp_peru   ld l,(iy+period_for_fx_lo)    ; increase period by portamento rate
          ld h,(iy+period_for_fx_hi)
          ld b,0
          add hl,bc
          ld c,l                        ; store result in bc
          ld b,h
          xor a
          sbc hl,de           
          jr c,chk_gliss
          ld c,e                        ; if destination is now smaller fix period at dest
          ld b,d
          jr tp_end 

chk_gliss bit 1,(iy+control_bits)       ; finally, check if glissando (step slide) is req'd 
          jr nz,do_gliss                
          
tp_end    ld (iy+period_for_fx_lo),c
          ld (iy+period_for_fx_hi),b
          ld (iy+period_lo),c 
          ld (iy+period_hi),b
          ret       
          
do_gliss  ld (iy+period_for_fx_lo),c    ; store updated "background" smooth slide
          ld (iy+period_for_fx_hi),b
          ld a,(iy+finetune)  
          sla a
          ld hl,tuning_table_list       
          ld e,a                        
          ld d,0
          add hl,de
          ld e,(hl)
          inc hl    
          ld d,(hl)                     ; de = start of relevent tuning table

          push ix
          push de
          pop ix
          xor a
          ld de,0                       ; divide period table into 3
          ld l,(ix+22)                  ; to save max search loop time
          ld h,(ix+23)
          sbc hl,bc
          jr z,tp_glend
          jr c,gltest
          ld de,24
          ld l,(ix+46)
          ld h,(ix+47)
          sbc hl,bc
          jr z,tp_glend
          jr c,gltest
          ld de,48

gltest    add ix,de
          ld d,b
          ld e,c
          xor a
          ld b,12
glissfper ld l,(ix)                     ; scan period table for nearest step
          ld h,(ix+1)
          sbc hl,de
          jr nc,nggliss
          ld c,(ix)
          ld b,(ix+1)
tp_glend  ld (iy+period_lo),c 
          ld (iy+period_hi),b
          pop ix
          ret

nggliss   inc ix
          inc ix
          djnz glissfper
          ld b,d
          ld c,e
          jr tp_glend


;--------- FX $04 -----------------------------------------------------------------

vibrato   ld b,(iy+vibrato_args)        ; get current args for vibrato effect
          ld a,(iy+fx_number)
          cp 4
          jr nz,vibrsame                ; only change args setting if fx_number = 4
          ld a,(iy+fx_args)
          or a
          jr z,vibrsame                 ; and then only if new args are not zero
          ld c,a
          and 15
          jr z,vibdsame                 ; if lower nyb = 0, dont change vibrato depth
          ld d,a
          ld a,b
          and $f0
          or d
          ld b,a                        ; update depth side of arg byte
vibdsame  ld a,c
          and $f0
          jr z,vibrsame                 ; if higher nyb = 0, dont change vibrato rate
          ld c,a
          ld a,b
          and $0f
          or c                          ; update the rate side of byte
          ld b,a                        
vibrsame  ld (iy+vibrato_args),b        ; fix settings as current
          
          ld c,(iy+vibrato_pos)
          srl c
          srl c
          ld a,c
          and $1f
          ld c,a                        ; c = step 0-31 in wave list
          ld a,(iy+wave_type) 
          and $f
          or a                          ; what type of wave is to used?
          jr z,vib_sine                 ; 0 = sine wave using lookup table
          sla c               
          sla c
          sla c                         ; multiply c by 8, now in range 0-248
          cp 1
          jr z,vib_ramp                 ; 1 = use c as a ramp type vibrato wave
          ld e,255                      
          jr vib_gotd                   ; else, use a square wave

vib_ramp  bit 7,(iy+vibrato_pos)        ;
          jr z,vibr2
          ld a,255
          sub c
          ld e,a
          jr vib_gotd
vibr2     ld e,c
          jr vib_gotd

vib_sine  ld hl,vibrato_table           ;get wave value from sine table
          ld b,0
          add hl,bc
          ld e,(hl)                     

vib_gotd  push ix
          ld a,(iy+vibrato_args)        
          cpl
          and $0f                       
          ld c,a                        ;get depth of effect in c (flipped for jump table)
          ld b,0                        
          ld d,b
          ld hl,vmul15
          add hl,bc
          push hl
          pop ix
          ld h,b
          ld l,b
          jp (ix)                       ; multiply wave value (de) by depth
vmul15    add hl,de                     ;+0 
vmul14    add hl,de                     ;+1
vmul13    add hl,de                     ;+2
vmul12    add hl,de                     ;+3
vmul11    add hl,de                     ;+4
vmul10    add hl,de                     ;+5
vmul9     add hl,de                     ;+6
vmul8     add hl,de                     ;+7
vmul7     add hl,de                     ;+8
vmul6     add hl,de                     ;+9
vmul5     add hl,de                     ;+10
vmul4     add hl,de                     ;+11
vmul3     add hl,de                     ;+12
vmul2     add hl,de                     ;+13
vmul1     add hl,de                     ;+14
vmul0     sla l                         ;15 - divide result in hl by 128
          rl h
          ld e,h
          ld d,0
          pop ix
          
          ld l,(iy+period_for_fx_lo)    ; normal "base" period
          ld h,(iy+period_for_fx_hi)
          bit 7,(iy+vibrato_pos)
          jr nz,vib_sub       
          add hl,de                     ; add on the displacement
          jr vib_pdone
vib_sub   xor a
          sbc hl,de                     ; subtract the displacement
vib_pdone ld (iy+period_lo),l
          ld (iy+period_hi),h

          ld b,(iy+vibrato_pos)         ; get the current vibrato index position
          ld a,(iy+vibrato_args)
          srl a
          srl a
          and $3c                       ; add on speed nybble arg * 4
          add a,b
          ld (iy+vibrato_pos),a         ; update vibrato index position
          ret


;-------- FX $05 -------------------------------------------------------------------
          
tone_portamento_volslide

          call tone_portamento
          jp volslide

          
;-------- FX $06 -------------------------------------------------------------------
          
vibrato_volslide    
          
          call vibrato
          jp volslide
          
          
;-------- FX $07 ------------------------------------------------------------------

tremolo   ld b,(iy+tremolo_args)        ; get current args for tremolo effect
          ld a,(iy+fx_args)
          or a
          jr z,trersame                 ; only change if new args are not zero
          ld c,a
          and 15
          jr z,tredsame                 ; if lower nyb = 0, dont change tremolo depth
          ld d,a
          ld a,b
          and $f0
          or d
          ld b,a                        ; update depth side of arg byte
tredsame  ld a,c
          and $f0
          jr z,trersame                 ; if higher nyb = 0, dont change tremolo rate
          ld c,a
          ld a,b
          and $0f
          or c                          ; update the rate side of byte
          ld b,a                        
trersame  ld (iy+tremolo_args),b        ; fix settings as current
          
          ld c,(iy+tremolo_pos)
          srl c
          srl c
          ld a,c
          and $1f
          ld c,a                        ; c = step 0-31 in wave list
          ld a,(iy+wave_type)           ; type of tremolo wave is in the upper 4 bits
          srl a
          srl a
          srl a
          srl a
          and $f                        ; what type of wave is to used?
          jr z,tre_sine                 ; 0 = sine wave using lookup table
          sla c               
          sla c
          sla c                         ; multiply c by 8, now in range 0-248
          cp 1
          jr z,tre_ramp                 ; 1 = use c as a ramp type tremolo wave
          ld e,255                      
          jr tre_gotd                   ; else, use a square wave

tre_ramp  bit 7,(iy+tremolo_pos)        ;
          jr z,trer2
          ld a,255
          sub c
          ld e,a
          jr tre_gotd
trer2     ld e,c
          jr tre_gotd

tre_sine  ld hl,vibrato_table           ;get wave value from sine table
          ld b,0
          add hl,bc
          ld e,(hl)                     

tre_gotd  push ix
          ld a,(iy+tremolo_args)        
          cpl
          and $0f                       
          ld c,a                        ;get depth of effect in c (flipped for jump table)
          ld b,0                        
          ld d,b
          ld hl,tmul15
          add hl,bc
          push hl
          pop ix
          ld h,b
          ld l,b
          jp (ix)                       ; multiply wave value (de) by depth
tmul15    add hl,de                     ;+0 
tmul14    add hl,de                     ;+1
tmul13    add hl,de                     ;+2
tmul12    add hl,de                     ;+3
tmul11    add hl,de                     ;+4
tmul10    add hl,de                     ;+5
tmul9     add hl,de                     ;+6
tmul8     add hl,de                     ;+7
tmul7     add hl,de                     ;+8
tmul6     add hl,de                     ;+9
tmul5     add hl,de                     ;+10
tmul4     add hl,de                     ;+11
tmul3     add hl,de                     ;+12
tmul2     add hl,de                     ;+13
tmul1     add hl,de                     ;+14
tmul0     sla l                         ;+15 - divide result in hl by 64
          rl h
          sla l
          rl h
          ld l,h
          pop ix
          
tshftl    ld a,(iy+volume_for_fx)       ; normal "base" volume
          bit 7,(iy+tremolo_pos)
          jr nz,tre_sub       
          add a,l                       ; add on the displacement
          cp 64
          jr c,tre_done
          ld a,64
          jr tre_done
tre_sub   sub l                         ; subtract the displacement
          jr nc,tre_done
          xor a
tre_done  ld (iy+volume),a
          
          ld b,(iy+tremolo_pos)         ; get the current tremolo index position
          ld a,(iy+tremolo_args)
          srl a
          srl a
          and $3c                       ; add on speed nybble arg * 4
          add a,b
          ld (iy+tremolo_pos),a         ; update tremolo index position
          ret

;-------- FX $09 -------------------------------------------------------------------

sample_offset

          ld a,(iy+fx_args)             
          or a
          jr z,usexoffs                 ; use existing offset if args = 0
          ld b,a
          ld c,0
          srl b
          rr c                          ; bc = offset in words
          ld (iy+samp_offset_lo),c
          ld (iy+samp_offset_hi),b
          
usexoffs  ld c,(iy+samp_offset_lo)      ; check if offset is larger than length of sample
          ld b,(iy+samp_offset_hi)
          ld l,(iy+samp_len_lo)
          ld h,(iy+samp_len_hi)
          xor a
          sbc hl,bc
          jr z,soffbad
          jr c,soffbad
          ld (iy+samp_len_lo),l         ; adjust the length of the sample
          ld (iy+samp_len_hi),h
          
          ld l,(iy+samp_loc_00)
          ld h,(iy+samp_loc_01)
          ld a,(iy+samp_loc_02)
          add hl,bc
          adc a,0
          add hl,bc
          adc a,0
          ld (iy+samp_loc_00),l         ; adjust the start position of the sample
          ld (iy+samp_loc_01),h
          ld (iy+samp_loc_02),a
          ret

soffbad   ld (iy+samp_len_lo),1         ; if offset is too high, just set the sample 
          ld (iy+samp_len_hi),0         ; length at 1
          ret
          

;-------- FX $0A -----------------------------------------------------------------------


volslide  ld a,(iy+fx_args)             ; sub lower nybble of fx args from volume         
          ld b,a
          rrca
	  rrca
	  rrca
	  rrca
	  and 15                        
          jr nz,volup
          
	  ld a,b
	  and $f
	  ld b,a
	  ld a,(iy+volume)		; sub lower nybble from fx args from volume
          sub b
          jr nc,voldok
          xor a
voldok    ld (iy+volume),a
          ret

volup     add a,(iy+volume)		; or add higher nybble of fx args to volume
          cp 64
          jr c,voluok
          ld a,64
voluok    ld (iy+volume),a
          ret


;-------- FX $0B -------------------------------------------------------------------

position_jump

          ld a,(iy+fx_args)
          ld (songpos),a		; select position in song to go to after this line
          ld a,255
          ld (patindex),a		; the end-of-line index inc will wrap this to 0
          ret


;-------- FX $0C -------------------------------------------------------------------

set_volume
          
          ld a,(iy+fx_args)
          cp $40
          jr c,vsetok
          ld a,$40
vsetok    ld (iy+volume),a
          ld (iy+volume_waiting),a
          ret


;-------- FX $0D -------------------------------------------------------------------

pattern_break
          
          ld a,(iy+fx_args)
          and $0f
	  ld b,a
	  ld a,(iy+fx_args)
	  and $f0				;new index = (upper nybble * 10) + lower nyble
	  rrca
	  ld c,a
	  rrca
	  rrca
	  add a,c
	  add a,b
	  and $3f
          or $80				;set bit 7 as "Patt Break is set" flag
	  ld (patt_break),a
          ret
 
          
;-------- FX $0E --------------------------------------------------------------------


extended_fx

          ld a,(iy+fx_args)			
          ld b,a
          and $f0
          cp $00
          jr z,e0_filter
          cp $10
          jr z,e1_fineport_up
          cp $20
          jr z,e2_fineport_down
          cp $30
          jp z,e3_glissando_control
          cp $40
          jp z,e4_vibrato_control
          cp $50
          jp z,e5_finetune_control
          cp $60
          jp z,e6_pattern_loop
          cp $70
          jp z,e7_tremolo_control
          cp $90
          jp z,e9_retrigger_note
          cp $a0
          jp z,ea_finevol_up
          cp $b0
          jp z,eb_finevol_down
          cp $c0
          jp z,ec_cutnote
          cp $d0
          jp z,ed_delayedtrig
          cp $e0
          jp z,ee_pattdelay
          ret



testtick0 ld a,(ticker)
          or a
          ret



e0_filter
	  call testtick0		; effect is only active on tick 0	
          ret nz
	  ld a,b                        ; set sound filter on or off
          and $01                       
          ld (filter_on_off),a
          ret
          

e1_fineport_up

          call testtick0		; effect is only active on tick 0
          ret nz
          ld b,0                        ; subtract fx arg lo nyb from period, once only
          ld a,(iy+fx_args)             
          and $0f
          ld c,a
          ld l,(iy+period_lo)
          ld h,(iy+period_hi)
          xor a
          sbc hl,bc
          jr c,fportumin
          or h
          jr nz,fportugnp
          ld a,l
          cp 113
          jr nc,fportugnp
fportumin ld hl,113                     ; min period = 113
fportugnp ld (iy+period_lo),l
          ld (iy+period_hi),h
          ret


e2_fineport_down
          
          call testtick0		; effect is only active on tick 0
          ret nz
          ld b,0                        ; add fx arg low nyb to period, once only
          ld a,(iy+fx_args)             
          and $0f
          ld c,a
          ld l,(iy+period_lo)
          ld h,(iy+period_hi)
          add hl,bc
          ld a,h
          cp 3
          jr c,fportdgnp
          jr nz,fportdmax
          ld a,l
          cp 88
          jr c,fportdgnp
fportdmax ld hl,856                     ; max period = 856
fportdgnp ld (iy+period_lo),l
          ld (iy+period_hi),h
          ret


e3_glissando_control

          res 1,(iy+control_bits)
          ld a,b
          and $1
          ret z
          set 1,(iy+control_bits)
          ret


e4_vibrato_control
          
          ld a,b
          and $07
          ld b,a
          ld a,(iy+wave_type)
          and $f0
          or b
          ld (iy+wave_type),a
          ret


e5_finetune_control
          
          ld a,b                        ; override the finetune value of this instrument
          and $0f                       
          ld (iy+finetune),a
          ret


e6_pattern_loop

          call testtick0		; effect is only active on tick 0
          ret nz
          ld a,b
          and $0f
          jr z,setplp
          ld hl,pattloop_count
          inc (hl)
          cp (hl)
          jr c,plp_end
          ld a,(pattloop_pos)           ;jump back to previously stored position
          dec a                         ;compensate for normal increment
          ld (patindex),a
          ret
plp_end   xor a                         
          ld (pattloop_count),a         ;loop count maxed, continue with pattern
          ret
setplp    ld a,(patindex)               ;set pattern loop jump back position
          ld (pattloop_pos),a
          ret
          

e7_tremolo_control
          
          ld a,b
          and $07
          ld b,a
          sla b
          sla b
          sla b
          sla b
          ld a,(iy+wave_type)
          and $0f
          or b
          ld (iy+wave_type),a
          ret
          

e9_retrigger_note

          ld a,b
          and $0f
          ret z
          ld b,a
          call testtick0
          jr z,retrigit
rtloop    sub b
          jr z,retrigit
          jr nc,rtloop
          ret
retrigit  set 0,(iy+control_bits)
          ret
          


ea_finevol_up

          call testtick0			; effect is only active on tick 0
          ret nz
          ld a,b
          and $0f
          add a,(iy+volume)
          cp 64
          jr c,eavolok
          ld a,64
eavolok   ld (iy+volume),a
          ret
          

eb_finevol_down
                    
          call testtick0			; effect is only active on tick 0
          ret nz
          ld a,b
          and $0f
          ld b,a
          ld a,(iy+volume)
          sub b
          jr nc,ebvolok
          xor a
ebvolok   ld (iy+volume),a
          ret


ec_cutnote

          ld a,b
          and $f
          ld b,a
          ld a,(ticker)
          cp b
          ret nz
          xor a
          ld (iy+volume),a
          ret
          


          
ed_delayedtrig      
          
          ld a,b
          and $f
          ld b,a
          ld a,(ticker)
          cp b
          ret nz
          
          bit 3,(iy+control_bits)       ; was a new period specifed?
          jr z,ed_nonewp2
          ld c,(iy+period_for_fx_lo)    ; if so lock new period into actual playing freq 
          ld b,(iy+period_for_fx_hi)
          ld (iy+period_lo),c
          ld (iy+period_hi),b
          set 0,(iy+control_bits)       ; a new period always retriggers the note
          ld a,(iy+instrument_waiting)  
          or a
          ret z
          jr ed_do_vol                  ; update the volume too unless instrument is zero
          
ed_nonewp2

          ld a,(iy+instrument_waiting)  ; if there's a new instrument and its different
          or a                          ; to the current instrument, that'll also trigger the note
          ret z
          cp (iy+instrument)                      
          jr z,ed_do_vol
          set 0,(iy+control_bits)

ed_do_vol ld (iy+instrument),a
          ld a,(iy+volume_waiting)      ; new instrument = set volume 
          ld (iy+volume),a    
          ld (iy+volume_for_fx),a       ; lock in new instrument's volume
          ret



          
ee_pattdelay
	  
 
	  call testtick0		; effect is only active on tick 0
	  ret nz
	  ld a,(pattdelay_count)
	  or a
	  ret nz
	  ld a,b
          and $f
          ld (pattdelay_count),a
          ret
          


;-------- FX $0F -------------------------------------------------------------------

set_speed
          ld a,(iy+fx_args)
          cp 32				; ignore if > 31 (a BPM value which isn't supported here)
	  ret nc
	  ld (songspeed),a
          ret


;---- Amiga Period List ------------------------------------------------------------

period_lookup_table 

                    DB 35,0,0,0,0,0,0,34,0,0,0,0,0,0,33,0
                    DB 0,0,0,0,0,0,32,0,0,0,0,0,0,0,31,0
                    DB 0,0,0,0,0,0,30,0,0,0,0,0,0,0,0,29
                    DB 0,0,0,0,0,0,0,0,0,28,0,0,0,0,0,0
                    DB 0,0,0,27,0,0,0,0,0,0,0,0,0,26,0,0
                    DB 0,0,0,0,0,0,0,0,0,25,0,0,0,0,0,0
                    DB 0,0,0,0,0,24,0,0,0,0,0,0,0,0,0,0
                    DB 0,23,0,0,0,0,0,0,0,0,0,0,0,0,0,22
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,21,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,20,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,19,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,18,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,17
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,16,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,15,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,14,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,13,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,11,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,6,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0      
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
                    DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


tuning_table_list   dw period_table_p0
                    dw period_table_p1
                    dw period_table_p2
                    dw period_table_p3
                    dw period_table_p4
                    dw period_table_p5
                    dw period_table_p6
                    dw period_table_p7
                    dw period_table_m8
                    dw period_table_m7
                    dw period_table_m6
                    dw period_table_m5
                    dw period_table_m4
                    dw period_table_m3
                    dw period_table_m2
                    dw period_table_m1
                    

period_table_p0     dw 856,808,762,720,678,640,604,570,538,508,480,453
                    dw 428,404,381,360,339,320,302,285,269,254,240,226
                    dw 214,202,190,180,170,160,151,143,135,127,120,113

period_table_p1     dw 850,802,757,715,674,637,601,567,535,505,477,450
                    dw 425,401,379,357,337,318,300,284,268,253,239,225
                    dw 213,201,189,179,169,159,150,142,134,126,119,113

period_table_p2     dw 844,796,752,709,670,632,597,563,532,502,474,447
                    dw 422,398,376,355,335,316,298,282,266,251,237,224
                    dw 211,199,188,177,167,158,149,141,133,125,118,112

period_table_p3     dw 838,791,746,704,665,628,592,559,528,498,470,444
                    dw 419,395,373,352,332,314,296,280,264,249,235,222
                    dw 209,198,187,176,166,157,148,140,132,125,118,111

period_table_p4     dw 832,785,741,699,660,623,588,555,524,495,467,441
                    dw 416,392,370,350,330,312,294,278,262,247,233,220
                    dw 208,196,185,175,165,156,147,139,131,124,117,110

period_table_p5     dw 826,779,736,694,655,619,584,551,520,491,463,437
                    dw 413,390,368,347,328,309,292,276,260,245,232,219
                    dw 206,195,184,174,164,155,146,138,130,123,116,109

period_table_p6     dw 820,774,730,689,651,614,580,547,516,487,460,434
                    dw 410,387,365,345,325,307,290,274,258,244,230,217
                    dw 205,193,183,172,163,154,145,137,129,122,115,109

period_table_p7     dw 814,768,725,684,646,610,575,543,513,484,457,431
                    dw 407,384,363,342,323,305,288,272,256,242,228,216
                    dw 204,192,181,171,161,152,144,136,128,121,114,108

period_table_m8     dw 907,856,808,762,720,678,640,604,570,538,508,480
                    dw 453,428,404,381,360,339,320,302,285,269,254,240
                    dw 226,214,202,190,180,170,160,151,143,135,127,120

period_table_m7     dw 900,850,802,757,715,675,636,601,567,535,505,477
                    dw 450,425,401,379,357,337,318,300,284,268,253,238
                    dw 225,212,200,189,179,169,159,150,142,134,126,119

period_table_m6     dw 894,844,796,752,709,670,632,597,563,532,502,474
                    dw 447,422,398,376,355,335,316,298,282,266,251,237
                    dw 223,211,199,188,177,167,158,149,141,133,125,118

period_table_m5     dw 887,838,791,746,704,665,628,592,559,528,498,470
                    dw 444,419,395,373,352,332,314,296,280,264,249,235
                    dw 222,209,198,187,176,166,157,148,140,132,125,118

period_table_m4     dw 881,832,785,741,699,660,623,588,555,524,494,467
                    dw 441,416,392,370,350,330,312,294,278,262,247,233
                    dw 220,208,196,185,175,165,156,147,139,131,123,117

period_table_m3     dw 875,826,779,736,694,655,619,584,551,520,491,463
                    dw 437,413,390,368,347,328,309,292,276,260,245,232
                    dw 219,206,195,184,174,164,155,146,138,130,123,116

period_table_m2     dw 868,820,774,730,689,651,614,580,547,516,487,460
                    dw 434,410,387,365,345,325,307,290,274,258,244,230
                    dw 217,205,193,183,172,163,154,145,137,129,122,115

period_table_m1     dw 862,814,768,725,684,646,610,575,543,513,484,457
                    dw 431,407,384,363,342,323,305,288,272,256,242,228
                    dw 216,203,192,181,171,161,152,144,136,128,121,114

;----- Vibrato sine wave -----------------------------------------------------------

vibrato_table       db 000,024,049,074,097,120,141,161
                    db 180,197,212,224,235,244,250,253
                    db 255,253,250,244,235,224,212,197
                    db 180,161,141,120,097,074,049,024

;-----------------------------------------------------------------------------------

pt_idlist		db 1,"M.K."	; will attempt to play mods with these IDs (as well as the no-ID Sountracker)
			db 2,"FLT4"
			db 3,"N.T."
			db 0		; Last entry
			
pt_modtype		db 0		; As from list above (0=Soundtracker: 15 samples)
pt_pattsmax_loc		dw 0		; Offset from start of module to "number of patterns" 
pt_patterns_loc		dw 0		; Offset from start of module to pattern data

;-----------------------------------------------------------------------------------


force_sample_base	db $01,$00,$00      ; if bit 0 is set, samples just follow song data

pt_sample_data_list	ds 31*11,0

pt_sampdata_loc		equ 0  ; (3 bytes)
pt_sampdata_len		equ 3  ; (2 bytes)
pt_sampdata_ft		equ 5  ; (1 btyte)
pt_sampdata_vol		equ 6  ; (1 byte)
pt_sampdata_loopoffset	equ 7  ; (2 bytes)
pt_sampdata_looplen	equ 9  ; (2 bytes)

;-----------------------------------------------------------------------------------

ticker              	db 0
songpos             	db 0
patindex            	db 0
songspeed          	db 0
arpeggio_counter    	db 0
pattloop_pos        	db 0
pattloop_count      	db 0
pattdelay_count     	db 0
filter_on_off       	db 0
max_pattern		db 0
patt_break		db 0

;-----------------------------------------------------------------------------------

pt_note_row		ds 16,0

;-----------------------------------------------------------------------------------

vars_per_channel    equ 35

channel_data        ds vars_per_channel*4,0
          
instrument          equ 0
period_lo           equ 1
period_hi           equ 2
volume              equ 3
fx_number           equ 4
fx_args             equ 5
period_for_fx_lo    equ 6
period_for_fx_hi    equ 7
volume_for_fx       equ 8
portamento_rate     equ 9
vibrato_args        equ 10
vibrato_pos         equ 11
tremolo_args        equ 12
tremolo_pos         equ 13
wave_type           equ 14              ;bits 7:4 = tremolo / bits 0:3 = vibrato
control_bits        equ 15              ;bit 0 = note triggered, 1 = glissando on/off 
portamento_dest_lo  equ 16              ;bit 2 = channel muted, bit 3 = there was a new period specified (for cmd ed)
portamento_dest_hi  equ 17
instrument_waiting  equ 18
volume_waiting      equ 19
finetune            equ 20
arp_base_period_lo  equ 21
arp_base_period_hi  equ 22

samp_loc_00         equ 23
samp_loc_01         equ 24
samp_loc_02         equ 25
samp_len_lo         equ 26
samp_len_hi         equ 27
samp_loop_loc_00    equ 28
samp_loop_loc_01    equ 29
samp_loop_loc_02    equ 30
samp_loop_len_lo    equ 31
samp_loop_len_hi    equ 32
samp_offset_lo      equ 33
samp_offset_hi      equ 34

;========================================================================================
; End of generic Z80 moplayer. 
;========================================================================================
