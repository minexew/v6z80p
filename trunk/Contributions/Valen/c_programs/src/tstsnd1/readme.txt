Example: How to use fx_player code from C program.
(fx_player was coded in asm by Phil)
=================================================================


How to run
==========
Upload to the V6 two files:
- .exe file
- .sam file (samples)
(Samples file is tstsnd1\fx_player\demo_data\my_fx1.sam)

The .dat file binary content is included in executable.
(see fx_player_code.asm)


Overview
========
To use fx_player in your program, you need to have 2 files:
.dat - FX data, contain sounds descriptors
.sam - all used samples, contain all samples used in your project

This two files can be produced by FXEDITOR.EXE tool. Check the docs how
to use it. 
(fxeditor is in dir FLOS_based_programs\tools\sfx_editor\)

After you produce .sam and .dat files you should:
- load .dat file to system memory
- load .sam to audio memory
Then you can use fx_player calls.


You should reserve a system memory, in your program, for fx_player code
and .dat file:
- fx_player code (about 1,7KB)
- .dat file (typically .dat file will be up to 1KB)
Thus, you will need about 2,7 KB of system memory. If you have that
amount of system memory, you can not use any banking code (to simplify
your program).
