/* dy_dummy.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

static int dummy_h(jd_var *rv, jd_var *ctx, jd_var *arg) {
  dy_debug("dummy object, ctx=%lJ, rv=%lJ, arg=%lJ", ctx, rv, arg);
  return 0;
}

void dy_dummy_init(void) {
  jd_var cl = JD_INIT;
  jd_set_closure(&cl, dummy_h);
  dy_object_register("dummy", &cl);
  jd_release(&cl);
}

void dy_dummy_destroy(void) {
  dy_object_unregister("dummy");
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
