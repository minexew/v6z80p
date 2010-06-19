MACRO GET_I_DATA, r0, r1, r2, r3, r4, r5
   ld ix, I_DATA

IF ! NUL r0
   ld r0,(ix+0)
ENDIF

IF ! NUL r1
   ld r1,(ix+1)
ENDIF

IF ! NUL r2
   ld r2,(ix+2)
ENDIF

IF ! NUL r3
   ld r3,(ix+3)
ENDIF

IF ! NUL r4
   ld r4,(ix+4)
ENDIF

IF ! NUL r5
   ld r5,(ix+5)
ENDIF

ENDM


MACRO GET_I_DATA_2, r0, r1, r2, r3, r4, r5

IF ! NUL r0
   ld r0,(ix)
   inc ix
ENDIF

IF ! NUL r1
   ld r1,(ix)
   inc ix
ENDIF

IF ! NUL r2
   ld r2,(ix)
   inc ix
ENDIF

IF ! NUL r3
   ld r3,(ix)
   inc ix
ENDIF

IF ! NUL r4
   ld r4,(ix)
   inc ix
ENDIF

IF ! NUL r5
   ld r5,(ix)
   inc ix
ENDIF

ENDM






MACRO SET_I_DATA, r0, r1, r2, r3, r4, r5


IF ! NUL r0
   ld (ix),r0
   inc ix
ENDIF

IF ! NUL r1
   ld (ix),r1
   inc ix
ENDIF

IF ! NUL r2
   ld (ix),r2
   inc ix
ENDIF

IF ! NUL r3
   ld (ix),r3
   inc ix
ENDIF

IF ! NUL r4
   ld (ix),r4
   inc ix        
ENDIF

IF ! NUL r5
   ld (ix),r5
   inc ix
ENDIF

ENDM


MACRO PUSH_ALL_REGS                       
        push af                               
        push bc                               
        push de                               
        push hl                               
        exx                                   
        push af                               
        push bc                               
        push de                               
        push hl                               
        exx                                   
        push ix                               
        push iy
ENDM        


MACRO POP_ALL_REGS                        
        pop iy                                
        pop ix                                
        exx                                   
        pop hl                                
        pop de                                
        pop bc                                
        pop af                                
        exx                                   
        pop hl                                
        pop de                                
        pop bc                                
        pop af
ENDM

