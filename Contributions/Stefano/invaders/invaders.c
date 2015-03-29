//  Ported from Windows to OSCA by Stefano Bodrato
//  zcc +osca -clib=ansi -create-app -lndos -o invaders invaders.c
//

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <time.h>


//char *display;
//extern int d_file @16396;

#define Sleep(x) delay(x)
 
    #define sizey 23
    #define sizex 40
    #define player 'A'
    #define playerLaser '^'
    #define enemy 'M'
    #define enemyShielded 'O'
    #define enemyLaser 'U'
    #define explosion 'X'

    int x, y, yi;
    char world[2*sizey*sizex];
    int score = 0;
    int victory = 1;
    int laserReady = 1;
    int enemyReady = 0;
	int totalEnemies = 0;
	int i,c,f,g;
	int currentEnemies;
    char direction = 'l';
    char keyPress;
	int bonus;
	int drop;
	int enemySpeed;

int main()
{
//    int sizey = 23;
//    int sizex = 77;


//	display=d_file+1;
	
    /*welcome screen*/
	//textcolor(YELLOW);
	fputc_cons(12);
    printf("\n \n  Welcome soldier! \n \n \n");
    //Sleep(500);
	Sleep(500);
    printf("  Brave the COMMAND PROMPT INVADERS\n");
	printf("  and come back a hero. \n \n \n");
    //Sleep(2500);
	Sleep(500);
    printf("  Your operating system is\n");
	printf("  depending upon you. \n \n \n");
    //Sleep(2500);
	Sleep(1000);
	printf("  Controls: 'A','D','M'\n");
    printf("                  Good luck.\n");
	Sleep(500);
    //Sleep(500);
    printf("\n \n            Press any key to start.");
    fgetc_cons();
    //srand(time(NULL));
	srand(clock());
	
	//zx_cls();
	fputc_cons(12);

    /*initialise world*/
    totalEnemies = 0;
    for (x = 0; x < sizex; x ++) {
        for (y = 0; y < sizey; y ++) {
            if ((y+1) % 2 == 0 && y < 7 && x > 4
            && x < sizex - 5 && x % 2 ==0) {
                world[y*sizex+x] = enemy;
                totalEnemies ++;
            }
            else if ((y+1) % 2 == 0 && y >= 7 && y < 9 && x > 4
            && x < sizex - 5 && x % 2 ==0){
                world[y*sizex+x] = enemyShielded;
                totalEnemies = totalEnemies + 2;
            }
            else {
                world[y*sizex+x] = ' ';
            }
        }
    }
    world[(sizey - 1)*sizex+(sizex / 2)] = player;
    i = 1;
    direction = 'l';
    currentEnemies = totalEnemies;
    while(currentEnemies > 0 && victory) {
        drop = 0;
        enemySpeed = 1 + 10 * currentEnemies / totalEnemies;
        laserReady ++;

        /*display world*/
		gotoxy(1,1);
        //cls();   //system("cls");
		textcolor(LIGHTBLUE);
        printf("   SCORE:  %d", score);
        printf("\n");

        /*control player*/
		keyPress = getk();
		/*
        if(kbhit()){
            keyPress = getch();
        }
        else {
            keyPress = ' ';
        }*/
        if (keyPress == 'a') {
            for (x = 0; x < sizex; x = x+1) {
                if ( world[(sizey-1)*sizex+x+1] == player) {
                    world[(sizey-1)*sizex+x] = player;
                    world[(sizey-1)*sizex+x+1] = ' ';
                }
            }
        }

        if (keyPress == 'd') {
            for (x = sizex - 1; x > 0; x = x-1) {
                if ( world[(sizey-1)*sizex+x-1] == player) {
                    world[(sizey-1)*sizex+x] = player;
                    world[(sizey-1)*sizex+x-1] = ' ';
                }
            }
        }
        if (keyPress == 'm' && laserReady > 2) {
            for (x = 0; x < sizex; x = x+1) {
                if ( world[(sizey-1)*sizex+x] == player) {
                    world[(sizey-2)*sizex+x] = playerLaser;
                    laserReady = 0;
                }
            }
        }

        /*laser time*/
        for (x = 0; x < sizex; x ++) {
            for (y = sizey-1; y >= 0; y --) {
                if (i%2 == 0 && world[y*sizex+x] == enemyLaser
                && (world[(y+1)*sizex+x] != enemy & world[(y+1)*sizex+x] != enemyShielded)){
                world[(y+1)*sizex+x] = enemyLaser;
                world[y*sizex+x] = ' ';
                }
                else if (i%2 == 0 && world[y*sizex+x] == enemyLaser
                && (world[(y+1)*sizex+x] == enemy | world[(y+1)*sizex+x] == enemyShielded)){
                    world[y*sizex+x] = ' ';
                }
            }
        }
        for (x = 0; x < sizex; x ++) {
            for (y = 0; y < sizey; y ++) {
                if ((i % 5) == 0 && (world[y*sizex+x] == enemyShielded
                | world[y*sizex+x] == enemy) && (rand() % 15) > 13
                && world[(y+1)*sizex+x] != playerLaser) {
                    for (yi = y+1; yi < sizey; yi ++) {
                        if (world[yi*sizex+x] == enemy
                        | world[yi*sizex+x] == enemyShielded) {
                            enemyReady = 0;
                            break;
                        }
                        enemyReady = 1;
                    }
                    if (enemyReady) {
                        world[(y+1)*sizex+x] = enemyLaser;
                    }
                }
                if (world[y*sizex+x] == playerLaser && world[(y-1)*sizex+x] == enemy) {
                    world[y*sizex+x] = ' ';
                    world[(y-1)*sizex+x] = explosion;
                    currentEnemies --;
                    score = score + 50;
                }
                else if (world[y*sizex+x] == playerLaser
                && world[(y-1)*sizex+x] == enemyShielded) {
                    world[y*sizex+x] = ' ';
                    world[(y-1)*sizex+x] = enemy;
                    currentEnemies --;
                    score = score + 50;
                }
                else if (world[y*sizex+x] == playerLaser
                && world[(y-1)*sizex+x] == enemyLaser) {
                    world[y*sizex+x] = ' ';
                }
                else if (world[y*sizex+x] == explosion) {
                    world[y*sizex+x] = ' ';
                }
                else if ((i+1) % 2 == 0 && world[y*sizex+x] == enemyLaser
                && world[(y+1)*sizex+x] == player) {
                    world[(y+1)*sizex+x] = explosion;
                    world[y*sizex+x] = ' ';
                    victory = 0;
                }
                else if (world[y*sizex+x] == playerLaser
                && world[(y-1)*sizex+x] != enemyLaser) {
                        world[y*sizex+x] = ' ';
                        world[(y-1)*sizex+x] = playerLaser;
                }
            }
        }

        /*update enemy direction*/
        for (y = 0; y < sizey; y ++) {
            if (world[y*sizex] == enemy) {
                direction = 'r';
                drop = 1;
                break;
            }
            if (world[y*sizex+sizex-1] == enemy){
                direction = 'l';
                drop = 1;
                break;
            }
			// keep the keyboard buffer empty
			getk();
        }

        /*update board*/
        if (i % enemySpeed == 0) {
            if (direction == 'l') {
                for (x = 0; x < sizex - 1; x ++) {
                    for (y = 0; y < sizey; y ++) {
                        if (drop && (world[(y-1)*sizex+x+1] == enemy
                            || world[(y-1)*sizex+x+1] == enemyShielded)){
                            world[y*sizex+x] = world[(y-1)*sizex+x+1];
                            world[(y-1)*sizex+x+1] = ' ';
                        }
                        else if (!drop && (world[y*sizex+x+1] == enemy
                            || world[y*sizex+x+1] == enemyShielded)) {
                            world[y*sizex+x] = world[y*sizex+x+1];
                            world[y*sizex+x+1] = ' ';
                        }
                    }
                }
            }
            else {
                for (x = sizex; x > 0; x --) {
                    for (y = 0; y < sizey; y ++) {
                        if (drop && (world[(y-1)*sizex+x-1] == enemy
                            || world[(y-1)*sizex+x-1] == enemyShielded)) {
                            world[y*sizex+x] = world[(y-1)*sizex+x-1];
                            world[(y-1)*sizex+x-1] = ' ';
                        }
                        else if (!drop && (world[y*sizex+x-1] == enemy
                            || world[y*sizex+x-1] == enemyShielded)) {
                            world[y*sizex+x] = world[y*sizex+x-1];
                            world[y*sizex+x-1] = ' ';
                        }
                    }
                }
            }
            for (x = 0; x < sizex; x ++) {
                if (world[(sizey-1)*sizex+x] == enemy) {
                    victory = 0;
                }
            }
        }
			g=0;
            for (y = 0; y < sizey; y ++) {
            //fputc_cons('|');
				f=0;
				for (x = 0; x < sizex; x ++)
					if (world[y*sizex+x]!=' ')  f++;

					for (x = 0; x < sizex; x ++) {
						//printf("%c",world[y*sizex+x]);
						
						c=world[y*sizex+x];
						switch (c) {
							case explosion:
								textcolor(RED);
								break;
							case playerLaser:
								textcolor(LIGHTBLUE);
								break;
							case enemyLaser:
								textcolor(GREEN);
								break;
							case player:
								textcolor(MAGENTA);
								break;
							case enemyShielded:
								textcolor(WHITE);
								break;
							case enemy:
								textcolor(YELLOW);
								break;
						}
						fputc_cons(c);
						//display[y*(sizex+1)+x] = world[y*sizex+x];
					}
					textcolor(LIGHTBLUE);
					//fputc_cons('|');
				
				g=f;
            fputc_cons('\n');
            }
			

        i ++;
        //Sleep(50);
    }
	gotoxy(1,1);
    //zx_topleft();  //cls();   //system("cls");
        printf("     SCORE:    %d", score);
        printf("\n");
            for (y = 0; y < sizey; y ++) {
            printf("|");
                for (x = 0; x < sizex; x ++) {
                    printf("%c",world[y*sizex+x]);
                }
            printf("|");
            printf("\n");
            }
    Sleep(500);
    //zx_cls();   //system("cls");
	fputc_cons(12);
	textcolor(YELLOW);

    if (victory != 0) {
        printf("\n \n \n               CONGRATULATIONS! \n \n \n");
        Sleep(500);
        printf("\n \n               Score: %d", score);
        Sleep(500);
        bonus = totalEnemies*20 - i;
        printf("\n \n               Bonus: %d", bonus);
        Sleep(500);
        printf("\n \n               Total Score: %d", score + bonus);
        printf("\n \n \n               Well done");
        Sleep(500);
        printf(", Hero.");
        Sleep(500);
        fgetc_cons();
    }
    else {
        printf("\n \n \n \n               You have failed.");
        Sleep(500);
        printf("\n \n \n \n           Your computer is doomed.");
        Sleep(500);
        printf("\n \n               Final Score: %d", score);
        Sleep(500);
        fgetc_cons();
    }
}
