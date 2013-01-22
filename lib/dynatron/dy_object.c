/* dy_object.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

static int object_new(jd_var *ctx, jd_var *rv, jd_var *arg) {
  dy_debug("Make object");

  return 0;
}

void dy_object_init(void) {
  dy_despatch_register("new", object_new);
}

void dy_object_destroy(void) {
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
