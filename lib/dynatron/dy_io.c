/* dy_io.c */

#include <unistd.h>

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

dy_io_reader *dy_io_new_reader(int fd, size_t size) {
  dy_io_reader *rd = jd_alloc(sizeof(dy_io_reader));
  rd->fd = fd;
  rd->size = size;
  rd->used = 0;
  rd->pos = 0;
  rd->buf = jd_alloc(size);
  return rd;
}

void dy_io_free_reader(dy_io_reader *rd) {
  jd_free(rd->buf);
  jd_free(rd);
}

ssize_t dy_io_fill(dy_io_reader *rd) {
  ssize_t got = read(rd->fd, rd->buf, rd->size);
  if (got <= 0) {
    if (got < 0) dy_error("read error: %m");
    return got;
  }
  rd->pos = 0;
  rd->used = got;
  return got;
}

void dy_io_consume(dy_io_reader *rd, size_t len) {
  rd->pos += len;
  if (rd->pos > rd->size) die("Out of range consume");
}

ssize_t dy_io_read(dy_io_reader *rd, char **bp) {
  if (rd->pos == rd->used) {
    ssize_t got = dy_io_fill(rd);
    if (got <= 0) return got;
  }
  *bp = rd->buf + rd->pos;
  return rd->used - rd->pos;
}

dy_io_writer *dy_io_new_writer(int fd) {
  dy_io_writer *wr = jd_alloc(sizeof(dy_io_writer));
  wr->type = NATIVE;
  wr->h.fd = fd;
  return wr;
}

dy_io_writer *dy_io_new_var_writer(jd_var *v) {
  dy_io_writer *wr = jd_alloc(sizeof(dy_io_writer));
  wr->type = VAR;
  jd_assign(&wr->h.v, v);
  return wr;
}

void dy_io_free_writer(dy_io_writer *wr) {
  switch (wr->type) {
  case NATIVE:
    break;
  case VAR:
    jd_release(&wr->h.v);
    break;
  }
  jd_free(wr);
}

ssize_t dy_io_write(dy_io_writer *wr, const void *buf, size_t len) {
  switch (wr->type) {
  case NATIVE: {
    ssize_t got = write(wr->h.fd, buf, len);
    if (got < 0)
      dy_error("write error: %m");
    return got;
  }
  case VAR:
    jd_append_bytes(&wr->h.v, buf, len);
    return len;
  }
  return 0;
}

jd_var *dy_io_getvar(dy_io_writer *wr) {
  switch (wr->type) {
  case NATIVE:
    die("No write buffer (native stream)");
  case VAR:
    return &wr->h.v;
  }
  return NULL;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
