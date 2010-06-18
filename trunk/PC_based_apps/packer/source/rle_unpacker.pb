; ------------------------------------------------------------
; Phil's Run Length Compressor
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","Decompressor for V5Z80P_RLE Packed Files" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a file","","All Files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                 ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize+256)      ; allocate the needed memory (plus a bit extra)
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("Decompressor","File error" + Chr(13) , 0)
       End
      EndIf
      CloseFile(0)
     EndIf
 
 ;-----------------------------------------------------------------------------------------
  
 FileName$ = GetFilePart(srcfile$)                        ; trim off file extention
 Position = FindString(FileName$, ".", 1)
 If position > 0
  FileName$=Left (FileName$,position-1)
 EndIf

 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer                                      ; Decompressor code

 *Dest_Buffer = AllocateMemory(512*1024)               ; Filesize 512KB max
 
   If *Dest_Buffer
 
     srcindex.l = 1
     dstindex.l = 0

   Token.w = PeekW(*SourceBuffer) & 255

  Repeat

     databyte.w = PeekW(*SourceBuffer + srcindex) & 255
 
     If Databyte = Token
      srcindex = srcindex + 1
      runvalue.w = PeekW(*SourceBuffer + srcindex) & 255
      srcindex = srcindex + 1
      runlength.w = PeekW(*SourceBuffer + srcindex) & 255
      srcindex = srcindex + 1
      For n = 1 To runlength
       PokeB (*dest_buffer+dstindex,runvalue)
       dstindex=dstindex+1
      Next n
     Else
       runvalue.w = PeekW(*SourceBuffer + srcindex) & 255
       PokeB (*dest_buffer+dstindex,runvalue)
       dstindex = dstindex + 1
       srcindex = srcindex + 1
     EndIf
           
  Until srcindex => sourcesize
 
    Else
      MessageRequester("Decompressor","Cant create work buffer!" + Chr(13) , 0)
    End
 
  EndIf


 ;------------------------------------------------------------------------------------------
 ; Save the data 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Data As..",FileName$+"_unpacked.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                       ; we create a new file...
   WriteData(0,*dest_Buffer,dstindex)                ; write data from the memory block into the file
   CloseFile(0)                                   ; close the previously opened file and so store the written data 
  Else
   MessageRequester("Decompressor","Can't create file" + Chr(13) , 0)
  End
  EndIf

;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

MessageRequester("Decompressor", "Done!" + Chr(13), 0)

Else

MessageRequester("Decompressor", "Failed!" + Chr(13), 0)

EndIf

End
 

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 82
; FirstLine = 48
; Folding = -
; Executable = ..\bmp_to_raw_planar\source\bmp_to_raw_chunky.exe