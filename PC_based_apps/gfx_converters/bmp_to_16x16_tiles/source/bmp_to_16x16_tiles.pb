; This script can work in two modes.
; If no args in command line - GUI mode.
;
; If 4 args in command line - command line mode.
; Command line args:
; - input BMP file
; - output BIN file
; - output PAL file
; - format of output palette (for PAL file) '12' or '24'


Global isGUI_Mode = 1;      ; default mode is GUI (not command line mode)

; ------------------------------------------------------------
; DoMessage Procedure
; ------------------------------------------------------------
  Procedure DoMessage(str1$, str2$, num)
    If isGUI_Mode
      ProcedureReturn MessageRequester(str1$, str2$, num)
    Else
      ConsoleError (str1$)
      str2$ = ReplaceString(str2$, Chr(13),  Chr(13) + Chr(10))   ; replace 13 with 10,13 (console wants 10,13 as newline sequence)
      ConsoleError (str2$)
    EndIf  
  EndProcedure
  
; ------------------------------------------------------------
; Check, if we are executed in command line mode
; ------------------------------------------------------------
  countParams = CountProgramParameters()
  If countParams >= 4
    isGUI_Mode = 0
    OpenConsole()
  EndIf 
      
; ------------------------------------------------------------
; Phil's Template
; ------------------------------------------------------------

 DoMessage("Phil's Utils..","Converts 256 Colour Windows .BMP File to linear sequence of 16x16 pixel tiles" + Chr(13) , 0)

  
;-------------------------------------------------------------------------------------
; Get the source file
;-------------------------------------------------------------------------------------
  If isGUI_Mode
    srcfile$ = OpenFileRequester("Select a file","","BMP files (.bmp)|*.bmp|All Files(*.*)|*.*",0)  
  Else
    srcfile$ = ProgramParameter(0);    
  EndIf
  

    
     If ReadFile(0,srcfile$) 
      sourcesize = Lof(0)                                 ; get the length of opened file
      *SourceBuffer = AllocateMemory(sourcesize)          ; allocate the needed memory
      If *SourceBuffer
       ReadData(0,*SourceBuffer, sourcesize)                ; read all data into the memory block
      Else
       DoMessage("BMP converter","File error" + Chr(13) , 0)
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
 ;Check format...
 ;-----------------------------------------------------------------------------------------

 If *SourceBuffer

If PeekW(*sourcebuffer+0) <> $4d42
 DoMessage("BMP sprite converter","Error! Not a .BMP format file" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+28) <> 8
 DoMessage("BMP sprite converter","Error! Must be 256 colour pic!" + Chr(13) , 0)
 End
EndIf
If PeekW(*sourcebuffer+30) <> 0
 DoMessage("BMP sprite converter","Error! Pic must have no compression!" + Chr(13) , 0)
 End
EndIf

imwid.w = PeekW(*SourceBuffer+18)             ; get data about file from its header
imhei.w = PeekW(*SourceBuffer+22)
pixelstartoffset.w = PeekW(*SourceBuffer+10)
   
If (imwid.w & 15) <> 0 Or (imhei.w & 15) <> 0 
 DoMessage ("BMP sprite converter","Error! Image cannot be divided evenly into 16x16 blocks"+ Chr(13) , 0)
 End
EndIf

;----------------------------------------------------------------------------------------

counter.l = 0
srcindex.l = 0

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
   DoMessage("BMP Converter","Cant create work buffer!" + Chr(13) , 0)
   End
  EndIf

;------------------------------------------------------------------------------------------
; convert the pixel data
;------------------------------------------------------------------------------------------

  counter.l = 0
  *DestBuffer = AllocateMemory(imwid * imhei)  
   If *Destbuffer
    For blockrow = 0 To (Imhei/16) -1
     For blockcolumn = 0 To (Imwid/16) - 1
      For pixelrow = 0 To 15
       For pixelcolumn = 0 To 15
        srcindex.l = (blockrow * imwid * 16) + (blockcolumn*16) + (pixelrow * imwid) + pixelcolumn
        pixel.w = PeekB(*Flipped_Buffer + srcindex) & 255
        PokeB (*DestBuffer + counter,pixel)
        counter = counter + 1
      Next pixelcolumn
     Next pixelrow
    Next blockcolumn
   Next blockrow
      
   Else
   DoMessage("BMP converter","Cant create destination buffer!" + Chr(13) , 0)
   End
  EndIf

Else
 DoMessage("BMP converter","No Source File Selected" + Chr(13) , 0)
 End
EndIf
 
 ;------------------------------------------------------------------------------------------
 ; Save the image data 
 ;------------------------------------------------------------------------------------------
  If isGUI_Mode       
    dstfile$ = SaveFileRequester("Save Tile Data As..",FileName$+"_tiles.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
  Else
    dstfile$ = ProgramParameter(1);
  EndIf
  
    
  If CreateFile(0,dstfile$)                      ; we create a new text file...
   WriteData(0,*DestBuffer,counter)                ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   DoMessage("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

 ;-------------------------------------------------------------------------------------------
 ; Convert the palette 
 ;------------------------------------------------------------------------------------------

pal_size.l = 0

  If isGUI_Mode    
    pal_depth$ = InputRequester("BMP converter", "12 bit ($0RGB..) or 24 bit ($RR,$GG,$BB..) palette", "12")
  Else
    pal_depth$ = ProgramParameter(3);
  EndIf
  
 
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
     PokeB (*DestBuffer + (counter*2)+1,redbits)
     PokeB (*DestBuffer + (counter*2),composite)
     offset = offset + 4
   Next counter
   pal_size = 256 * 2
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
  If isGUI_Mode
    dstfile$ = SaveFileRequester("Save Palette Data As..",FileName$+"_"+pal_depth$+"bit_"+"palette.bin","Binary (.bin)|*.bin|All files (*.*)|*.*",0)
  Else
    dstfile$ = ProgramParameter(2);
  EndIf   
  
    
  If CreateFile(0,dstfile$)                      ; create a new file...
   WriteData(0,*DestBuffer,pal_size)              ; write data from the memory block into the file
   CloseFile(0)                                  ; close the previously opened file and so store the written data 
  Else
   DoMessage("BMP converter","Can't create file" + Chr(13) , 0)
  End
  EndIf

;----------------------------------------------------------------------------------------------
;Finish up
;----------------------------------------------------------------------------------------------

DoMessage("Phil's Utils..", "Done!" + Chr(13), 0)

End 


  
; IDE Options = PureBasic 4.51 (Windows - x86)
; ExecutableFormat = Console
; CursorPosition = 21
; Folding = -
; EnableAsm
; Executable = ..\..\..\V3_Z80_PROJECT\PC-Side_Tools\bmp-to-sprites\bmp_to_16x16_tiles.exe