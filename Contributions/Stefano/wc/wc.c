/*
 * wc [file ...]

	Count the number of bytes, words, and lines in one or more files.
	wc accepts wild-card file name arguments.

Original author (PDP11 DECUS version)
	Martin Minow

 */

/* To build:
		zcc +osca -lflosdos -owc.exe -DFLOS wc.c
		zcc +cpm -owc.com wc.c
*/


#include <stdio.h>
#include <stdlib.h>
#ifdef FLOS
#include <string.h>
#include <flos.h>
#endif

long	twords	= 0;
long	tlines	= 0;
long	tbytes	= 0;


#ifdef FLOS

char	file_name[20];


// Found in the BDS C sources, (wildexp..),written by Leor Zolman.
// contributed by: W. Earnest, Dave Hardy, Gary P. Novosielski, Bob Mathias and others

int match(char *wildnam, char *filnam)
{
   char c;
   
   while (c = *wildnam++)
	if (c == '?')
		if ((c = *filnam++) && c != '.')
			continue;
		else
			return 0;
	else if (c == '*')
	{
		while (c = *wildnam)
		{ 	wildnam++;
			if (c == '.') break;
		}
		while (c = *filnam)
		{	filnam++;
			if (c == '.') break;
		}
	}
	else if (c == *filnam++)
	 	continue;
	else return 0;

   if (!*filnam)
	return 1;
   else
	return 0;
}

#endif


/*
plural(long value, char *what)
{
//#ifdef	unix
//	printf("%8ld", value);
//#else
	//printf("%06ld %s%c ", value, what, (value == 1) ? ' ' : 's');
	printf("%06ld %s,", value, what);
//#endif
}
*/

output(long lines, long words, long bytes, char *filename)
{
//	plural(lines, "l");
//	plural(words, "w");
//	plural(bytes, "b");
	printf("%07ld ", lines);
	printf("%07ld ", words);
	printf("%07ld ", bytes);
	if (filename != NULL)
	    printf(" %s", filename);
	printf("\n");
}




int main(int argc, char *argv[])

{
	int	x,i, nfiles;
	FILE	*fp;
	int		gotcha;

	nfiles = 0;
	if(argc < 2) {
	    //++nfiles;
	    //count(stdin, NULL);
			printf("\nwc - Count the number of bytes, words,\nand lines in one or more files.\n");
		    exit (0);
	}
	else {
	printf("\nWords   Lines   Bytes    File\n");
	printf("------- ------- -------  -----------\n");

#ifdef FLOS
	    for (i = 1; i < argc; ++i) {
			if ((x=dir_move_first())!=0) return(0);

			while (x == 0) {
				if (match(argv[i],dir_get_entry_name())) {
					if (!dir_get_entry_type()) {
						++nfiles;
						fp = fopen(dir_get_entry_name(), "r");
						count(fp, dir_get_entry_name());
						fclose(fp);
					}
				}
				x = dir_move_next();
			}

		    if (gotcha == 0)
			printf("\"%s\": no matching files\n", argv[i]);
	    }
#else
	    for (i = 1; i < argc; ++i) {
		if ((fp = fopen(argv[i], "r")) == NULL) {
		    //perror(argv[i]);
			printf("\"%s\": file not found\n", argv[i]);
		    exit (0);
		}
		else {
		    ++nfiles;
		    count(fp, argv[i]);
		    fclose(fp);
		}
	    }
#endif
	}
	if (nfiles > 1) {
		printf("------- ------- -------  -----------\n");
		output(tlines, twords, tbytes, "TOTAL");
	}
}

count(fp, filename)
FILE		*fp;			/* File pointer			*/
char		*filename;		/* File name string		*/
{
	register int c, inword;
	long lines;
	long words;
	long bytes;

	lines = 0;
	words = 0;
	bytes = 0;
	inword = 0;
	while((c = getc(fp)) != EOF) {
	    ++bytes;
	    if (c == ' ' || c == '\t' || c == '\n') {
		inword = 0;
		if (c == '\n')
		    ++lines;
	    }
	    else if (!inword) {
		++inword;
		++words;
	    }
	}
	twords += words;
	tlines += lines;
	tbytes += bytes;
	output(lines, words, bytes, filename);
	
	return(0);
}
