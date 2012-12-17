/* utils.c */

#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "utils.h"
#include "version.h"

int verbose = 0;

const char *v_info = V_INFO;

void die(const char *msg, ...) {
  va_list ap;
  va_start(ap, msg);
  fprintf(stderr, "Fatal: ");
  vfprintf(stderr, msg, ap);
  fprintf(stderr, "\n");
  va_end(ap);
  exit(1);
}

void warn(const char *msg, ...) {
  va_list ap;
  va_start(ap, msg);
  fprintf(stderr, "Warning: ");
  vfprintf(stderr, msg, ap);
  fprintf(stderr, "\n");
  va_end(ap);
}

void mention(const char *msg, ...) {
  if (verbose) {
    va_list ap;
    va_start(ap, msg);
    vfprintf(stderr, msg, ap);
    fprintf(stderr, "\n");
    va_end(ap);
  }
}

void version() {
  fprintf(stderr, "%s\n", v_info);
  exit(0);
}

void *alloc(size_t sz) {
  void *m = malloc(sz);
  if (!m) die("Out of memory");
  memset(m, 0, sz);
  return m;
}

char *sstrdup(const char *s) {
  if (!s) return NULL;
  size_t sz = strlen(s) + 1;
  char *ss = alloc(sz);
  memcpy(ss, s, sz);
  return ss;
}

// Slightly messy: if scale < 100 it's treated as a power of two.
// I can't think of any other way to express a large (>long long)
// power of two as a constant.
static struct {
  const char *name;
  double scale;
} size_unit[] = {
  // Standard units
  { "kB", 1e3 }, // kilobyte
  { "MB", 1e6 }, // megabyte
  { "GB", 1e9 }, // gigabyte
  { "TB", 1e12 }, // terabyte
  { "PB", 1e15 }, // petabyte
  { "EB", 1e18 }, // exabyte
  { "ZB", 1e21 }, // zettabyte
  { "YB", 1e24 }, // yottabyte
  { "KiB", 10 }, // kibibyte
  { "MiB", 20 }, // mebibyte
  { "GiB", 30 }, // gibibyte
  { "TiB", 40 }, // tebibyte
  { "PiB", 50 }, // pebibyte
  { "EiB", 60 }, // exbibyte
  { "ZiB", 70 }, // zebibyte
  { "YiB", 80 }, // yobibyte
  // Popular aliases
  { "K", 10 }, // kibibyte
  { "M", 20 }, // mebibyte
  { "G", 30 }, // gibibyte
  { "T", 40 }, // tebibyte
  { "P", 50 }, // pebibyte
  { "E", 60 }, // exbibyte
  { "Z", 70 }, // zebibyte
  { "Y", 80 }, // yobibyte
  // Let's be kind; we know what they mean
  { "k", 10 }, // kibibyte
  { "m", 20 }, // mebibyte
  { "g", 30 }, // gibibyte
  { "t", 40 }, // tebibyte
  { "p", 50 }, // pebibyte
  { "e", 60 }, // exbibyte
  { "z", 70 }, // zebibyte
  { "y", 80 }, // yobibyte
};

ssize_t parse_size(const char *opt) {
  int i;
  char *end;
  double scale = 1;
  unsigned long val = strtoul(opt, &end, 10);

  if (end == opt) return -1;

  if (!*end)
    return (ssize_t) val * scale;

  for (i = 0; i < sizeof(size_unit) / sizeof(size_unit[0]); i++) {
    if (!strcmp(end, size_unit[i].name)) {
      scale = size_unit[i].scale;
      if (scale < 100) scale = pow(2, scale);
      double bs = val * scale;
      if (bs > (size_t) - 1) die("Too large");
      return bs;
    }
  }

  return -1;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
