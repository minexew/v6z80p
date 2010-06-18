; ------------------------------------------------------------
; Phil's Template
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","This util converts a 24bit bmp file to 12 bit (+4 padded) words: $0RGB" + Chr(13) , 0)
  
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------

  srcfile$ = OpenFileRequester("Select a file","","BMP files (.bmp)|*.bmp|All Files(*.*)|*.*",0)
    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                  ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)          ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       MessageRequester("BMP converter","File error" + Chr(13) , 0)
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
  MessageRequester("BMP converter","Error! Not a .BMP format file" + Chr(13) , 0)
  End
 EndIf

 If PeekW(*sourcebuffer+30) <> 0
  MessageRequester("BMP converter","Error! Pic must have no compression!" + Chr(13) , 0)
  End
 EndIf

;-----------------------------------------------------------------------------------------

imwid.w = PeekW(*SourceBuffer+18)             
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
counter.l = 0
src_dataline.w = ((imwid + 3) & $fffc) * 3  ; necessary because of bmp padding to 4 pixel multiples
Debug (src_dataline)

;----------------------------------------------------------------------------------------
 
  *DestBuffer = AllocateMemory(imwid*imhei*2) 
    If *destbuffer

     For ypos = (imhei - 1) To 0 Step -1
      For xpos = 0 To (imwid - 1) 
       srcindex = pixelstartoffset + (ypos * src_dataline) +(xpos * 3)
       blue.w = PeekB(*SourceBuffer + srcindex) & 255
       green.w = PeekB(*SourceBuffer + srcindex+1) & 255
       red.w = PeekB(*SourceBuffer + srcindex+2) & 255
       bluebits.w    = (blue & 240) >> 4
       greenbits.w   = (green & 240) >> 4 
       redbits.w     = (red & 240) >> 4
       composite.b   = bluebits | (greenbits << 4)
       PokeB (*DestBuffer + (counter*2) + 1,redbits)
       PokeB (*DestBuffer + (counter*2),composite)
       counter = counter + 1
     Next xpos
    Next ypos 

   Else
    MessageRequester("BMP Converter","Cant create dest buffer!" + Chr(13) , 0)
   End
  EndIf


 ;------------------------------------------------------------------------------------------
 ; Save the "image" data 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Data As..",FileName$+"_conv.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*DestBuffer,counter*2)            ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("BMP converter","Can't create file" + Chr(13) , 0)
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
; CursorPosition = 48
; Folding = -
; Executable = 24bitpic_converter.exe