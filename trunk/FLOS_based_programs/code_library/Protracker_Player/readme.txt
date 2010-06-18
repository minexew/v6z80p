50Hz_60Hz_Protracker_code_v513.asm


Notes:
------

The whole Protracker module can be loaded into sample RAM (system RAM $20000-$3FFFF)
or the samples can be split from the pattern data (there is a PC app to do so in the
PC_based_apps folder). In both cases the replay routine must be in the same bank as
the pattern data (unless the replay code is located below $8000 - and then the 
bank just needs to set for the pattern data).

If the module is split, the samples can be positioned anywhere IN SAMPLE RAM (a
variable is set to point to the sample origin - see below)


 

Labels required:
----------------

"music_module" = Z80 address location of Protracker module (pattern data) this must
be located at a word address boundary.

"force_sample_base" (optional) - If the samples have been split from the pattern
data, write the location of the samples IN WORDS from the start of sample RAM to
this variable before initializing song. (Otherwise ignore it, or write with $FFFF). 


Calls:
------

"init_tracker" - call once to set the tune to start point.

"play_tracker" - call each frame to process tune
"update_sound_hardware" - call each frame to update OSCA hardware registers


** WARNING! **

The routine "update_sound_hardware.asm" routine uses the first entry in the
maths assist mult_table, so this should be restored manually by user's program
if used for other purposes (remember, the mult_table is write only)
