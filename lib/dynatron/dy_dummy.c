/* dy_dummy.c */

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

void dy_dummy_init(void) {
  jd_var obj = JD_INIT;
  jd_set_hash(&obj, 1);
  dy_object_register("dummy", &obj, "core");
  jd_release(&obj);
}

void dy_dummy_destroy(void) {
  dy_object_unregister("dummy");
}


/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
