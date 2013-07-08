In the OSBORNE user group sources they prepared a set of minimalistic version of the UNIX commands.   'sort' was a good exercise to test the automatic memory space definition, the BDS C conversion macros and the file redirection parameters, so here it is. It is able to handle not too big text files, see the source for details.

Quick example:
sort -u <filein.txt >fileout.txt
 
Use CTRL-Z to close input stream if you get stuck with the console connected as stdin.