;-----------------------------------------------------------------
; Insert CRC word to OS file at offset $0C
; ----------------------------------------------------------------

;-------------------------------------------------------------------------------------
; Get the OS file
;-------------------------------------------------------------------------------------

    srcfile$ = OpenFileRequester("Select an OS file for CRC insertion","","All Files(*.*)|*.*",0)
    
    If ReadFile(0,srcfile$) 
      sourcesize_bc = Lof(0)                                  ; get the length of opened file
       *SourceBuffer = AllocateMemory(sourcesize_bc)          ; allocate the needed memory
      ReadData(0,*SourceBuffer, sourcesize_bc)                ; read all data into the memory block
      CloseFile(0)
    

;-----------------------------------------------------------------------------------------

filename$ = srcfile$
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
  
destfilename$=pathp$ + Left (filep$,size)+".OSF"

;-------------------------------------------------------------------------------
; Make CRC checksum
;-------------------------------------------------------------------------------

hlreg.l = 65535
For bytecount = 16 To sourcesize_bc-1
 byteval.w = PeekB(*SourceBuffer+bytecount)&$ff
 hlreg = (byteval << 8) ! hlreg
 For n = 0 To 7
  hlreg = hlreg + hlreg
   If hlreg > 65535 
   hlreg = hlreg & $FFFF
   hlreg = hlreg ! $1021
  EndIf
 Next n
;Debug (Hex(hlreg))
Next bytecount

calculated_crc.l = hlreg&$ffff

PokeL (*sourcebuffer+8,sourcesize_bc-16)                  ; put in filesize (less header)
PokeW (*sourcebuffer+12,calculated_crc)                   ; inject CRC at $0C

;------------------------------------------------------------------------------------------
; Save the file
;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save As..",DestFileName$,"V6Z80P OS File (.osf)|*.osf|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*Sourcebuffer,sourcesize_bc)      ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file  
  Else
   MessageRequester("Phils Utils","Cant create file!" + Chr(13) , 0)
   End
  EndIf

 ;------------------------------------------------------------------------------------------

  MessageRequester("Phil's V6Z80P Utils..","Checksum word inserted into OS file at offset $0C" + Chr(13) , 0)
  
EndIf

End

; IDE Options = PureBasic 5.21 LTS (Windows - x86)
; CursorPosition = 8
; Executable = ..\..\..\FLOS\apps\insert_crc_into_OS.exe