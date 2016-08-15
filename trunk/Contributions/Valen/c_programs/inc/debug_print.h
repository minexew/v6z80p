#ifndef DEBUG_PRINT_H
#define DEBUG_PRINT_H


// This is new file use this file in your program.
// (old obsolete file: base_lib/debig_print.h)

extern unsigned char program_isPrintToSerial;	// you need to add this var in your program (or link error will be produced by linker)

// IAR C does not support variadic macros.
// (some info here http://en.wikipedia.org/wiki/Variadic_macro)
// So we need to do this in old way (with C89 compatibility).

#ifdef __IAR_SYSTEMS_ICC__
#define DEBUG_PRINT(fmt)            program_isPrintToSerial = 1;      \
                                    printf fmt;                       \
                                    program_isPrintToSerial = 0;
#endif



#if defined(SDCC) || defined(__SDCC)
#define DEBUG_PRINT(...)    program_isPrintToSerial = 1;   	\
                            printf(__VA_ARGS__);            \
                            program_isPrintToSerial = 0;
#endif



// PC
#ifndef  __SDCC
#define DEBUG_PRINT(...)           printf(__VA_ARGS__);
                                    
#endif




#endif /* DEBUG_PRINT_H */
