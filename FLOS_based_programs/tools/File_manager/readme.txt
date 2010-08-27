FILE MANAGER V0.03 - Requires FLOS 5.77+
----------------------------------------

Updates:
--------

v0.03 - Added "RX" button to receive files via Serial Link, requires Serial Link 2.8
        for complete compatibility (EG: Handling file overwrite)

      - Fixed path display code (was inserting "/../" when not needed)

      - Tab swaps panels, CTRL selects buttons.

      - Improved text entry code.

      - Fixed unhandled attempts at copying a file with same name as a dir

      - Tests if MOVE has deleted the folder FLOS was originally in (back to root on exit)


Instructions:
-------------


TAB key selects between upper panels. Left panel is for the source directory,
right panel is for the destination directory. Highlight files for an operation
on the source side (only) with the SPACE BAR.

Press CTRL to activate the lower buttons and then press LEFT, RIGHT or TAB to cycle
through them, ENTER to choose an option.

When you select "make a new directory" (or RX) the panel that is the target for
the operation is that which was active before the buttons were selected.

ESC to quit requesters (or press ENTER on CANCEL Button provides)


