/* Exercise 43 - Higher / Lower Number Game

** (c) Copyright 2002-4 Simon Huggins

** Written 4th December 2002

*/



/* Include standard C libraries to use */

#include <stdio.h>
#include <conio.h>
#include <ctype.h>
#include <stdlib.h>
#include <time.h>



/* Define TRUE / FALSE constants, and also maximum number (1-n) to use */

#define TRUE 1
#define FALSE 0
#define LOWEST_NUM 1
#define MAX_NUMS 10

/* Main program */

main()

{

  /* Set up variables:
  ** - score: The score - starts at 0, increased by 1 with a correct guess
  ** - number: The number chosen by the computer from 1 to MAX_NUMS
  ** - prior_number: The previous number the computer chose
  ** - have_guessed: TRUE if user has guessed at least once. Used to make
       sure do not do comparison first time around loop
  ** - guess: User's guess - must be H for higher or L for lower
  */

  int score, number, prior_number, have_guessed;

  char guess;

  /* Set up variables, including first random number to be displayed */

  have_guessed = FALSE; score = 0;
  clrscr();
  printf( "Press any key to begin\n");
  getch();
  srand( (unsigned int) time( NULL ) );
  number = ( rand () % MAX_NUMS ) + LOWEST_NUM;
  printf( "\nInitial number is %d\n", number );

  do
  {
    /* Only do the following if statement after have been around the loop once */

    if ( have_guessed == TRUE )
    {

      /* If the guess was H and the number was higher than the previous
         number, or if the guess was L and the number was lower than the
         previous number... */

      if ( (( guess == 'H' ) && ( number > prior_number )) ||
         (( guess == 'L' ) && ( number < prior_number )) )
      {
        printf(  "Correct! The number was %d\n", number );
        score++; /* increase the score by 1 point */
        printf( "Score is now %d", score );
      }

      /* Otherwise the user made a wrong guess, so break out of the loop and
         end the game */

      else

      {

        printf( "Incorrect! The number was %d\n", number );

        printf( "Score was %d\nGAME OVER!\n\n", score );

        break;

      }

    } /* end of if not first time around loop */


    /* remember the previous number */
    prior_number = number;

    /* get the next random number the computer will use */
    while (number == prior_number) number = ( rand () % MAX_NUMS ) + LOWEST_NUM;



    /* Get the user's input, which must be upper case H or L */
    do
    {
      printf( "\nHigher or Lower (H/L) for a number %d-%d? ",
              LOWEST_NUM, LOWEST_NUM + MAX_NUMS - 1 );
      guess = toupper( getche() );
    }
    while ( ( guess != 'H' ) && ( guess != 'L' ) );


    printf( "\n\n" );

    /* We have been once around the loop, so we can compare number to
       prior_number now, so set have_guessed to TRUE */

    have_guessed = TRUE;



  } while ( TRUE ); /* Loop around without any condition */



  /* Outside loop - must be game over. So wait for user to press a key. */

  //getch();

}
/*
Change the program to pick out numbers between 1 and 5 instead of 1 and 10.
How about picking a number between 5 and 9 (hint: from 5 to 9 there are 5 
possible numbers that could be picked, and the lowest number is 5. If you 
found a random number between 0 and 4 and added 5 to this, you would get a
number between 5 and 9. Try to apply this logic to the program above.

Finally, if you have the time, change the program so that the same number 
cannot be picked by the computer twice in a row.  To do this, you will need to:
* - Create a new variable to store the previous number selected by the computer 
(e.g. call it prior_number). 
Set the variable to initially contain something that cannot be chosen
*  - e.g.
*  -1. Place a do..while loop around the selection of the new random number
*      (this is not necessary for the very first number picked out).  
*      The condition should be that the prior number equals the selected number
*  - i.e. if the numbers are the same, the loop executes again to pick another number. 

After the loop, you will need to set the prior number variable to the contents of the new number, 
ready for the next number that may be selected (if the user makes a correct choice!) 

*/
