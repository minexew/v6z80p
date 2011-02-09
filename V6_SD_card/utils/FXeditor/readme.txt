FXEDITOR.EXE

A multi-channel sound FX editor / player - by Phil Ruston 2010
--------------------------------------------------------------

This util allows the creation of multi-channel sound effects for
use in the user's own programs.


Changes:
--------

0.24 - Improved text input in script Editor.
     - Fixed error reporting in script editor.

0.23 - Added standard file requesters for LOAD / SAVE
     - Press space to silence all channels (no longer L-shift)
     - Changing the sample whilst preview mode is on now plays new sound



Effect creation method - overview:
----------------------------------

Sound samples are loaded, clips are made from the samples (adjustments
to start/stop, period and loop positions) then these clips are
assigned independantly to 1 - 4 sound channels to make a sound
effect. Each effect has its own priority level and its clips
can optionally use a script to dynamically adjust the sound as
it plays.


Controls:
---------

Shift+F1 - FX Edit page - where clips are assigned to channels.

Shift+F2 - Clip creation page - where clips are made from samples.

Shift+F3 - Script editor page - to type out / edit scripts.

Shift+F4 - Sample loader page - load in .wav files to the 32 slots.

Shift+F5 - Project file page - Load and Save currrent Project, and save
           final optimized files for user's own program.
           
Tab / Up / Down arrow - cycle through data input points on
           the current page.

+/-	- Increment / decrement current numeric data point value

Enter     - Type a new value / string at current data input point.
            Or if current highlighted point is a button - activate it.

ESC       - Exit program / finish editing current script 

DEL       - (In script editor) Erase current line 

CTRL      - Hear current FX (as selected on first page)

Shift     - Silence.

 
FX Edit (Top Level Page) - shift+f1
-----------------------------------

Once you have loaded some samples and assigned clips to them you can
insert the clip numbers to play on each channel as required here.
When you set a clip, its initial volume should be set (this is
in the range 0-FF, the software scales it to the value required
by the hardware). Additionally you can add a script number if
required.

In this program an individual Sound Effect (FX) is defined as the 1
to 4 clips set to play on the channels (with their associated volumes
and scripts) as set on this page.

Each FX has a priority value and priority-active-time value. These
parameters allow important FX (EG: explosions) to override less
important ones (EG: gunshots) but not vice versa. The higher
the priority value, the more precedent it has. The Time value
specifies how long the priority matters (it counts in frames).
Once the timer has counted down to zero, the FX has zero
priority.

The priority system does NOT have to be used, especially if clips
are assigned to different channels under different FX (EG: FX 1:
explosion on channel 0, FX 2:  gunshot on channel 1) - in this
case the clips will play simultaneously.


Clip Creation Page - shift+f2
-----------------------------

Once any sample has been loaded, you need to make at least one
clip from it for it to be of use. Selecting a clip shows the sample
current assigned to it. When you change the sample number assigned
to a clip the sample's default location/loop/period information
is copied to the clip but this page lets you change the values
for each clip (you can make multiple clips from each sample).
For the most basic use, you'd just assign sample 1 to clip 1,
sample 2 to clip 2, sample 3 to clip 3 etc and make no other
changes.

If you set "Preview" to "Y" the clip (not the FX) will play
repeatedly (if looped) or once every time a parameter is changed
(if unlooped).


Script Editor Page - shift+f3
-----------------------------

Scripts allow the parameters of a clip to be changed as it plays,
(volume, period, etc) which is useful for synthetic sounds.
Scripts are entered in pseudo-English, and compiled by the
editor. Note that changes to scripts do not take effect
until the script editing has finished (pressed ESC). Basic
syntax checking is performed by the compiler.

Script Command list:
-------------------

SETVOL [byte]

 Forces the volume of the clip to a set level.

ADDVOL [byte]

 Adds a value to the clip's volume (maxes out at $FF)

SUBVOL [byte]

 Subtracts a value from the clip's volume (stops at 0)

SETPER [word]

 Sets the clip's period to a certain value

ADDPER [word]

 Adds a value to the clip's period (see PERCYC, PERMIN, PERMAX
 for more info)

SUBPER [word]

 Subtracts a value from the clip's period (see PERCYC, PERMIN, PERMAX
 for more info)

MAXPER [word]

 Imposes a maximum period limit for ADDPER (see PERCYC for more info)

MINPER [word]

 Imposes a minimum period limit for MINPER (see PERCYC for more info)

RNDPER [word]

 Sets the period to a random value. The argument is an AND mask
 for 16-bit random value. The value written to the period port
 is (the random value AND the argument supplied) + MINPER Value.

SETRND [word]

 Sets the random number generator's seed value.

WAIT [byte]

 Waits a number of frames. All scripts containing loops require
 a WAIT instruction, otherwise the script will run in a tight loop
 and take a lot of CPU time. 

LOOP [byte]

 Sets a loop position, with argument being the number of loops
 required.

GOLOOP [no args]

 Jump back to the loop position.

REPEAT [no args]

 Set a repeat point. This point is returned to when DONE is reached.
 (there should a maximum of one REPEAT per script). 

DONE [no args]

 Ends the script or jumps back to the REPEAT point. All scripts
 must end with a DONE command. If there is no WAIT between REPEAT
 and DONE, the script is terminated (as this would otherwise
 lock up the player routine in an endloop cycle).
 
CLIP [byte]

 Starts a new sound clip playing on the current channel. 

PERCYC [byte]

 Dictates what happens when the minimum or maximum period is reached
 by the MINPER or MAXPER commands.
 
  0 - Period is fixed at the minimum / maximum value (default)
  1 - Period loops around to the absolute minimum / maximum value.
  2 - Period loops around to minimum / maximum value with an
     offset equal to the amount the period over/underflowed.
     


Sample loader Page
------------------

Select a slot, press Enter and use requester to locate a .wav
file. Only 8-bit, mono, unsigned, unpacked .wav files less than
32KB long are accepted (they're converted to the signed values
that the OSCA hardware requires by the editor software)


Disk I/O - Load and Save currrent Project, and save optimized
-------------------------------------------------------------

Loads / Save a "Project file": Use this for works in progress
as Project Files include everything currently in the editor.
(Select the LOAD or SAVE button and press Enter).

Save Optimized Files: This option detects which FX, Clips,
Scripts and Samples are actually in use and only saves
the data necessary for an external program to play the
defined FX. Two files are saved, the FX data (normally with
a .dat extension) and Samples (same filename but with .sam
extension).


How to use optimized files in user program
------------------------------------------

The user program should include the source "fx_player.asm" this code
references the label "fx_data" so your program should incbin
the optimized fx data file at that location. EG: it can contain
the lines:

	include "fx_player.asm"
fx_data	incbin  "my_fx1.dat"

The sample file (*.sam) needs be positioned into the start of the 
sample RAM (system RAM $20000-$3ffff).  If the file is small
it can also be incbin'd into the body of the user program and
moved for example with an LDIR and use of the "sys_alt_write_page"
port. If it is large, then the user program can load it from disk
direct to sample RAM using the Kernal load routines.

The user program should call:

"new_fx" with the new FX to play in A when a new effect needs
to be triggered. (Any important registers should be PUSH/POP'd
around the call by the user program.)

(The routine "silence_fx" can be called to clear all sound output.)

On each frame, call:

"play_fx" to update the registers.


