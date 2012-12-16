/* buffer.c */

#include <stdio.h>

#include "utils.h"
#include "buffer.h"

buffer *b_new(size_t sz) {
  buffer *b = alloc(sizeof(buffer));
  b->size = sz + 1; // +1 byte because we don't want to ever be full
  b->b = alloc(b->size);
  pthread_mutex_init(&b->mutex, NULL);
  pthread_cond_init(&b->can_read, NULL);
  pthread_cond_init(&b->can_write, NULL);
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
  br->b = b;
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

static size_t _b_space(buffer *b) {
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

static size_t _b_available(buffer_reader *br) {
  buffer *b = br->b;
  ssize_t avail = b->pos - br->pos;
  if (avail < 0) avail += b->size;
  return avail;
}

size_t b_space(buffer *b) {
  pthread_mutex_lock(&b->mutex);
  size_t space = _b_space(b);
  pthread_mutex_unlock(&b->mutex);
  return space;
}

size_t b_available(buffer_reader *br) {
  buffer *b = br->b;
  pthread_mutex_lock(&b->mutex);
  size_t avail = _b_available(br);
  pthread_mutex_unlock(&b->mutex);
  return avail;
}

size_t b_get_input(buffer *b, buffer_iov *bi) {
  return _b_get_buf(b, bi, _b_space(b), b->pos);
}

size_t b_get_output(buffer_reader *br, buffer_iov *bi) {
  return _b_get_buf(br->b, bi, _b_available(br), br->pos);
}

void b_commit_input(buffer *b, size_t len) {
  if (len) {
    pthread_mutex_lock(&b->mutex);
    b->pos += len;
    if (b->pos >= b->size) b->pos -= b->size;
    pthread_mutex_unlock(&b->mutex);
    pthread_cond_broadcast(&b->can_read);
  }
}

void b_commit_output(buffer_reader *br, size_t len) {
  if (len) {
    buffer *b = br->b;
    pthread_mutex_lock(&b->mutex);
    br->pos += len;
    if (br->pos >= b->size) br->pos -= b->size;
    pthread_mutex_unlock(&b->mutex);
    pthread_cond_broadcast(&b->can_write);
  }
}

size_t b_wait_input(buffer *b, buffer_iov *bi) {
  size_t sz = 0;
  pthread_mutex_lock(&b->mutex);
  for (;;) {
    sz = b_get_input(b, bi);
    if (sz) break;
    pthread_cond_wait(&b->can_write, &b->mutex);
  }
  pthread_mutex_unlock(&b->mutex);
  return sz;
}

size_t b_wait_output(buffer_reader *br, buffer_iov *bi) {
  buffer *b = br->b;
  size_t sz = 0;
  pthread_mutex_lock(&b->mutex);
  for (;;) {
    sz = b_get_output(br, bi);
    if (sz || b->eof) break;
    pthread_cond_wait(&b->can_read, &b->mutex);
  }
  pthread_mutex_unlock(&b->mutex);
  return sz;
}

void b_eof(buffer *b) {
  b->eof = 1;
  pthread_cond_broadcast(&b->can_read);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
