#ifdef SDCC
struct {
    unsigned char isPrintToSerial;
} program;

void Program_Set_IsPrintToSerial(unsigned char val)
{
    program.isPrintToSerial = val;
}

#endif