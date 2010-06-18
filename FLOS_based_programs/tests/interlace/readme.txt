
"int_on" and "int_off" simply enable / disable the interlacing
hardware - the display will show vertical jitter as the same
image is used for both fields.

"interpic" loads and displays an interlaced picture. The
odd and even fields are switched manually at the vertical
retrace.

"intpicmodulo" loads a single picture file, the height is
twice the size of a non-interlaced picture. The program
uses the modulo registers to skip alternate lines each
field.

Interlace does not work in VGA mode
