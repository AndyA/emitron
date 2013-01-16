/* jd_string.c */

#include "jsondata.h"

#include <string.h>
#include <stdio.h>
#include <stdarg.h>

jd_string *jd_string_init(jd_string *jds, size_t size) {
  jds->data = jd_alloc(size);
  jds->size = size;
  jds->used = 0;
  jds->hdr.refs = 1; /* or maybe 0... */
  return jds;
}

jd_string *jd_string_new(size_t size) {
  jd_string *jds = jd_alloc(sizeof(jd_string));
  jd_string_init(jds, size);
  jds->used = 1; /* trailing \0 */
  return jds;
}

jd_string *jd_string_empty(jd_string *jds) {
  jds->used = 1;
  jds->data[0] = '\0';
  return jds;
}

jd_string *jd_string_from(const char *s) {
  size_t len = strlen(s) + 1;
  jd_string *jds = jd_string_new(len);
  memcpy(jds->data, s, len);
  jds->used = len;
  return jds;
}

jd_string *jd_string_ensure(jd_string *jds, size_t size) {
  if (jds->size < size) {
    char *nstr = jd_alloc(size);
    memcpy(nstr, jds->data, jds->used);
    jd_free(jds->data);
    jds->data = nstr;
    jds->size = size;
  }
  return jds;
}

jd_string *jd_string_space(jd_string *jds, size_t minspace) {
  if (jds->size - jds->used < minspace) {
    size_t newsize = jds->used + minspace;
    if (newsize < jds->size * 2) newsize = jds->size * 2;
    return jd_string_ensure(jds, newsize);
  }
  return jds;
}

void jd_string_free(jd_string *jds) {
  jd_free(jds->data);
  jd_free(jds);
}

jd_string *jd_string_retain(jd_string *jds) {
  jds->hdr.refs++;
  return jds;
}

jd_string *jd_string_release(jd_string *jds) {
  if (jds->hdr.refs <= 1) {
    jd_string_free(jds);
    return NULL;
  }
  jds->hdr.refs--;
  return jds;
}

size_t jd_string_length(jd_string *jds) {
  return jds->used - 1;
}

jd_string *jd_string_append(jd_string *jds, jd_var *v) {
  jd_string *vs = jd_as_string(v);
  size_t len = jd_string_length(vs);
  jd_string_space(jds, len);
  memcpy(jds->data + jds->used - 1, vs->data, len + 1);
  jds->used += len;
  return jds;
}

int jd_string_compare(jd_string *jds, jd_var *v) {
  jd_string *vs = jd_as_string(v);
  size_t la = jd_string_length(jds);
  size_t lb = jd_string_length(vs);
  size_t lc = la < lb ? la : lb;
  int cmp = memcmp(jds->data, vs->data, lc);
  if (cmp) return cmp;
  return la < lb ? -1 : la > lb ? 1 : 0;
}

unsigned long jd_string_hashcalc(jd_string *jds) {
  unsigned long h = 0;
  size_t len = jd_string_length(jds);
  unsigned i;
  for (i = 0; i < len; i++) {
    h = 31 * h + jds->data[i];
  }
  return h;
}

jd_string *jd_string_vprintf(jd_string *jds, const char *fmt, va_list ap) {
  jd_string_empty(jds);
  for (;;) {
    va_list aq;
    va_copy(aq, ap);
    size_t sz = vsnprintf(jds->data, jds->size, fmt, aq);
    va_end(aq);
    if (sz < jds->size) {
      jds->used = sz + 1;
      return jds;
      break;
    }
    jd_string_ensure(jds, sz + 1);
  }
}

jd_string *jd_string_printf(jd_string *jds, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  jd_string_vprintf(jds, fmt, ap);
  va_end(ap);
  return jds;
}

jd_var *jd_string_sub(jd_string *jds, int from, int len, jd_var *out) {
  size_t sl = jd_string_length(jds);
  jd_string *jo;

  if (from < 0) from += sl;
  if (len <= 0 || from < 0 || from >= sl) {
    jd_set_string(out, "");
    return out;
  }
  if (from + len > sl) len = sl - from;
  jd_set_empty_string(out, len + 1);
  jo = jd_as_string(out);
  memcpy(jo->data, jds->data + from, len);
  jo->data[len] = '\0';
  jo->used = len + 1;
  return out;
}

static const char *memfind(const char *haystack, size_t hslen,
                           const char *needle, size_t nlen) {
  const char *hsend = haystack + hslen - nlen;

  while (haystack <= hsend) {
    if (memcmp(haystack, needle, nlen) == 0) return haystack;
    haystack++;
  }

  return NULL;
}

int jd_string_find(jd_string *jds, jd_var *pat, int from) {
  jd_string *ps = jd_as_string(pat);
  size_t sl = jd_string_length(jds);
  size_t pl = jd_string_length(ps);
  if (from < 0) from += sl;
  if (from < 0 || from + pl > sl) return -1;
  const char *hit = memfind(jds->data + from, sl - from, ps->data, pl);
  if (hit) return hit - jds->data;
  return -1;
}

jd_var *jd_string_split(jd_string *jds, jd_var *pat, jd_var *out) {
  int pos;
  jd_set_array(out, 10);
  for (pos = 0; ;) {
    int hit = jd_string_find(jds, pat, pos);
    if (hit == -1) break;
    jd_string_sub(jds, pos, hit - pos, jd_push(out, 1));
    pos = hit + 1;
  }
  jd_string_sub(jds, pos, jd_string_length(jds) - pos, jd_push(out, 1));
  return out;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
