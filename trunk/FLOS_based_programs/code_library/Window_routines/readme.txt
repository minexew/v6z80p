Simple Window drawing and support code for FLOS - by Phil Ruston
-----------------------------------------------------------------

Last updated 02/07/2012 - Window draw code version 0.10

The routines allow the user to create and operate simple windows
(EG: requesters) with minimal effort. To use, please include
the following files into your project's code:

 "Window routines/inc/window_draw_routines.asm" (this source
  has an incbin for the data "window_chars.bin" so that file
  should also be copied into your project's include folder).

 and, if required: 

 "Window routines/inc/Window_Support_Routines.asm"


Overview
--------

The Window system defines "Windows" and "Elements" - A window is the basic frame
which contains elements (EG: gadgets). There are currently 3 basic types of element:

Type 0: A button - some text with a double outline.
Type 1: A data area - a blank area where dynamic data is entered or displayed. 
Type 2: Info - purely cosmetic, EG: window text.

In your source code, you need three things:

1. A window address list - merely a list of addresses to window descriptions.
2. Descriptions of the windows (see below)
3. Descriptions of the elements used by your window (see below)

Once you have this data you can display a window by setting:

A to the window number.
B to the x coordinate of Window
C to the y coordinate of window.

and then calling: "Draw_window"


Details:
--------

As mentioned, the window list is just a list of labels (addresses) to your
different window types. This should be labelled "Window_list". EG:

window_list:	dw my_ok_requester
		dw my_cancel_requester
		dw etc_etc..

The data structures these labels point to describe a window's dimensions and lists
the position of the elements it contains. 


The data structure for a Window is as follows:
-----------------------------------------------

 Byte 0: X coordinate (in characters) of window frame on screen (set internally)
      1: Y coordinate "" ""
      2: X dimension of window
      3: Y dimension "" ""
      4: Current element selected (dynamic, set internally)
      5: Unused at present
      
      6: First 4-byte element reference (see below)

      6+?: 255 - Rogue value to signify the end of element references.


-------------------------------------------------------------------------------

Here's a simple example of a Window with one element:

my_ok_requester	db 0,0			;0 - position on screen of frame (x,y) 
		db 10,5			;2 - dimensions of window (x,y)
		db 0			;4 - current element/gadget selected
		db 0			;5 - unused at present

		db 4,2			;6 - position of first element (x,y)
		dw win_element_a	;8 - address of first element description

		db 255			;End of list of window elements

--------------------------------------------------------------------------------


Bytes 0, 1 are populated by the call that draws the window (draw_window)
Byte 4 is populated by the window support code. These can all be set at
zero to start with.

Each four-byte element reference starting at byte 6 is defined as follows:

   0 : X coordinate (offset from left edge of window to element)
   1 : Y coordinate (offset from top of window to element) 
 2:3 : Address of the element's data structure.

Because bytes 2:3 contain a pointer to the actual element description instead
of the element description itself, you can use define an element, EG: A "cancel"
button, and use it for multiple windows. The data structure the label points to
is defined as follows:

Data structure for each unique element:
---------------------------------------

 Byte  0   : Element Type: 0=button, 1=data area, 2=info (text)
 Byte  1   : width of element
 Byte  2   : height of element 
 Byte  3   : Control bits
 Byte  4   : Event flag (currently unused)
 Bytes 5/6 : (Word) address of "associated data" (set to zero if irrelevant)
 Bytes 7-16: Element dependant (can be omitted if irrelevant) 
 
The bits of the control byte (3) are mainly used in the window support code,
and are described later. However, if an element is a data area and bit 2
of the control byte is set ("accepts user input") then the "associated data"
location address (bytes 5/6) points to the default text string that is to
appear in the box. Note: The text string should be big enough for data area
and be null-terminated.

As mentioned, the word at offset 5 is an address label that points to data relevent
to the  element type, EG: ASCII text for a button (or default data as stated above).
If such data is irrelevant to an element type, the word should be set to 0 (for safety)
but can be omitted if desired.

Bytes 7-16 change meaning based on the element type. They play no part in the
drawing of the window and can be omitted if irrelevant to the element type.

-----------------------------------------------------------------------------

For example, here's an element (an "OK" button) used by the above window
description:

win_element_a	db 0		;0 = Element Type: 0 = A button
		db 2,1		;1/2 = dimensions of element x,y
		db 1		;3 = control bits
		db 0		;4 = event flag (currently unused)
		dw ok_txt		;5/6 = location of associated data

ok_txt		db "OK",0	;The ASCII that goes in the button

-----------------------------------------------------------------------------

Notes:

When "w_draw_window" is called, the window is drawn over anything on the display.
If the original character map/attr maps are to be maintained, the following calls
can assist:

w_backup_display	- no arguments (pushes display to stack)
w_restore_display	- no arguments (just pops the last display saved off the stack)

(if the zero flag is not set on return, the stack is full, or empty in case of restore)

w_restore_level_a	- Put the stack level required in A (0-2)

These are called either side of "w_draw_window" (of course the user program can handle
backup/restore itself if more flexibility is required). The above routines have a 3
layer stack and place the data in VRAM at $1c800-$1dfff

-----------------------------------------------------------------------------
Window support code
-----------------------------------------------------------------------------

This is a loose set of helper routines to provide support for the operation a
window system. Please include "Window routines/inc/Window_Support_Routines.asm"
into your program if you want to use them.

The routines use the same data-sets as the draw routines above and now the control
bits (byte 3 of element descriptions) come into play. The bits are defined:

 Bit 0  : This element is selectable. This ensures that when the user cycles
          (tabs) through the elements, only the actual "gadgets" are selectable
          and not cosmetic text elements etc.

     1  : This element is a list type selection (EG: disk directory). This is
          a special case of a selectable element. Instead of the entire element
          being highlighted when selected, a single line is highlighted only.
          The line that is chosen for highlighting is selected by a value in
          the "associated data" variable.

     2  : This element can accept ASCII input from the keyboard. The routines
          do not currently act on this - at present it is merely an indicator
          for parent programs.

     3  : The data to be entered is to be interpreted as a signed 32 bit hex number.
          When this bit is set, bytes 7-16 of the element data are required:
	  
	   Bytes 7-10: Double word, upper limit for numeric input (32 bit signed)
 	   Bytes 11-14:Double word, lower limit for numeric input (32 bit signed)
 	   Bytes 15/16:Displacement value for numeric data adjust (+/- keys)
             (this value doubles several times when +/- key is held)
           Byte 17    :Bit 0 = sign extend number entered by user to 32bit internal
                      :Bit 1 = Skip leading zeroes when displaying number

     4-7: currently unused.



Full list of routines contained in "Window routines/inc/Window_Support_Routines.asm")
-------------------------------------------------------------------------------------

Note: All unused registers *are* preserved.


W_LOCATE_ACTIVE_WINDOW
 
   HL returns the address of window description for the active (last drawn) window 

 
 W_LOCATE_WINDOW_A

   HL returns the address of window description for window number in A

			
 W_GET_ACTIVE_WINDOW_COORDS

   BC returns coordinates of active (last drawn) window. B = x, C = y.


 W_GET_WINDOW_A_COORDS

   BC returns coordinates of window number in A.  B = x, C = y.


 W_GET_ELEMENT_SELECTION

   A returns the number of the selected element in the active window


 W_SET_ELEMENT_SELECTION

   A sets the element selection of the active window


 W_GET_SELECTED_ELEMENT_COORDS

   BC returns the coords of the selected element in the active window

 
 W_GET_ELEMENT_A_COORDS

   BC returns the top left coords of element in A of the active window


 W_GET_SELECTED_ELEMENT_ADDRESS

   HL returns the address in the window description of the selected element
   in the active window (IE: the address of the group "x,y,element_address")


 W_GET_ELEMENT_A_ADDRESS

   HL returns the address in the window description of element A in the active
   window (IE: the address of the group "x,y,element_address")


 W_GET_SELECTED_ELEMENT_DATA_LOCATION

   IX returns the location of the selected element itself in the active window
   (IE: The address of the group "element_type,dimensions,flags" etc)


 W_GET_ELEMENT_A_DATA_LOCATION

   IX returns the location of element A itself in the active window
   (IE: The address of the group "element_type,dimensions,flags" etc)


 W_HIGHLIGHT_SELECTED_ELEMENT

   Highlights the selected element in the active window with pen colour in A
   If an element is the special line-by-line selection bit set, the a single
   line will be highlighted, the y offset is taken from teh associated variable location.


 W_UNHIGHLIGHT_SELECTED_ELEMENT

   Removes the highlight from the selected element


 W_NEXT_SELECTABLE_ELEMENT

   Moves the element selection on top the next selectable element (and wraps around
   if necessary)


 W_ASCII_TO_ASSOCIATED_DATA

   Copies an ASCII string (source=HL) to the currently selected element's associated
   data area. Stops on encountering null char ($00) (or width of element filled).


 W_SHOW_ASSOCIATED_TEXT

   Updates the display with the "associated data" text string for the currently selected
   element.


 W_GET_ASSOCIATED_DATA_LOCATION

  Put address of the currently selected element's "associated data" in HL. If
  Zero flag is set on return, the element has no associated data.


------------------------------------------------------------------------------------------

EG: The first thing you may want to do after drawing a window is set the
default active element. EG:

	ld a,0			;window number
	ld b,8			;x
	ld c,2			;y
	call draw_window		

	ld a,2
	call w_set_element_selection

-------------------------------------------------------------------------------------------

Simple demo code for window drawing and support is provided in:

FLOS_based_programs\code_library\Window_routines\demo

-------------------------------------------------------------------------------------------

