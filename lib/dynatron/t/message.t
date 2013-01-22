/* basic.t */

#include <stdio.h>
#include <string.h>

#include "util.h"
#include "tap.h"
#include "jd_test.h"
#include "dynatron.h"

void test_main(void) {
  jd_var msg = JD_INIT, json = JD_INIT, out = JD_INIT;
  jd_set_empty_string(&out, 1);
  dy_io_writer *wr = dy_io_new_var_writer(&out);

  jd_set_string(&json, "{\"verb\":\"listen\"}");
  jd_from_json(&msg, &json);
  dy_message_write(&msg, wr);

  jdt_is_json(&out, "\"17\\n{\\\"verb\\\":\\\"listen\\\"}\"", "message written");
  dy_io_free_writer(wr);
  jd_release(&msg);
  jd_release(&out);
  jd_release(&json);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
