;-----------------------------------------------------------------
; Append CRC to the FPGA bootcode file
; ----------------------------------------------------------------

  MessageRequester("Phil's V6Z80P Utils..","This puts the V6Z80P checksum header onto OS files" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the bootcode file
;-------------------------------------------------------------------------------------

    srcfile$ = OpenFileRequester("Select a file","",".bin files (.bin)|*.bin|All Files(*.*)|*.*",0)
    
    If ReadFile(0,srcfile$) 
      sourcesize_bc = Lof(0)                                  ; get the length of opened file
       *SourceBuffer = AllocateMemory(sourcesize_bc+16)       ; allocate the needed memory
      ReadData(0,*SourceBuffer+16, sourcesize_bc)             ; read all data into the memory block
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
For bytecount = 16 To sourcesize_bc+15
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

PokeS (*sourcebuffer,"Z80P*OS*")                          ; add header to file
PokeL (*sourcebuffer+8,sourcesize_bc)                     ; put in filesize (less header)
PokeW (*sourcebuffer+12,calculated_crc)                   ; inject CRC at $0C
PokeW (*sourcebuffer+14,0)                                ; nothing at $E

;------------------------------------------------------------------------------------------
; Save the file
;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save As..",DestFileName$,"V6Z80P OS File (.osf)|*.osf|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*Sourcebuffer,sourcesize_bc+16)   ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file  
  Else
   MessageRequester("Phils Utils","Cant create file!" + Chr(13) , 0)
   End
  EndIf

 ;------------------------------------------------------------------------------------------

MessageRequester("Phils utils","Done." + Chr(13) , 0)

EndIf

End

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 80
; Folding = -
; Executable = ..\Add_os_crc_header.exe