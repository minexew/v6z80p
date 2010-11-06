//
// stdio_v6z80p.h
//
// Standard I/O routines for V6Z80P.
//


#ifndef STDIO_V6Z80P_H
#define STDIO_V6Z80P_H

//#include <sys/types.h>
typedef int handle_t;

#include "../c_support/crt/stdio_v6z80p/os.h"


int errno;


#ifndef _FPOS_T_DEFINED
#define _FPOS_T_DEFINED
typedef long fpos_t;
#endif

#ifndef SEEK_SET
#define SEEK_SET   0
#define SEEK_CUR   1
#define SEEK_END   2
#endif

#define FILENAME_MAX   256
#define EOF            (-1)
#define BUFSIZ         512

struct _iobuf 
{
  char *ptr;
  int cnt;
  char *base;
  int flag;
//  handle_t file; // we don't use OS handle, because FLOS don't provide any "file handles"
  int charbuf;
  int bufsiz;
  int phndl;
};

typedef struct _iobuf FILE;

#define stdin   __getstdhndl(0)
#define stdout  __getstdhndl(1)
#define stderr  __getstdhndl(2)

#define _IORD           0x0001
#define _IOWR           0x0002

#define _IOFBF          0x0000
#define _IOLBF          0x0040
#define _IONBF          0x0004

#define _IOOWNBUF       0x0008
#define _IOEXTBUF       0x0100
#define _IOTMPBUF       0x1000

#define _IOEOF          0x0010
#define _IOERR          0x0020
#define _IOSTR          0x0040
#define _IORW           0x0080

#define _IOCRLF         0x8000



int filbuf(FILE *stream);
int flsbuf(int, FILE *stream);

FILE *fdopen(int fd, const char *mode);
FILE *freopen(const char *filename, const char *mode, FILE *stream);
FILE *fopen(const char *filename, const char *mode);

FILE *popen(const char *command, const char *mode);
int pclose(FILE *stream);

void clearerr(FILE *stream);
int fclose(FILE *stream);
int fflush(FILE *stream);

int fgetc(FILE *stream);
int fputc(int c, FILE *stream);

char *fgets(char *string, int n, FILE *stream);
int fputs(const char *string, FILE *stream);

char *gets(char *buf);
int puts(const char *string);

size_t fread(void *buffer, size_t size, size_t num, FILE *stream);
size_t fwrite(const void *buffer, size_t size, size_t num, FILE *stream);

int fseek(FILE *stream, long offset, int whence);
long ftell(FILE *stream);
void rewind(FILE *stream);
int fsetpos(FILE *stream, const fpos_t *pos);
int fgetpos(FILE *stream, fpos_t *pos);

void perror(const char *message);

void setbuf(FILE *stream, char *buffer);
int setvbuf(FILE *stream, char *buffer, int type, size_t size);

int ungetc(int c, FILE *stream);

int remove(const char *filename);
int rename(const char *oldname, const char *newname);

FILE *tmpfile();
char *tmpnam(char *string);
char *tempnam(const char *dir, const char *prefix);



FILE *__getstdhndl(int n);


#define feof(stream)     ((stream)->flag & _IOEOF)
#define ferror(stream)   ((stream)->flag & _IOERR)
#define fileno(stream)   ((stream)->file)

#define getc(stream)     (--(stream)->cnt >= 0 ? 0xff & *(stream)->ptr++ : filbuf(stream))
#define putc(c, stream)  (--(stream)->cnt >= 0 ? 0xff & (*(stream)->ptr++ = (char) (c)) :  flsbuf((c), (stream)))
#define getchar()        getc(stdin)
#define putchar(c)       putc((c), stdout)

#include "../c_support/crt/stdio_v6z80p/sysapi.c"
#include "../c_support/crt/stdio_v6z80p/stdio_v6z80p.c"


#endif // STDIO_V6Z80P_H

