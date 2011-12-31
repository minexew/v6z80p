EDIT.EXE v0.01 for FLOS by Phil Ruston 2011 (to replace TEXTEDIT.EXE)
---------------------------------------------------------------------

Use: EDIT [filename] [-G hex_number]

If no filename is supplied, a new document called "NEW.TXT" is created.
The parameter [-G hex_number] is the line to go to at start (also optional).
 
Keys:
----
CTRL + ESC = QUIT
CTRL + L   = LOAD
CTRL + S   = SAVE
CTRL + G   = GOTO LINE
CTRL + N   = NEW DOCUMENT

Also supported: Page_Up, Page_Down, Home, Insert

Notes:
------

Max line length = 248 characters
Max file size = 384KB
When saving, if a file exists with same name, that file is renamed "*.BAK"
Tabs are fixed at 8 characters
 
Tech info:
----------
Stores text file in VRAM $20000-$7ffff for ease/speed of manipulation with blitter
Also uses VRAM $0-$1fff for buffer

