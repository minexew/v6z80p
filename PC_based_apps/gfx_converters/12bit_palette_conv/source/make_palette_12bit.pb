; ------------------------------------------------------------
; Phil's Template
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","This util converts the palette to 12 bit (IE: R,G,B AND 0F0h)" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a file","","BMP files (.bmp)|*.bmp|All Files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                 ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)          ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("Palette converter","File error" + Chr(13) , 0)
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
 ;Check file...
 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer                               ; get data about file from its header

 If PeekW(*sourcebuffer+0) <> $4d42
  MessageRequester("Palette converter","Error! Not a .BMP format file" + Chr(13) , 0)
  End
 EndIf

 If PeekW(*sourcebuffer+28) <> 8
  MessageRequester("Palette converter","Error! Must be 256 colour pic!" + Chr(13) , 0)
  End
 EndIf

 If PeekW(*sourcebuffer+30) <> 0
  MessageRequester("Palette converter","Error! Pic must have no compression!" + Chr(13) , 0)
  End
 EndIf

imwid.w = PeekW(*SourceBuffer+18)             
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
counter.l = 0

 ;-------------------------------------------------------------------------------------------
 ; Convert the palette 
 ;------------------------------------------------------------------------------------------

   offset = 54
   
    For counter = 0 To 255
   
     blue.w        = PeekB(*SourceBuffer + offset + 0) & 255
     bluebits.w    = (blue & 240)
     green.w       = PeekB(*SourceBuffer + offset + 1) & 255
     greenbits.w   = (green & 240) 
     red.w         = PeekB(*SourceBuffer + offset + 2) & 255
     redbits.w     = (red & 240)
     
     PokeB (*SourceBuffer + offset + 0,bluebits)
     PokeB (*SourceBuffer + offset + 1,greenbits)
     PokeB (*SourceBuffer + offset + 2,redbits)
    
     offset = offset + 4
   
   Next counter

   
 ;------------------------------------------------------------------------------------------
 ; Save the altered file 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save As..",FileName$+"_12bitpalette.bmp","BMP (.bmp)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*SourceBuffer,sourcesize)          ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("Palette converter","Can't create file" + Chr(13) , 0)
  End
  EndIf 
  
;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

MessageRequester("Phil's Utils..", "Done!" + Chr(13), 0)

Else

MessageRequester("Phil's Utils..", "Failed!" + Chr(13), 0)

EndIf

End
 

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 89
; FirstLine = 52
; Folding = -
; Executable = ..\bmp_to_raw_planar\source\bmp_to_raw_chunky.exe