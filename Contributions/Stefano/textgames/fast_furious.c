/* 
 * 
 * Simone Reggiani
 * 
 * The Fast & The Furious
 * 
 */

#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <dos.h>
#include <windows.h>
#include <string.h>



void main()

{

  int a,c,d,e,g,r,k,j,f;

  char n1[80],n2[80],n3[80],n4[80];

  //randomize();
  do {
  a=1; k=1; j=1; f=1;
  clrscr();

  textcolor(4);
  gotoxy(10,12);
  cprintf("THE FAST & THE FURIOUS");

  textcolor(5);
  gotoxy(8,16);
  cprintf("press any key to continue");
  getch();
  srand(clock());

  clrscr();
  textcolor(11);
  cprintf("PLAYER 1: "); cscanf("%s",n1); printf("\n\n");
  cprintf("PLAYER 2: "); cscanf("%s",n2); printf("\n\n");
  cprintf("PLAYER 3: "); cscanf("%s",n3); printf("\n\n");
  cprintf("PLAYER 4: "); cscanf("%s",n4);

  getch();
  clrscr();

  gotoxy(1,1);        /* auto 1 all'inizio */
  c=random(4)+1;
  textcolor(c);
  cprintf("|\\");
  gotoxy(1,2);
  textcolor(7);
  cprintf("0=0");

  gotoxy(1,4);        /* auto 2 all'inizio */
  d=random(8)+5;
  textcolor(d);
  cprintf("|\\");
  gotoxy(1,5);
  textcolor(7);
  cprintf("0=0");

  gotoxy(1,7);        /* auto 3 all'inizio */
  e=random(12)+9;
  textcolor(e);
  cprintf("|\\");
  gotoxy(1,8);
  textcolor(7);
  cprintf("0=0");

  gotoxy(1,10);        /* auto 4 all'inizio */
  g=random(15)+13;
  textcolor(g);
  cprintf("|\\");
  gotoxy(1,11);
  textcolor(7);
  cprintf("0=0");

  gotoxy(1,20);
  textcolor(14);
  cprintf("Press any key to start the race");

  getch();

  
  while(k<=37 && a<=37 && j<=37 && f<=37)
     {

         r=random(2);

         if(r)

          {

         	textcolor(c);

         	gotoxy(k+1,1);

         	cprintf("|\\");

  		gotoxy(k+1,2);

   	 	textcolor(7);

      	 	cprintf("0=0");

                gotoxy(k,1);

   	 	printf(" ");

      	 	gotoxy(k,2);

         	printf(" ");

         	k=k+1;

          }

         r=random(2);

         if(r)

          {

            textcolor(d);

            gotoxy(a+1,4);

            cprintf("|\\");

            gotoxy(a+1,5);

            textcolor(7);

            cprintf("0=0");

            gotoxy(a,4);

            printf(" ");

            gotoxy(a,5);

            printf(" ");

            a=a+1;

          }

         r=random(2);

         if(r)

          {

         	textcolor(e);

   	        gotoxy(j+1,7);

      	        cprintf("|\\");

         	gotoxy(j+1,8);

   	        textcolor(7);

  	        cprintf("0=0");

        	gotoxy(j,7);

         	printf(" ");

        	gotoxy(j,8);

        	printf(" ");

         	j=j+1;

          }

         r=random(2);

         if(r)

          {

         	textcolor(g);

 	        gotoxy(f+1,10);

   	        cprintf("|\\");

      	        gotoxy(f+1,11);

      	        textcolor(7);

 	        cprintf("0=0");

   	        gotoxy(f,10);

      	        printf(" ");

         	gotoxy(f,11);

    	        printf(" ");

      	        f=f+1;

          }

         Sleep(500);

     }

  //clrscr();

  gotoxy(12,12);

  textcolor(9);

  cprintf("THE WINNER IS: ");

  if(a==78) cprintf("%s",n2);

   else if (k==78) cprintf("%s",n1);

    else if (j==78) cprintf("%s",n3);

     else cprintf("%s",n4);

  getch();
  


  //}
  textcolor(5);
  gotoxy(2,16);
  cprintf("ENTER to restart, another key to exit");

}  while(getch()==13);

  return(-1);
}
//}

