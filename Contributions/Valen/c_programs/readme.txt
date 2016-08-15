SDCC framework for V6Z80P.

Online Docs:
http://wiki.retroleum.co.uk/wiki/view/SDCC+framework


SDCC framework use SCons build system.
(Old makefile based system is marked as deprecated.)



Heap HowTo (sdcc site):
----
The answer is that, on Z80 systems, heap size is hard-coded to 1kB. Maarten Brock answered this on the sdcc-user mailing list.

You have to create the heap yourself if the standard 1kB is not enough. 
Copy heap.s into your project dir and modify it to create your preferred size. Then assemble it and link with your project.

Unlike the mcs51 heap which is defined in _heap.c this is not documented for Z80 in the manual. 
Feel free to request a documentation update or merge of _heap.c and heap.s in the tracker system.