CPM 3 for V6Z80P
How to use this:

1. Unzip all files onto an SD card 
2. Put the card into the V6Z80P
3. Start the V6Z80p; have a keyboard and screen connected
4. under FLos: type <formatc> ; follow directions on the screen; 
   this will make four CP-M "disks"A:,B:,C: and D: of 8 Mb each on the SDcard
5. If not already connected: connect the V6Z80P to your PC using the serial cable
6. start your terminal emulation (choose VT52 if possible for using Wordstar) on the PC; I use ZOC, to be found on the net
7. under FLOS: type <initcpm> 
8. This will copy the necessary file CCP.COM and other CP-M files to CP-M disk A:
9. It shows the progress on your terminal screen
10. When finished you will see the A> prompt. Type <dir> on the keyboard of your terminal (emulator)
11. If the V6Z80P has been switched off or reset, type <startcpm> under Flos; this avoids copying all files again,
	(this does no harm, but takes time)

12. startcpm loads CPM3.SYS and starts CP/M. CP/M then loads CCP.COM and waits for user input.
I could have put this all together in one startup program, but wanted to stay close to the original.

Just a few basic things about CP/M:
- built-in commands: 
	DIR: obvious
	DIRSYS; id for system files
	ERASE: obvious
	RENAME newname=oldname
	TYPE: lists contents to the screen
	USER: sets the user number (0-16); files are linked to a user so will not show up after a change
- to exit a program: type CTRL-C (in most cases)
- to change drives: type A:, B: like in MSDOS
- to copy files from f.i. A: to B: type: b:=PIP filename.ext
- to copy and rename: b:newname.ext=pip filename.ext
- you may use wildcards as in MSDOS
- programs start at 100H 
- The upper boundary for programs can be found at 0006H 

- 0-100H is reserved area, but you may implement an nmi vector and maybe others

The program BOOTFLOS.COM restarts the V6Z80P

I have included a copy of the CP/M manuals 

I will make a program that can copy files of your choice to the CP/M disks. For the moment 
you have to make do with the fixed list of INITCPM.

I will also upload the source files, after I have made a mark-up where they differ from the CP/M originals 

