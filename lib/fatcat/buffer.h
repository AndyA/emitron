/* buffer.h */

#ifndef __BUFFER_H
#define __BUFFER_H

#include <stdlib.h>
#include <sys/uio.h>

typedef struct buffer_reader {
  unsigned long pos;
  struct buffer_reader *next;
} buffer_reader;

typedef struct {
  unsigned char *b;
  size_t size;
  unsigned long pos;
  buffer_reader *br;
} buffer;

typedef struct {
  struct iovec iov[2];
  int iovcnt;
} buffer_iov;

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
