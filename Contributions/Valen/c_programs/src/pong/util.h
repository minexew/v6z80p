#ifndef UTIL_H
#define UTIL_H

#define CLEAR_IRQ_KEYBOARD      1



void DiagMessage(char* pMsg, const char* pFilename);
BOOL Util_LoadPalette(const char* pFilename);
void Sys_ClearIRQFlags(byte flags);
byte GetR(void)  __naked;

#endif /* UTIL_H */