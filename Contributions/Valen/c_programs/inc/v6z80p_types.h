#ifndef V6Z80P_TYPES_H
#define V6Z80P_TYPES_H

/*
   V6Z80P types
   This is main include file, it must be included in any project.

*/

typedef unsigned long  ulong;
typedef unsigned short ushort;
typedef unsigned char  uchar;

typedef unsigned char  byte;
typedef unsigned short word;
typedef unsigned long  dword;

typedef unsigned short FIXED88;         // fixed point 8.8

typedef unsigned char  BOOL;

#define FALSE   0
#define TRUE    1

// Pointer to void func, without any args
typedef void (*ptrVoidFunc)(void);


#endif /* V6Z80P_TYPES_H */
