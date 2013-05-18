/*
 *	detab <file >file
 */

/*)BUILD	$(TKBOPTIONS) = {
			TASK	= ...DET
		}
*/

#ifdef	DOCUMENTATION

title	detab	Replace tabs by blanks
index		Replace tabs by blanks

synopsis

	entab infile outfile

description

	Copies input to output, replacing sequences of tabs
	by a string of blanks (presupposing tabstops every
	8 columns).  Trailing blanks are removed.  If the file
	arguments are missing, the standard input and output
	are used.

diagnostics

	None

author

	Martin Minow

bugs

	Tabs occur every eight columns only.

#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define	FALSE	0
#define	TRUE	1
#define	EOS	0
#define	BLANK	' '
#define	TAB	'\t'
#define	NEWLINE	'\n'
#define	FALSE	0
#define	TRUE	1

char	line[513];

main(int argc, char *argv[])
{
	register int	i;
	register char	*lstart;
	register char	*lend;

	if (argc==1) {
		    printf("Please specify an input file name\n");
			return(0);
		}
	for (i = 1; i < argc; i++) {
	    if (i == 1) {
		if (freopen(argv[i], "r", stdin) == NULL) {
		    //perror(argv[i]);
	        fprintf(stderr, "%s: cannot open\n", argv[i]);
		    exit(1);
		}
	    }
	    else {
		if (freopen(argv[i], "w", stdout) == NULL) {
	        fprintf(stderr, "%s: cannot open\n", argv[i]);
		    //perror(argv[i]);
		    exit(1);
		}
	    }
	}
	//while (gets(line) != NULL) {
	while (fgets(line,sizeof(line),stdin) != NULL) {
	    lstart = line;
	    while ((lend = strchr(lstart, TAB)) != NULL) {
		/*
		 * Found a tab.
		 */
		*lend++ = EOS;
		printf("%s", lstart);
		i = 8 - ((lend - lstart - 1) & 07);
		while (--i >= 0)
		    //putchar(BLANK);
		    fputc(BLANK,stdout);
		lstart = lend;
	    }
	    printf("%s\n", lstart);
	}
}		
