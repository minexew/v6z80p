
Notes for latest version: Protracker_code_v515.asm  (Requires OSCA672+)
-----------------------------------------------------------------------

(See source code for full info).

Module size limitations have been removed in this version. If the module is in
banked memory (IE: outside the first 64KB of system RAM) the replay routine must be
in unpaged memory.
 
To use, include "osca_modplay_v515.asm" into the source of you app (this contains
an include for the generic Z80 portion of the code).


Labels required:
----------------

"pt_module_loc_lo" WORD [address of module bits 15:0]
"pt_module_loc_hi" BYTE [address of module bits 23:16]

These specify the location of the Protracker module in system RAM - Modules must be
located at a word address boundary.


Calls:
------

"pt_init" - call once to set the tune to start point.

"osca_play_tracker" - call each frame to process the tune and update the OSCA sound hardware

  The "osca_play_tracker" routine automatically detects the frame rate and skips regualar
  updates if 60HZ is detected (to approximate 50Hz timing) . If this feature is not required
  (EG: Using timer interrupts) call "pt_play" then "osca_update_audio_hardware" every
  update cycle instead.

"pt_set_sample_base" - Optional: If the samples have been split from the pattern data, put
the system RAM location of the start of sample data in A:HL and call this routine
before "pt_init"


**************
** WARNING! **
**************

The routine "update_sound_hardware.asm" routine uses the first entry in the
maths assist mult_table, so this should be restored manually by user's program
if used for other purposes (remember, the mult_table is write only)

