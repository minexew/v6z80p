; ------------------------------------------------------------
; Phil's Utils
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","Makes raw 16x16 sprites from a 256 colour Windows .BMP file." + Chr(13) + "Pic is scanned top To bottom, left To right" + Chr(13) , 0)
  skipzerotile$ = InputRequester("Phil's Utils..", "Want to skip all-zero 16x16 tiles?", "y")
 
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
 
 ;-------------------------------------------------------------------------------------------

 FileName$ = GetFilePart(srcfile$)                        ; trim off file extention
 Position = FindString(FileName$, ".", 1)
 If position > 0
  FileName$=Left (FileName$,position-1)
 EndIf

 ;-----------------------------------------------------------------------------------------
 ;Check file...
 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer

If PeekW(*sourcebuffer+0) <> $4d42
 MessageRequester("BMP sprite converter","Error! Not a .BMP format file" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+28) <> 8
 MessageRequester("BMP sprite converter","Error! Must be 256 colour pic!" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+30) <> 0
 MessageRequester("BMP sprite converter","Error! Pic must have no compression!" + Chr(13) , 0)
 End
EndIf

imwid.w = PeekW(*SourceBuffer+18)             ; get data about file from its header
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
   
If (imwid.w & 15) <> 0 Or (imhei.w & 15) <> 0 
 MessageRequester ("BMP sprite converter","Error! Image cannot be divided evenly into 16x16 blocks"+ Chr(13) , 0)
 End
EndIf

;-----------------------------------------------------------------------------------------

index_offset$ = InputRequester("BMP conversion", "Any palette index offset (for non-zero pixels)?", "0")
index_offset = Val (index_offset$) 

;-----------------------------------------------------------------------------------------
;Convert pixels
;-----------------------------------------------------------------------------------------

;  Debug imwid
;  Debug imhei
  counter.l = 0
  *DestBuffer = AllocateMemory(imwid * imhei)  
   If *Destbuffer
    For vertstrip = 0 To (imwid / 16) - 1 
     For sprline = 0 To (imhei - 1) Step 16
      Orsum.w = 0
      For pixelrowindex = 0 To 15
       For pixelindex = 0 To 15
        srcindex.l = pixelstartoffset + pixelindex + (vertstrip * 16) + ((imhei - (sprline + pixelrowindex + 1)) * imwid)
        pixel.w = PeekB(*SourceBuffer + srcindex) & 255
        If pixel <> 0                                             ;offset
         pixel= pixel + index_offset
        EndIf        
        PokeB (*DestBuffer + counter,pixel)
        Orsum=Orsum|pixel
        counter = counter + 1
       Next pixelindex
      Next pixelrowindex
      If skipzerotile$ = "y" And Orsum=0
       counter=counter-256
      EndIf
     Next sprline
    Next vertstrip  
   Else
   MessageRequester("BMP converter","Cant create destination buffer!" + Chr(13) , 0)
   End
  EndIf

Else
 MessageRequester("BMP converter","No Source File Selected" + Chr(13) , 0)
 End
EndIf
 
 ;------------------------------------------------------------------------------------------
 ; Save the image data 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Sprite Data As..",FileName$+"_sprites.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new text file...
   WriteData(0,*DestBuffer,counter)                ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

  ;-------------------------------------------------------------------------------------------
 ; Convert the palette 
 ;------------------------------------------------------------------------------------------
   
  pal_depth$ = InputRequester("BMP converter", "12 bit ($0RGB) or 24 bit ($RR,$GG,$BB..) palette", "12")
 
  If pal_depth$ = "12"
   offset = 54
    For counter = 0 To 255
     blue.w        = PeekB(*SourceBuffer + offset + 0) & 255
     bluebits.w    = (blue & 240) >> 4
     green.w       = PeekB(*SourceBuffer + offset + 1) & 255
     greenbits.w   = (green & 240) >> 4 
     red.w         = PeekB(*SourceBuffer + offset + 2) & 255
     redbits.w     = (red & 240) >> 4
     composite.b   = bluebits | (greenbits << 4)
     PokeB (*DestBuffer + (counter*2) +1,redbits)
     PokeB (*DestBuffer + (counter*2),composite)
     offset = offset + 4
   Next counter
   pal_size.l = 256 * 2
  Else
  pal_depth$ = "24"
   offset = 54
    For counter = 0 To 255
     blue.w        = PeekB(*SourceBuffer + offset + 0) & 255
     green.w       = PeekB(*SourceBuffer + offset + 1) & 255
     red.w         = PeekB(*SourceBuffer + offset + 2) & 255
     PokeB (*DestBuffer + (counter*3),red)
     PokeB (*DestBuffer + (counter*3) + 1,green)
     PokeB (*DestBuffer + (counter*3) + 2,blue)
     offset = offset + 4
   Next counter
   pal_size.l = 256 * 3
  EndIf
   
 ;------------------------------------------------------------------------------------------
 ; Save the palette
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Palette Data As..",FileName$+"_"+pal_depth$+"bit_"+"palette.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; create a new file...
   WriteData(0,*DestBuffer,pal_size)              ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   MessageRequester("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

MessageRequester("Phil's Utils..", "Done!" + Chr(13), 0)

End 

; IDE Options = PureBasic 4.30 (Windows - x86)
; CursorPosition = 82
; FirstLine = 45
; Folding = -
; EnableAsm
; Executable = ..\bmp_to_chunky_sprites.exe