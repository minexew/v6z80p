// To enable assert functionality, define DEBUG in your program.

#ifdef DEBUG
#define ASSERT_V6(x) ((x) == 0 ? _assert_v6(#x, __FILE__, __LINE__):(void)0)
void _assert_v6(char *expr, const char *filename, unsigned int linenumber);
#else
#define ASSERT_V6(x) ((void)0)
#endif



