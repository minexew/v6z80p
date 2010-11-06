//
// stdio_v6z80p.c
//
// Standard I/O routines for V6Z80P.
//

/*#include <os.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <stdarg.h>
#include <crtbase.h>

#define SHELL "sh.exe"
*/


int output(FILE *stream, const char *format, va_list args);
int input(FILE *stream, const unsigned char *format, va_list arglist);

#define bigbuf(s) ((s)->flag & (_IOOWNBUF | _IOEXTBUF | _IOTMPBUF))
#define anybuf(s) ((s)->flag & (_IOOWNBUF | _IOEXTBUF | _IOTMPBUF | _IONBF))
#define inuse(s)  ((s)->flag & (_IORD |_IOWR |_IORW))

/*
void init_stdio()
{
  struct job *job = gettib()->job;
  struct crtbase *crtbase = (struct crtbase *) job->crtbase;

  crtbase->iob[0].file = job->in;
  crtbase->iob[0].base = crtbase->iob[0].ptr = crtbase->stdinbuf;
  crtbase->iob[0].flag = _IORD | _IOEXTBUF;
  crtbase->iob[0].bufsiz = BUFSIZ;

  crtbase->iob[1].file = job->out;
  crtbase->iob[1].flag = _IOWR | _IONBF | _IOCRLF;

  crtbase->iob[2].file = job->err;
  crtbase->iob[2].flag = _IOWR | _IONBF | _IOCRLF;

  crtbase->opt.err = 1;
  crtbase->opt.ind = 1;
  crtbase->opt.sp = 1;
}

FILE *__getstdhndl(int n)
{
  struct job *job = gettib()->job;
  struct crtbase *crtbase = (struct crtbase *) job->crtbase;

  return &crtbase->iob[n];
}

static void getbuf(FILE *stream)
{
  // Try to get a buffer
  if (stream->base = malloc(BUFSIZ))
  {
    // Got a buffer
    stream->flag |= _IOOWNBUF;
    stream->bufsiz = BUFSIZ;
  }
  else 
  {
    // Did NOT get a buffer - use single char buffering.
    stream->flag |= _IONBF;
    stream->base = (char *) &stream->charbuf;
    stream->bufsiz = 1;
  }

  stream->ptr = stream->base;
  stream->cnt = 0;
}

static void freebuf(FILE *stream)
{
  if (stream->flag & _IOOWNBUF)
  {
    free(stream->base);
    stream->flag &= ~_IOOWNBUF;
    stream->base = stream->ptr = NULL;
    stream->cnt = 0;
  }
}

static int stbuf(FILE *stream, char *buf, int bufsiz)
{
  // Setup temp buffering
  stream->base = stream->ptr = buf;
  stream->cnt = bufsiz;
  stream->flag |= (_IOWR | _IOTMPBUF | _IOEXTBUF);

  return 0;
}

static void ftbuf(FILE *stream)
{
  if (stream->flag & _IOTMPBUF)
  {
    // Flush the stream and tear down temp buffering
    fflush(stream);
    stream->flag &= ~(_IOEXTBUF | _IOTMPBUF);
    stream->bufsiz = 0;
    stream->base = stream->ptr = NULL;
  }
}

int filbuf(FILE *stream)
{
  if (stream->flag & _IOSTR) return EOF;

  if (stream->flag & _IOWR) 
  {
    stream->flag |= _IOERR;
    return EOF;
  }

  stream->flag |= _IORD;

  // Get a buffer, if necessary.
  if (!anybuf(stream))
    getbuf(stream);
  else
    stream->ptr = stream->base;

  stream->cnt = read(fileno(stream), stream->base, stream->bufsiz);

  if (stream->cnt <= 0)
  {
    stream->flag |= stream->cnt ? _IOERR : _IOEOF;
    stream->cnt = 0;
    return EOF;
  }

  stream->cnt--;

  return *stream->ptr++ & 0xff;
}

int flsbuf(int ch, FILE *stream)
{
  int count;
  int written;
  int fh;
  char chbuf;

  fh = fileno(stream);

  if (!(stream->flag & (_IOWR | _IORW)) || (stream->flag & _IOSTR))
  {
    stream->flag |= _IOERR;
    return -1;
  }

  if (stream->flag & _IORD) 
  {
    stream->cnt = 0;
    if (stream->flag & _IOEOF) 
    {
      stream->ptr = stream->base;
      stream->flag &= ~_IORD;
    }
    else 
    {
      stream->flag |= _IOERR;
      return -1;
    }
  }

  stream->flag |= _IOWR;
  stream->flag &= ~_IOEOF;
  written = count = stream->cnt = 0;

  // Get a buffer for this stream, if necessary
  if (!anybuf(stream)) getbuf(stream);

  // If big buffer is assigned to stream
  if (bigbuf(stream)) 
  {
    count = stream->ptr - stream->base;
    stream->ptr = stream->base + 1;
    stream->cnt = stream->bufsiz - 1;

    if (count > 0) written = write(fh, stream->base, count);

    *stream->base = (char) ch;
  }
  else 
  {
    // Perform single character output (either _IONBF or no buffering)
    count = 1;
    chbuf = (char) ch;
    written = write(fh, &chbuf, count);
  }

  // See if the write was successful.
  if (written != count) 
  {
    stream->flag |= _IOERR;
    return -1;
  }

  return ch & 0xff;
}
*/

static int open_file(FILE *stream, const char *filename, const char *mode)
{
  int oflag;
  int streamflag;
  handle_t handle;

  switch (*mode)
  {
    case 'r':
      oflag = O_RDONLY;
      streamflag = _IORD;
      break;

    case 'w':
      oflag = O_WRONLY | O_CREAT | O_TRUNC;
      streamflag = _IOWR;
      break;

    case 'a':
      oflag = O_WRONLY | O_CREAT | O_APPEND;
      streamflag = _IOWR;
      break;
  
    default:
      errno = EINVAL;
      return -1;
  }

  while (*++mode)
  {
    switch (*mode)
    {
      case '+':
        oflag |= O_RDWR;
        oflag &= ~(O_RDONLY | O_WRONLY);
        streamflag |= _IORW;
        streamflag &= ~(_IORD | _IOWR);
        break;

      case 't':
        oflag &= ~(O_TEXT | O_BINARY);
        oflag |= O_TEXT;
        break;

      case 'b':
        oflag &= ~(O_TEXT | O_BINARY);
        oflag |= O_BINARY;
        break;

      case 'c':
      case 'n':
        break;

      case 'S':
        oflag |= O_SEQUENTIAL;
        break;

      case 'R':
        oflag |= O_RANDOM;
        break;

      case 'T':
        oflag |= O_SHORT_LIVED;
        break;

      case 'D':
        oflag |= O_TEMPORARY;
        break;

      case ' ':
        // Ignore
        break;

      default:
        errno = EINVAL;
        return -1;
    }
  }

  handle = open(filename, oflag/*, S_IREAD | S_IWRITE*/);
  if (handle < 0) return -1;

  stream->flag = streamflag;
  stream->cnt = 0;
  stream->base = stream->ptr = NULL;
//  stream->file = handle;
//  stream->phndl = NOHANDLE;

  return 0;
}

/*
static int close_file(FILE *stream)
{
  int rc = EOF;

  if (stream->flag & _IOSTR) 
  {
    stream->flag = 0;
    return EOF;
  }

  rc = fflush(stream);
  freebuf(stream);

  if (close(fileno(stream)) < 0) rc = EOF;

  return rc;
}

FILE *fdopen(int fd, const char *mode)
{
  FILE *stream; 
  int streamflag;

  switch (*mode)
  {
    case 'r':
      streamflag = _IORD;
      break;

    case 'w':
      streamflag = _IOWR;
      break;

    case 'a':
      streamflag = _IOWR;
      break;
  
    default:
      errno = EINVAL;
      return NULL;
  }

  while (*++mode)
  {
    switch (*mode)
    {
      case '+':
        streamflag |= _IORW;
        streamflag &= ~(_IORD | _IOWR);
        break;
    }
  }

  stream = malloc(sizeof(FILE));
  if (!stream)
  {
    errno = ENFILE;
    return NULL;
  }

  stream->flag = streamflag;
  stream->cnt = 0;
  stream->base = stream->ptr = NULL;
  stream->file = fd;
  stream->phndl = NOHANDLE;

  return stream;
}

FILE *freopen(const char *filename, const char *mode, FILE *stream)
{ 
  if (inuse(stream)) close_file(stream);
  if (open_file(stream, filename, mode) < 0)
  {
    free(stream);
    return NULL;
  }

  return stream;
}
*/

struct {
    FILE arrFILE[4];
} stdio_v6z80p;

FILE *fopen(const char *filename, const char *mode)
{
  FILE *stream;

  // allocate memory for stream
  stream = &stdio_v6z80p.arrFILE[0];

  if (!stream)
  {
    errno = ENFILE;
    return NULL;
  }

  if (open_file(stream, filename, mode) < 0)
  {
    //free(stream);
    return NULL;
  }

  return stream;
}

/*
FILE *popen(const char *command, const char *mode)
{
  char cmdline[1024];
  int rc;
  int hndl[2];
  int phndl;
  struct tib *tib;
  struct job *job;
  FILE *f;

  if (!command)
  {
    errno = EINVAL;
    return NULL;
  }

  if (strlen(command) + strlen(SHELL) + 1 >= sizeof(cmdline))
  {
    errno = E2BIG;
    return NULL;
  }

  strcpy(cmdline, SHELL);
  strcat(cmdline, " ");
  strcat(cmdline, command);

  phndl = spawn(P_SUSPEND, SHELL, cmdline, &tib);
  if (phndl < 0) return NULL;
  job = tib->job;

  rc = pipe(hndl);
  if (rc < 0) return NULL;

  if (*mode == 'w')
  {
    if (job->in != NOHANDLE) close(job->in);
    job->in = hndl[0];
    f = fdopen(hndl[1], mode);
  }
  else
  {
    if (job->out != NOHANDLE) close(job->out);
    job->out = hndl[1];
    f = fdopen(hndl[0], mode);
  }

  if (f == NULL) return NULL;
  f->phndl = phndl;
  resume(phndl);

  return f;
}

int pclose(FILE *stream)
{
  int rc;

  if (stream->flag & _IORD)
  {
    wait(stream->phndl, INFINITE);
    close(stream->phndl);
    rc = close_file(stream);
  }
  else
  {
    int phndl = stream->phndl;
    rc = close_file(stream);
    wait(phndl, INFINITE);
    close(phndl);
  }

  return rc;
}

void clearerr(FILE *stream)
{
  // Clear flags
  stream->flag &= ~(_IOERR | _IOEOF);
}

int fclose(FILE *stream)
{
  int rc;

  rc = close_file(stream);
  free(stream);
  return rc;
}

int fflush(FILE *stream)
{
  int rc = 0;
  int count;

  if ((stream->flag & (_IORD | _IOWR)) == _IOWR && 
      bigbuf(stream) && 
      (count = stream->ptr - stream->base) > 0)
  {
    if (write(fileno(stream), stream->base, count) == count) 
    {
      // If this is a read/write file, clear _IOWR so that next operation can be a read
      if (stream->flag & _IORW) stream->flag &= ~_IOWR;
    }
    else 
    {
      stream->flag |= _IOERR;
      rc = EOF;
    }
  }

  stream->ptr = stream->base;
  stream->cnt = 0;

  return rc;
}

int fgetc(FILE *stream)
{
  return getc(stream);
}

int fputc(int c, FILE *stream)
{
  return putc(c, stream);
}

char *fgets(char *string, int n, FILE *stream)
{
  char *ptr = string;
  int ch;

  if (n <= 0) return NULL;

  while (--n)
  {
    if ((ch = getc(stream)) == EOF)
    {
      if (ptr == string)  return NULL;
      break;
    }

    if ((*ptr++ = ch) == '\n') break;
  }

  *ptr = '\0';
  return string;
}

int fputs(const char *string, FILE *stream)
{
  int len;
  int written;

  len = strlen(string);

  if (stream->flag & _IONBF)
  {
    char buf[BUFSIZ];

    stbuf(stream, buf, BUFSIZ);
    written = fwrite(string, 1, len, stream);
    ftbuf(stream);
  }
  else
    written = fwrite(string, 1, len, stream);

  return written == len ? 0 : EOF;
}

char *gets(char *buf)
{
  char *p = buf;
  int ch;

  while (1)
  {
    ch = getchar();
    if (ch == EOF)
    {
      if (errno == ETIMEDOUT) continue;
      return NULL;
    }

    if (ch == 8)
    {
      if (p > buf)
      {
        putchar('\b');
        putchar(' ');
        putchar('\b');
        p--;
      }
    }
    else if (ch == '\r' || ch =='\n' || ch >= ' ')
    {
      putchar(ch);
      if (ch == '\r') putchar('\n');
      if (ch == '\n' || ch == '\r') break;
      *p++ = ch;
    }
  }

  *p = 0;
  return buf;
}

int puts(const char *string)
{
  FILE *stream = stdout;

  if (stream->flag & _IONBF)
  {
    char buf[BUFSIZ];

    stbuf(stream, buf, BUFSIZ);

    while (*string) 
    {
      if (putchar(*string) == EOF)
      {
        ftbuf(stream);
        return EOF;
      }
      string++;
    }
  
    if (putchar('\n') == EOF) 
    {
      ftbuf(stream);
      return EOF;
    }

    ftbuf(stream);
  }
  else
  {
    while (*string) 
    {
      if (putchar(*string) == EOF) return EOF;
      string++;
    }
  
    if (putchar('\n') == EOF) return EOF;
  }

  return 0;
}

size_t fread(void *buffer, size_t size, size_t num, FILE *stream)
{
  char *data;                     // Point to where should be read next
  unsigned total;                 // Total bytes to read
  unsigned count;                 // Num bytes left to read
  unsigned bufsize;               // Size of stream buffer
  unsigned nbytes;                // How much to read now
  unsigned nread;                 // How much we did read
  int c;                          // A temp char

  // Initialize local vars
  data = buffer;

  if ((count = total = size * num) == 0) return 0;

  if (anybuf(stream))
    // Already has buffer, use its size
    bufsize = stream->bufsiz;
  else
    // Assume will get BUFSIZ buffer
    bufsize = BUFSIZ;

  // Here is the main loop -- we go through here until we're done
  while (count != 0) 
  {
    // if the buffer exists and has characters, copy them to user buffer
    if (anybuf(stream) && stream->cnt != 0) 
    {
      // How much do we want?
      nbytes = (count < (unsigned) stream->cnt) ? count : stream->cnt;
      memcpy(data, stream->ptr, nbytes);

      // Update stream and amount of data read
      count -= nbytes;
      stream->cnt -= nbytes;
      stream->ptr += nbytes;
      data += nbytes;
    }
    else if (count >= bufsize)
    {
      // If we have more than bufsize chars to read, get data
      // by calling read with an integral number of bufsiz
      // blocks.

      // Calc chars to read -- (count / bufsize) * bufsize
      nbytes = bufsize ? count - count % bufsize : count;

      nread = read(fileno(stream), data, nbytes);
      if (nread == 0) 
      {
        // End of file -- out of here
        stream->flag |= _IOEOF;
        return (total - count) / size;
      }
      else if ((int) nread < 0)
      {
        // Error -- out of here
        stream->flag |= _IOERR;
        return (total - count) / size;
      }

      // Update count and data to reflect read
      count -= nread;
      data += nread;
    }
    else 
    {
      // Less than bufsize chars to read, so call filbuf to fill buffer
      if ((c = filbuf(stream)) == EOF) 
      {
        // Error or eof, stream flags set by filbuf
        return (total - count) / size;
      }

      // filbuf returned a char -- store it
      *data++ = (char) c;
      count--;

      // Update buffer size
      bufsize = stream->bufsiz;
    }
  }

  // We finished successfully, so just return num
  return num;
}

size_t fwrite(const void *buffer, size_t size, size_t num, FILE *stream)
{
  const char *data;               // Point to where data comes from next
  unsigned total;                 // Total bytes to write
  unsigned count;                 // Num bytes left to write
  unsigned bufsize;               // Size of stream buffer
  unsigned nbytes;                // Number of bytes to write now
  unsigned nwritten;              // Number of bytes written
  int c;                          // A temp char

  // Initialize local vars
  data = buffer;
  count = total = size * num;
  if (count == 0) return 0;

  if (anybuf(stream))
    // Already has buffer, use its size
    bufsize = stream->bufsiz;
  else
    // Assume will get BUFSIZ buffer
    bufsize = BUFSIZ;

  // Here is the main loop -- we go through here until we're done
  while (count != 0) 
  {
    // If the buffer is big and has room, copy data to buffer
    if (bigbuf(stream) && stream->cnt != 0) 
    {
      // How much do we want?
      nbytes = (count < (unsigned) stream->cnt) ? count : stream->cnt;
      memcpy(stream->ptr, data, nbytes);

      // Update stream and amount of data written
      count -= nbytes;
      stream->cnt -= nbytes;
      stream->ptr += nbytes;
      data += nbytes;
    }
    else if (count >= bufsize) 
    {
      // If we have more than bufsize chars to write, write
      // data by calling write with an integral number of
      // bufsiz blocks.  If we reach here and we have a big
      // buffer, it must be full so flush it.

      if (bigbuf(stream)) 
      {
        if (fflush(stream)) 
        {
          // Error, stream flags set -- we're out of here
          return (total - count) / size;
        }
      }

      // Calc chars to write -- (count / bufsize) * bufsize
      nbytes = bufsize ? (count - count % bufsize) : count;
      nwritten = write(fileno(stream), data, nbytes);
      if ((int) nwritten < 0) 
      {
        // Error -- out of here
        stream->flag |= _IOERR;
        return (total - count) / size;
      }

      // Update count and data to reflect write
      count -= nwritten;
      data += nwritten;

      if (nwritten < nbytes) 
      {
        // Error -- out of here
        stream->flag |= _IOERR;
        return (total - count) / size;
      }
    }
    else 
    {
      // Buffer full and not enough chars to do direct write, so do a flsbuf.
      c = *data;  
      if (flsbuf(c, stream) == EOF) 
      {
        // Error or eof, stream flags set by _flsbuf
        return (total - count) / size;
      }

      // flsbuf wrote a char -- update count
      ++data;
      --count;

      // Update buffer size
      bufsize = stream->bufsiz > 0 ? stream->bufsiz : 1;
    }
  }

  // We finished successfully, so just return num
  return num;
}

int fseek(FILE *stream, long offset, int whence)
{
  if (whence != SEEK_SET && whence != SEEK_CUR && whence != SEEK_END)
  {
    errno = EINVAL;
    return -1;
  }

  // Clear EOF flag
  stream->flag &= ~_IOEOF;

  // Flush buffer as necessary
  fflush(stream);

  // If file opened for read/write, clear flags since we don't know
  // what the user is going to do next.
  if (stream->flag & _IORW) stream->flag &= ~(_IOWR | _IORD);

  // Seek to the desired location and return
  return lseek(fileno(stream), offset, whence) < 0 ? -1 : 0;
}

long ftell(FILE *stream)
{
  long filepos;

  if (stream->cnt < 0) stream->cnt = 0;    
  if ((filepos = tell(fileno(stream))) < 0L) return -1L;
  if (!bigbuf(stream)) return filepos - stream->cnt;

  if (stream->flag & _IORD)
    filepos -= stream->cnt;
  else if (stream->flag & _IOWR)
    filepos += (stream->ptr - stream->base);

  return filepos;
}

void rewind(FILE *stream)
{
  fseek(stream, 0L, SEEK_SET); 
  clearerr(stream);
}

int fsetpos(FILE *stream, const fpos_t *pos)
{
  return fseek(stream, *pos, SEEK_SET);
}

int fgetpos(FILE *stream, fpos_t *pos)
{
  long n;

  n = ftell(stream);
  if (n < 0) return n;
  *pos = n;
  return 0;
}

void perror(const char *message)
{
  fprintf(stderr, "%s: %s\n", message, strerror(errno));
}

void setbuf(FILE *stream, char *buffer)
{
  if (buffer == NULL)
    setvbuf(stream, NULL, _IONBF, 0);
  else
    setvbuf(stream, buffer, _IOFBF, BUFSIZ);
}

int setvbuf(FILE *stream, char *buffer, int type, size_t size)
{
  fflush(stream);
  freebuf(stream);

  stream->flag &= ~(_IOOWNBUF | _IOEXTBUF | _IONBF);

  if (type & _IONBF) 
  {
    stream->flag |= _IONBF;
    buffer = (char *) &stream->charbuf;
    size = 1;
  }
  else if (buffer == NULL)
  {
    if ((buffer = malloc(size)) == NULL ) return -1;
    stream->flag |= _IOOWNBUF;
  }
  else 
    stream->flag |= _IOEXTBUF;

  stream->bufsiz = size;
  stream->ptr = stream->base = buffer;
  stream->cnt = 0;

  return 0;
}

int ungetc(int c, FILE *stream)
{
  // Stream must be open for read and can NOT be currently in write mode.
  // Also, ungetc() character cannot be EOF.
  if (c == EOF) return EOF;
  if (!((stream->flag & _IORD) || ((stream->flag & _IORW) && !(stream->flag & _IOWR)))) return EOF;

  // If stream is unbuffered, get one.
  if (stream->base == NULL) getbuf(stream);

  // Now we know base != NULL; since file must be buffered

  if (stream->ptr == stream->base) 
  {
    if (stream->cnt) return EOF;
    stream->ptr++;
  }

  if (stream->flag & _IOSTR) 
  {
    // If stream opened by sscanf do not modify buffer
    if (*--stream->ptr != (char) c) 
    {
      ++stream->ptr;
      return EOF;
    }
  } 
  else
    *--stream->ptr = (char) c;

  stream->cnt++;
  stream->flag &= ~_IOEOF;
  stream->flag |= _IORD;

  return c & 0xff;
}

int remove(const char *filename)
{
  return unlink(filename);
}

static int gentmpfn(char *path, char *prefix, int unique, char *tempfn)
{
  const char *format = "%s%c%s%4.4x.tmp";
  int len;

  len = strlen(path);
  if (len > 0 && (path[len - 1] == PS1 || path[len - 1] == PS2)) len--;

  if (unique == 0) unique = clock();
  
  sprintf(tempfn, format, path, PS1, prefix, unique);
  while (access(tempfn, 0) == 0)
  {
    unique++;
    sprintf(tempfn, format, path, PS1, prefix, unique);
  }
  if (errno != ENOENT) return -1;

  return unique;
}

FILE *tmpfile()
{
  static int unique = 0;

  FILE *stream;
  char *path;
  char tempfn[MAXPATH];
  int rc;

  path = getenv("tmp");
  if (!path) path = "/tmp";

  stream = malloc(sizeof(FILE));
  if (!stream)
  {
    errno = ENFILE;
    return NULL;
  }

  while (1)
  {
    rc = gentmpfn(path, "t", unique, tempfn);
    if (rc < 0) return NULL;
    unique = rc;

    rc = open_file(stream, tempfn, "wb+TD");
    if (rc == 0) break;

    if (rc < 0 && errno != EEXIST)
    {
      free(stream);
      return NULL;
    }
  }

  return stream;
}

char *tmpnam(char *string)
{
  static int unique = 0;
  char *path;
  char *tempfn;
  int rc;

  if (string)
    tempfn = string;
  else
    tempfn = gettib()->tmpnambuf;
  
  path = getenv("tmp");
  if (!path) path = "/tmp";

  rc = gentmpfn(path, "s", 0, tempfn);
  if (rc < 0) return NULL;
  unique = rc;

  return tempfn;
}

char *tempnam(const char *dir, const char *prefix)
{
  static int unique = 0;
  char *path;
  char *tempfn;
  int rc;

  tempfn = gettib()->tmpnambuf;
  
  path = (char *) dir;
  if (!path) path = getenv("tmp");
  if (!path) path = ".";

  rc = gentmpfn(path, (char *) prefix, unique, tempfn);
  if (rc < 0) return NULL;
  unique = rc;

  return strdup(tempfn);
}

int vfprintf(FILE *stream, const char *fmt, va_list args)
{
  int rc;

  if (stream->flag & _IONBF)
  {
    char buf[BUFSIZ];

    stbuf(stream, buf, BUFSIZ);
    rc = output(stream, fmt, args);
    ftbuf(stream);
  }
  else
    rc = output(stream, fmt, args);

  return rc;
}

int fprintf(FILE *stream, const char *fmt, ...)
{
  int rc;
  va_list args;

  va_start(args, fmt);

  if (stream->flag & _IONBF)
  {
    char buf[BUFSIZ];

    stbuf(stream, buf, BUFSIZ);
    rc = output(stream, fmt, args);
    ftbuf(stream);
  }
  else
    rc = output(stream, fmt, args);

  return rc;
}

int vprintf(const char *fmt, va_list args)
{
  return vfprintf(stdout, fmt, args);
}

int printf(const char *fmt, ...)
{
  va_list args;

  va_start(args, fmt);
  return vfprintf(stdout, fmt, args);
}

int vsprintf(char *buf, const char *fmt, va_list args)
{
  FILE str;
  int rc;

  str.cnt = INT_MAX;
  str.flag = _IOWR | _IOSTR;
  str.ptr = str.base = buf;

  rc = output(&str, fmt, args);
  if (buf != NULL) putc('\0', &str);

  return rc;
}

int sprintf(char *buf, const char *fmt, ...)
{
  va_list args;
  FILE str;
  int rc;

  va_start(args, fmt);

  str.cnt = INT_MAX;
  str.flag = _IOWR | _IOSTR;
  str.ptr = str.base = buf;

  rc = output(&str, fmt, args);
  if (buf != NULL) putc('\0', &str);

  return rc;
}

int vsnprintf(char *buf, size_t count, const char *fmt, va_list args)
{
  FILE str;
  int rc;

  str.cnt = (int) count;
  str.flag = _IOWR | _IOSTR;
  str.ptr = str.base = buf;

  rc = output(&str, fmt, args);
  if (buf != NULL) putc('\0', &str);

  return rc;
}

int snprintf(char *buf, size_t count, const char *fmt, ...)
{
  va_list args;
  FILE str;
  int rc;

  va_start(args, fmt);

  str.cnt = (int) count;
  str.flag = _IOWR | _IOSTR;
  str.ptr = str.base = buf;

  rc = output(&str, fmt, args);
  if (buf != NULL) putc('\0', &str);

  return rc;
}

int fscanf(FILE *stream, const char *fmt, ...)
{
  int rc;
  va_list args;

  va_start(args, fmt);

  rc = input(stream, fmt, args);

  return rc;
}

int scanf(const char *fmt, ...)
{
  int rc;
  va_list args;

  va_start(args, fmt);

  rc = input(stdin, fmt, args);

  return rc;
}

int sscanf(const char *buffer, const char *fmt, ...)
{
  int rc;
  va_list args;
  FILE str;

  va_start(args, fmt);

  str.flag = _IORD | _IOSTR | _IOOWNBUF;
  str.ptr = str.base = (char *) buffer;
  str.cnt = strlen(buffer);
  rc = input(&str, fmt, args);

  return rc;
}
*/




