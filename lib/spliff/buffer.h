/* buffer.h */

#ifndef __BUFFER_H
#define __BUFFER_H

#include <stdlib.h>
#include <sys/uio.h>
#include <pthread.h>

typedef struct buffer buffer;

typedef struct buffer_reader {
  unsigned long pos;
  struct buffer_reader *next;
  buffer *b;
} buffer_reader;

struct buffer {
  unsigned char *b;
  size_t size;
  unsigned long pos;
  buffer_reader *br;
  int eof;
  pthread_mutex_t mutex;
  pthread_cond_t can_read;
  pthread_cond_t can_write;
};

typedef struct {
  struct iovec iov[2];
  int iovcnt;
} buffer_iov;

buffer *b_new(size_t sz);
void b_free(buffer *b);
buffer_reader *b_add_reader(buffer *b);
void b_eof(buffer *b);

size_t b_space(buffer *b);
size_t b_get_input(buffer *b, buffer_iov *bi);
void b_commit_input(buffer *b, size_t len);
size_t b_wait_input(buffer *b, buffer_iov *bi);

size_t b_available(buffer_reader *br);
size_t b_get_output(buffer_reader *br, buffer_iov *bi);
void b_commit_output(buffer_reader *br, size_t len);
size_t b_wait_output(buffer_reader *br, buffer_iov *bi);

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
