
Disktool.exe for FLOS by Phil Ruston 2010-2012
----------------------------------------------

v0.08


Info
----

Ordinarilly, when formatting an SD card with Windows (or by using the FLOS
FOrmat command) no Master Boot Record is created - instead the entire disk
is treated as a single partition. (Linux and some devices such as digital
cameras will install a MBR and create one or more partitions).

Since v5.65, FLOS can make use of multiple partitions and this util can
create and format them on the V6Z80P.


Notes:
------

A minimum partition size of 32MB (and a maximum of 2048MB) is imposed.

FLOS does not follow the Microsoft method of handling multiple ("extended")
partitions, with "logical drives" etc. Instead, the four primary partition
"slots" in the MBR are used. Generally speaking, Windows (XP) will only see
the first partition, Linux and other OSes may well recognize the others.

