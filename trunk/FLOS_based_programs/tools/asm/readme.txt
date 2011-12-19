ASM.EXE by Phil Ruston - A native Z80 assembler for FLOS
--------------------------------------------------------

V0.01 

Usage:

ASM source_filename [%include assigned dir #1] [%include assigned dir #2] etc

A binary file is produced with the same filename but with extension ".exe"


Directives supported:
---------------------

ORG	- set code assembly location
INCLUDE	- include a source file at current location
INCBIN	- include a binary file at current location
DB	- data byte(s) EG: 'DB 1,2,3,some_symbol' , 'DB "string1"' or mixed
DW	- data word(s)
DS	- data string (EG: "DS 10,5" (enters 10 bytes, each with value 5))
EQU	- set value of a symbol, (EG: "my_symbol equ $1234")



General:
--------

* Only the official Z80 opcodes are currently allowed.

* There are no macros or conditional assembly directives.

* Line labels must be aligned to the left margin

* A tab or space must exist before opcodes or instructions such as INCBIN, ORG etc.

* Comments should begin with a semi-colon 
	
* Lines can be a maximum of 255 characters long



Numbers/Maths/expressions:
--------------------------
	
* Operators supported: "+", "-", "/", "*", ">>", "<<", "&" (and), "|" (or) 
	
* Bases: Unprefixed figure = decimal, $[value] = hex, %[value] = binary, quoted "n" or 'n' = ASCII
	
* "$" (alone) = Special case: Current opcode address, allowing "$+2", "$-2" etc references.
  (Page alignment can be achieved with org $+255&$ff00)

* The maths system internally uses 16-bit integers, therefore no part of an expression can be
  greater than 65535. 8-bit values derived from 16-bit can be in range -128 to 255) without
  returning errors.
	
* A sign prefix can be specified: EG "+1", "-5"

* Brackets can be used in expressions. The assembler scans the expression left to right
  solving the first innermost bracketed section it finds, until all bracketed sections have
  been resolved.



 Labels / Symbols / Strings
----------------------------

* ORG using symbols: The symbol cannot be a forward reference (IE: Must be defined prior to the ORG directive.)
	
* ORG cannot specify an address lower than the current assembly location. If not ORG exists, assembly starts at 0.
	
* Instructions/symbols/etc are NOT case sensitive

* Includes can be nested, to a maximum of 8 levels

* Line labels can end in colons if desired (will be ignored)
		
* Symbol table is limited to approx 32KB max.	
	
* When using strings with DB directive, the quote character (CHR $22) cannot be within the string,
  it must be declared separately as a byte: EG: DB $22,"Hello",$22," said Bob." (Apostropes (')
  can be within strings.)

* All symbols/labels are global.



Files:	
------


* There is no restriction on the length of source .asm files
	
* Max incbin filesize = 64KB
		
* Output file starts from the lowest defined address (where data has been placed) 64KB max.

* No paths permitted in filenames however, the directories that should be scanned for
  component files can be specified on the command line via FLOS directory assignments,
  EG: "ASM MY_PROJ.ASM %INC %DAT"
  
* Any quotes around filenames are ignored (spaces are not allowed in filenames)
	
		

To do:
------

More instruction syntax checking is required (extraneous args, illegal arg
combinations etc.)

Optimization for speed and code size.
