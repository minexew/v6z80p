#ifndef DEBUG_PRINT_H
#define DEBUG_PRINT_H


extern void Program_Set_IsPrintToSerial(unsigned char);

#define DEBUG_PRINT(...)    Program_Set_IsPrintToSerial(1);   \
                            printf(__VA_ARGS__);              \
                            Program_Set_IsPrintToSerial(0);

#endif /* DEBUG_PRINT_H */
