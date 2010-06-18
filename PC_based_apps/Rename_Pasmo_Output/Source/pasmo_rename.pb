; Pasmo rename - By Phil Ruston for V6Z80P
 
; This renames the output file obtained by dragging an .asm file
; to assemble.bat (IE: somecode.asm.bin) to an 8.3 filename with
; .exe extension. Warning: deletes existing file of that name if present.
;
; USAGE: Command line z80_rename.exe [filename]


filename$ = ProgramParameter()

filep$ = GetFilePart(filename$)
pathp$ = GetPathPart(filename$)

 Position = FindString(filep$, ".", 1)     ; trim off file extention
 If position > 0
  filep$=Left (filep$,position-1)
 EndIf
 
 size = Len (filep$)                        ;ensure 8.3 format
 If size > 8
  size = 8
 EndIf
  
sourcefilename$=filename$+".bin"
destfilename$=pathp$ + Left (filep$,size)+".exe"


result = CopyFile(sourcefilename$,destfilename$)
If result = 0
 MessageRequester("Error","Error copying file!")
Else
 DeleteFile(sourcefilename$)
EndIf

End

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 30
; Folding = -
; EnableXP
; Executable = pasmo_rename.exe