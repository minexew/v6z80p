
bulk_file_loader.asm
--------------------

 With this routine, a program can load files from a collated "bulk data file"
 as created with the utility BULKFILE.EXE

 The bulkfile util joins multiple files end to end and places a index at the
 top so that loading is as simple as reading normal individual files.

 Limitations: Currently, only complete files can be read from bulk data (No
 offset or truncated loads).


 To use the routine, set the following EQUATES in your main code:

 index_start_lo 
 index_start_hi  

  (This is the 32 bit file offset (split into 2 words) to the index in the bulk file.
   It should be zero if the bulk file is separate to main .exe)
 
 
 bulkfile_fn  (Address of the filename of the bulk file. If the bulk file is
               attached to main .exe, make this be same as the .exe filename) 


 To load a file from the bulk data, set:

 HL = filename of the file required within the bulk data
 DE = load address
  B = load bank

 then call "load_from_bulk_file"

 The error codes returned are the same as a KJT file load call (IE: If ZF = set
 all OK, else error code in A)

 The bulk data file can be joined to the end of the main executable, so reducing
 everything down to a one file. In this scenario, bulkfile_fn should point to a
 filename which is the same name as the .exe. index_start_lo & index_start_hi should
 equal the number of bytes in the .exe. Also, The the executable should have a FLOS
 Program Location Header to specify how long the executable part is (IE: we dont want
 FLOS to load the entire file - only everything up to the bulk data index).


