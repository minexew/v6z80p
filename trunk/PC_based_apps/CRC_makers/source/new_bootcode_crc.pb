;-----------------------------------------------------------------
; Append CRC to the FPGA bootcode file
; ----------------------------------------------------------------

  MessageRequester("Phil's V6Z80P Utils..","This modifies the last two bytes of a file with a CRC word" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the bootcode file
;-------------------------------------------------------------------------------------

  srcfile2$ = OpenFileRequester("Select a Z80 bootcode file","",".exe files (.exe)|*.exe|All Files(*.*)|*.*",0)
    
    If ReadFile(0,srcfile2$) 
      sourcesize_bc = Lof(0)                                  ; get the length of opened file
       *SourceBuffer = AllocateMemory(sourcesize_bc)          ; allocate the needed memory
      ReadData(0,*SourceBuffer, sourcesize_bc)                ; read all data into the memory block
      CloseFile(0)
    EndIf

;-------------------------------------------------------------------------------
; Make CRC checksum
;-------------------------------------------------------------------------------

hlreg.l = 65535
For bytecount = 0 To sourcesize_bc-3
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
PokeW (*sourcebuffer+sourcesize_bc-2,calculated_crc)

;------------------------------------------------------------------------------------------
; Save the file
;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save As..","bootcode.epr","V6Z80P EEPROM (.epr)|*.epr|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*Sourcebuffer,sourcesize_bc)      ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file  
  Else
   MessageRequester("Phils Utils","Cant create file!" + Chr(13) , 0)
   End
  EndIf

 ;------------------------------------------------------------------------------------------

MessageRequester("Phils utils","Done." + Chr(13) , 0)
 
End

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 10
; Folding = -
; Executable = ..\New_bootcode_CRC_maker.exe