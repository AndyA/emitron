/* utils.c */

#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "utils.h"
#include "version.h"

int verbose = 0;

const char *v_git_hash = V_GIT_HASH;
const char *v_date = V_DATE;
const char *v_version = V_VERSION;
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

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
