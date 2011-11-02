There are two targets in this dir:
1. i_flos.c
This file is always linked with user program.

2. C FLOS library.
Interfacing C code with FLOS kernal.

All .c files, with pattern name FLOS_* are compiled to objects and then linked to one lib.

Note: Each FLOS_... function is stored in separate source file. This save code/data size of user program.
Only functions, which called by user, will be linked to user app.


