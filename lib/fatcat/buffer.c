/* buffer.c */

#include <stdio.h>
#include <pthread.h>

#include "utils.h"
#include "buffer.h"

buffer *b_new(size_t sz) {
  buffer *b = alloc(sizeof(buffer));
  b->size = sz + 1; // +1 byte because we don't want to ever be full
  b->b = alloc(b->size);
  return b;
}

void b_free(buffer *b) {
  if (b) {
    buffer_reader *br, *next;
    for (br = b->br; br; br = next) {
      next = br->next;
      free(br);
    }
    free(b->b);
    free(b);
  }
}

buffer_reader *b_add_reader(buffer *b) {
  buffer_reader *br = alloc(sizeof(buffer_reader));
  br->next = b->br;
  b->br = br;
  return br;
}

static size_t _b_get_buf(const buffer *b, buffer_iov *bi,
                         size_t avail, unsigned long pos) {
  bi->iovcnt = 0;

  if (avail) {
    size_t tail = b->size - pos;
    bi->iovcnt++;
    bi->iov[0].iov_base = b->b + pos;
    if (avail <= tail) {
      bi->iov[0].iov_len = avail;
    }
    else {
      bi->iov[0].iov_len = tail;
      bi->iovcnt++;
      bi->iov[1].iov_base = b->b;
      bi->iov[1].iov_len = avail - tail;
    }
  }

  return avail;
}

size_t b_space(const buffer *b) {
  buffer_reader *br;
  size_t space = 0;
  for (br = b->br; br; br = br->next) {
    ssize_t sp = br->pos - b->pos;
    if (sp <= 0) sp += b->size;
    if (space == 0 || sp < space) space = sp;
  }
  if (space > 0) return space - 1;
  return 0;
}

size_t b_available(const buffer *b, const buffer_reader *br) {
  ssize_t avail = b->pos - br->pos;
  if (avail < 0) avail += b->size;
  return avail;
}

size_t b_get_input(const buffer *b, buffer_iov *bi) {
  return _b_get_buf(b, bi, b_space(b), b->pos);
}

size_t b_get_output(const buffer *b, const buffer_reader *br, buffer_iov *bi) {
  return _b_get_buf(b, bi, b_available(b, br), br->pos);
}

void b_commit_input(buffer *b, size_t len) {
  b->pos += len;
  if (b->pos >= b->size) b->pos -= b->size;
}

void b_commit_output(const buffer *b, buffer_reader *br, size_t len) {
  br->pos += len;
  if (br->pos >= b->size) br->pos -= b->size;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
