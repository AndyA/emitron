/* dy_io.c */

#include <unistd.h>

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

dy_io_reader *dy_io_new_reader(int fd, size_t size) {
  dy_io_reader *rd = jd_alloc(sizeof(dy_io_reader));
  rd->type = NATIVE;
  rd->h.n.fd = fd;
  rd->h.n.size = size;
  rd->h.n.used = 0;
  rd->pos = 0;
  rd->h.n.buf = jd_alloc(size);
  return rd;
}

dy_io_reader *dy_io_new_var_reader(jd_var *v) {
  dy_io_reader *rd = jd_alloc(sizeof(dy_io_reader));
  rd->type = VAR;
  jd_assign(&rd->h.v, v);
  rd->pos = 0;
  return rd;
}

void dy_io_free_reader(dy_io_reader *rd) {
  switch (rd->type) {
  case NATIVE:
    jd_free(rd->h.n.buf);
    break;
  case VAR:
    jd_release(&rd->h.v);
    break;
  }
  jd_free(rd);
}

static ssize_t fillbuf(dy_io_reader *rd) {
  ssize_t got = read(rd->h.n.fd, rd->h.n.buf, rd->h.n.size);
  if (got <= 0) {
    if (got < 0) dy_error("read error: %m");
    return got;
  }
  rd->pos = 0;
  rd->h.n.used = got;
  return got;
}

void dy_io_consume(dy_io_reader *rd, size_t len) {
  rd->pos += len;
}

ssize_t dy_io_read(dy_io_reader *rd, char **bp) {
  switch (rd->type) {
  case NATIVE:
    if (rd->pos == rd->h.n.used) {
      ssize_t got = fillbuf(rd);
      if (got <= 0) return got;
    }
    *bp = rd->h.n.buf + rd->pos;
    return rd->h.n.used - rd->pos;
  case VAR: {
    size_t len;
    const char *buf = jd_bytes(&rd->h.v, &len);
    *bp = (char *) buf + rd->pos;
    return len - rd->pos - 1;
  }
  }
  return 0;
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
