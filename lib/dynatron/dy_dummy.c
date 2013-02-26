/* dy_dummy.c */

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

void dy_dummy_init(void) {
  scope dy_object_register("dummy", jd_nhv(1), "core");
}

void dy_dummy_destroy(void) {
  dy_object_unregister("dummy");
}


/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
