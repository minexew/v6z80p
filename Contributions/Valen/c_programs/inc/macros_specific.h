#ifndef MACROS_SPECIFIC_H
#define MACROS_SPECIFIC_H

// compiler specific

#ifdef SDCC
#define ASM_PREFIX		#
#define NAKED   		__naked
#define	BEGINASM()              __asm
#define	ENDASM()                __endasm;
#else
#define ASM_PREFIX
#define NAKED
#define	BEGINASM()
#define	ENDASM()
#endif


#ifdef SDCC
#define PUSH_ALL_REGS()                       \
        push af                               \
        push bc                               \
        push de                               \
        push hl                               \
        exx                                   \
        push af                               \
        push bc                               \
        push de                               \
        push hl                               \
        exx                                   \
        push ix                               \
        push iy


#define POP_ALL_REGS()                        \
        pop iy                                \
        pop ix                                \
        exx                                   \
        pop hl                                \
        pop de                                \
        pop bc                                \
        pop af                                \
        exx                                   \
        pop hl                                \
        pop de                                \
        pop bc                                \
        pop af
#else
#define PUSH_ALL_REGS()
#define POP_ALL_REGS()
#endif



#ifdef SDCC
#define DI()     __asm          \
                 di             \
                 __endasm;

#define EI()     __asm          \
                 ei             \
                 __endasm;
#endif





# ifdef S_SPLINT_S
# endif //S_SPLINT_S


#endif /* MACROS_SPECIFIC_H */
