#ifndef SET_STACK_H
#define SET_STACK_H

#define SET_STACK()     const word own_sp = OWN_SP;     // OWN_SP is defined in project configuration file (filename: 'SConscript')
SET_STACK()                                             // set stack address for this program (actual value is in project makefile)

#endif /* SET_STACK_H */
