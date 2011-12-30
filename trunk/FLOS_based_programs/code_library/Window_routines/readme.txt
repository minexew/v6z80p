Simple Window drawing and support code for FLOS - by Phil Ruston
-----------------------------------------------------------------

Last updated 03/03/2010.

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

 Byte  0  : Element Type: 0=button, 1=data area, 2=info (text)
 Byte  1  : width of element
 Byte  2  : height of element 
 Byte  3  : Control bits
 Byte  4  : Event flag (currently unused)
 Bytes 5/6: (Word) address of "associated data"

The bits of the control byte (3) are irrelevent when just drawing windows
but are used in the window support code - they are described later. The
word at offset 5 is an address lable that points to data relevent
to the element type, EG: ASCII text for a button. If irrelevant, the word
can be omitted.

-----------------------------------------------------------------------------

For example, here's an element (an "OK" button) used by the above window
description:

win_element_a	db 0		;0 = Element Type: 0 = A button
		db 2,1		;1/2 = dimensions of element x,y
		db 1		;3 = control bits
		db 0		;4 = event flag (currently unused)
		dw ok_txt	;5/6 = location of associated data

ok_txt		db "OK",0	;The ASCII that goes in the button


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
          do not current act on this - at present it is merely an indicator
          for parent programs.

     3-7: currently unused.



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

FLOS_based_programs\code_library\_tests_and_demos

-------------------------------------------------------------------------------------------

Notes:

Windows are drawn on top of anything on the display. If the original character
map is to be restored after a window is finished with, the user's program must
handle it.

