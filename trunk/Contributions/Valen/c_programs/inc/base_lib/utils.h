#ifndef UTILS_H
#define UTILS_H

BOOL Utils_Check_FLOS_Version(word req_version);
void DiagMessage(const char* pMsg, const char* pFilename);

void PrintWORD(WORD w, BYTE radix);
#endif /* UTILS_H */
