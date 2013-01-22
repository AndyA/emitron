/* basic.t */

#include <stdio.h>
#include <string.h>

#include "util.h"
#include "tap.h"
#include "jd_test.h"
#include "dynatron.h"

static void make_messages(jd_var *out, int n) {
  jd_var json = JD_INIT, msg = JD_INIT;
  int i;

  jd_set_array(out, n);

  jd_set_string(&json, "{\"verb\":\"listen\"}");
  jd_from_json(&msg, &json);

  for (i = 0; i < n ; i++) {
    jd_set_int(jd_lv(&msg, "$.config.instance"), i);
    jd_clone(jd_push(out, 1), &msg, 1);
  }

  jd_release(&msg);
  jd_release(&json);
}

static void test_multiple(void) {
  jd_var msgs = JD_INIT, buf = JD_INIT, got = JD_INIT;

  make_messages(&msgs, 3);

  jd_set_empty_string(&buf, 1);

  {
    int i;
    dy_io_writer *wr = dy_io_new_var_writer(&buf);

    for (i = 0; i < jd_count(&msgs); i++) {
      dy_message_write(jd_get_idx(&msgs, i), wr);
    }

    dy_io_free_writer(wr);
  }

  jd_set_array(&got, 1);
  {
    dy_io_reader *rd = dy_io_new_var_reader(&buf);
    jd_var msg = JD_INIT;
    while (dy_message_read(&msg, rd)) {
      jd_assign(jd_push(&got, 1), &msg);
    }
    jd_release(&msg);
    dy_io_free_reader(rd);
  }

  jdt_is(&got, &msgs, "multiple messages");

  jd_release(&buf);
  jd_release(&got);
  jd_release(&msgs);
}

static void test_single(void) {
  jd_var msg = JD_INIT, json = JD_INIT, out = JD_INIT, msg2 = JD_INIT;

  jd_set_string(&json, "{\"verb\":\"listen\"}");
  jd_from_json(&msg, &json);

  jd_set_empty_string(&out, 1);

  {
    dy_io_writer *wr = dy_io_new_var_writer(&out);
    dy_message_write(&msg, wr);
    dy_io_free_writer(wr);
  }

  jdt_is_json(&out, "\"17\\n{\\\"verb\\\":\\\"listen\\\"}\"", "message written");

  {
    dy_io_reader *rd = dy_io_new_var_reader(&out);
    jd_var *got = dy_message_read(&msg2, rd);
    dy_io_free_reader(rd);
    not_null(got, "read msg");
  }

  jdt_is(&msg2, &msg, "msg roundtripped");

  jd_release(&msg);
  jd_release(&msg2);
  jd_release(&out);
  jd_release(&json);
}

void test_main(void) {
  test_single();
  test_multiple();
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
