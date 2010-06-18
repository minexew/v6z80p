; ------------------------------------------------------------
; Phil's Template
; ------------------------------------------------------------

  MessageRequester("Phil's Utils..","This util makes an 'alternate bit font' for the CP/M test from a 256 colour Windows .BMP File - make sure font is 128 chars long, 0-31 = blanks" + Chr(13) , 0)
  
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
 ;Convert the pixels...
 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer                               ; get data about file from its header

 If PeekW(*sourcebuffer+0) <> $4d42
  MessageRequester("BMP converter","Error! Not a .BMP format file" + Chr(13) , 0)
  End
 EndIf

 If PeekW(*sourcebuffer+28) <> 8
  MessageRequester("BMP converter","Error! Must be 256 colour pic!" + Chr(13) , 0)
  End
 EndIf

 If PeekW(*sourcebuffer+30) <> 0
  MessageRequester("BMP converter","Error! Pic must have no compression!" + Chr(13) , 0)
  End
 EndIf

imwid.w = PeekW(*SourceBuffer+18)             
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
   
If (imwid.w & 7) <> 0
 MessageRequester ("BMP converter","Error! Image width must be multiples of 8 pixels!"+ Chr(13) , 0)
 End
EndIf

counter.l = 0

;----------------------------------------------------------------------------------------

;flip the buffer as BMPs are upside down
  
  *Flipped_Buffer = AllocateMemory(imwid * imhei)  
   If *Flipped_Buffer
     For ypos = (imhei - 1) To 0 Step -1
      For xpos = 0 To (imwid - 1) 
       srcindex = pixelstartoffset + xpos + (ypos * imwid)
       Databyte.b = PeekB(*SourceBuffer + srcindex)
       PokeB (*Flipped_Buffer + counter,databyte)
       counter = counter + 1
     Next xpos
    Next ypos 
   Else
   MessageRequester("BMP to Charset Converter","Cant create work buffer!" + Chr(13) , 0)
   End
  EndIf

;------------------------------------------------------------------------------------------
; convert the pixel data
;------------------------------------------------------------------------------------------

Counter = 0

*Dest_Buffer = AllocateMemory(imwid * imhei) 

 If *Dest_Buffer
 
     For ypos = 0 To (imhei - 1)
      For xpos = 0 To (imwid - 1) Step 16
 
 
        planarbyte_a.b = 0
        planarbyte_b.b = 0
        pixelbit = 0 
        
        For nyb = 0 To 1

         For pix = 0 To 3
  
         srcindex = (ypos * imwid) + xpos + (nyb*8) + ((pix*2)+1)
         Databyte.b = PeekB(*Flipped_Buffer+srcindex)
         If Databyte <> 0
          planarbyte_a = planarbyte_a + (1 << pixelbit)
         EndIf
        
         srcindex = (ypos * imwid) + xpos + (nyb*8) + (pix*2)
         Databyte.b = PeekB(*Flipped_Buffer+srcindex)
         If Databyte <> 0
          planarbyte_b = planarbyte_b + (1 << pixelbit)
         EndIf
         
         pixelbit = pixelbit + 1       
        Next pix
        
        Next nyb
 
        PokeB (*Dest_Buffer + counter,planarbyte_a)
        PokeB (*dest_buffer + 512 + counter,planarbyte_b)
 
        counter = counter + 1
      Next xpos 
     Next ypos 
     
  Else
   MessageRequester("BMP to Charset Converter","Cant create destination buffer!" + Chr(13) , 0)
  End
  EndIf
  
Else
 MessageRequester("BMP to Charset converter","No Source File Selected" + Chr(13) , 0)
 End
EndIf
 
counter = 1024                                   ;fix file length as 2 block RAMs length

 ;------------------------------------------------------------------------------------------
 ; Save the image data 
 ;------------------------------------------------------------------------------------------
   
  dstfile$ = SaveFileRequester("Save Bitplane Data As..",FileName$+"_bitplanes.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
    
  If CreateFile(0,dstfile$)                      ; we create a new file...
   WriteData(0,*Dest_Buffer,counter)                ; write data from the memory block into the file
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
; CursorPosition = 111
; FirstLine = 83
; Folding = -
; Executable = make_font.exe