/* dy_message.c */

#include <ctype.h>
#include <unistd.h>

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

jd_var *dy_message_read(jd_var *out, dy_io_reader *rd) {
  size_t paylen = 0, want;
  jd_var json = JD_INIT;
  int state = 0;

  for (;;) {
    char *buf, *bp, *be;
    ssize_t got = dy_io_read(rd, &buf);
    if (got <= 0) {
      if (got < 0) dy_error("Error on listener: %m");
      jd_release(&json);
      return NULL;
    }
    bp = buf;
    be = buf + got;

    switch (state) {
    case 0:
      while (bp != be && !isdigit(*bp)) bp++;
      dy_io_consume(rd, bp - buf);
      if (bp != be) state = 1;
      break;
    case 1:
      while (bp != be && isdigit(*bp))
        paylen = paylen * 10 + *bp++ - '0';
      dy_io_consume(rd, bp - buf);
      if (bp != be) state = isspace(*bp) ? 2 : 0;
      break;
    case 2:
      while (bp != be && isspace(*bp)) bp++;
      dy_io_consume(rd, bp - buf);
      jd_set_empty_string(&json, 1000);
      state = 3;
      break;
    case 3:
      want = paylen;
      if (want > got) want = got;
      jd_append_bytes(&json, bp, want);
      dy_io_consume(rd, want);
      paylen -= want;
      if (paylen == 0) {
        jd_from_json(out, &json);
        jd_release(&json);
        return out;
      }
      break;
    default:
      die("Huh?");
    }
  }
}

static void format_message(jd_var *out, jd_var *v) {
  jd_var json = JD_INIT, msg = JD_INIT, sep = JD_INIT;

  jd_set_array(&msg, 2);
  jd_to_json(&json, v);
  jd_set_int(jd_push(&msg, 1), jd_length(&json));
  jd_assign(jd_push(&msg, 1), &json);
  jd_set_string(&sep, "\n");
  jd_join(out, &sep, &msg);

  jd_release(&json);
  jd_release(&msg);
  jd_release(&sep);
}

void dy_message_write(jd_var *v, dy_io_writer *wr) {
  jd_var msg = JD_INIT;
  size_t ml;
  const char *buf;

  format_message(&msg, v);
  buf = jd_bytes(&msg, &ml);
  dy_io_write(wr, buf, ml - 1);
  jd_release(&msg);
}


/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
