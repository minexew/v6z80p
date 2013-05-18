/*
 *	entab <file >file
 */

/*)BUILD	$(TKBOPTIONS) = {
			TASK	= ...ENT
		}
*/

#ifdef	DOCUMENTATION

title	entab	Replace blanks by tabs and blanks
index		Replace blanks by tabs and blanks

synopsis
	.s.nf
	entab [-t] infile outfile
	.s.f
description

	Copies input to output, replacing sequences of blanks
	and tabs by the minimum number of tabs and blanks required
	to give the same visual effect.

	Trailing blank/tabs are removed.

	<Return> overstrikes are handled.

	If -t is given, a single blank will be output as <TAB> if
	valid.  For example, if the string:

		1234567 8

	is given, the program will output a space following the '7'.
	If -t is given, the program will output a <TAB>.
	
diagnostics

	None

author

	Martin Minow

	(Taken from Kernighan and Plauger, Software Tools)

bugs

	Tabs occur every eight column only.

#endif

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#define	BLANK	' '
#define	TAB	'\t'
#define	RETURN	'\r'
#define	NEWLINE	'\n'
#define	FALSE	0
#define	TRUE	1

int	tflag = FALSE;

main(int argc, char *argv[])
{
	register int	c;
	register int	col;
	register int	newcol;
	int		lastc;

	col = FALSE;			/* TRUE if input redirected	*/
	for (c = 1; c < argc; c++) {
	    if (argv[c][0] == '-') {
		if (tolower(argv[c][1]) == 't')
		    tflag++;
		else {
		    printf("Unknown option \"%s\"\n", argv[c]);
		}
	    }
	    else {
		if (!col) {
		    freopen(argv[c], "r", stdin);
		    col++;
		}
		else {
		    freopen(argv[c], "w", stdout);
		}
	    }
	}
	if (col==0) {
		    printf("Please specify an input file name\n");
			return(0);
	}

	c = EOF;
	col = 0;	/* Tab stops at 0, 8, 16, ...			*/
	for (;;) {
	    newcol = col;
	    for (;;) {
		lastc = c;
		switch (c = fgetc(stdin)) {
		case BLANK:
		    newcol++;
		    continue;

		case TAB:
		    newcol = nexttabstop(newcol);
		    continue;

		default:
		    break;		/* Exits for loop		*/
		}
		break;			/* Neither BLANK nor TAB	*/
	    }
	    if (c == EOF) {
		if (newcol > 0) {
		    //putchar(NEWLINE);
		    fputc(NEWLINE,stdout);
		}
		break;
	    }
	    else if (c == RETURN || c == NEWLINE) {
		col = 0;
		//putchar(c);
		fputc(c,stdout);
	    }
	    else {
		/*
		 * If -t was not given and the last character was
		 * a blank and there's just one blank, don't do
		 * a tab here.
		 */
		if (tflag || lastc == TAB || (col + 1) < newcol) {
		    while (nexttabstop(col) <= newcol) {
			//putchar(TAB);
			fputc(TAB,stdout);
			col = nexttabstop(col);
		    }
		}
		while (col < newcol) {
		    //putchar(BLANK);
		    fputc(BLANK,stdout);
		    col++;
		}
		//putchar(c);
		fputc(c,stdout);
		col++;
	    }
	}
}


nexttabstop(col)
register int	col;
/*
 * Return the next tab stop after col (col == 1 -> 8)
 */
{
	return (col + (8 - (col & 7)));
}

