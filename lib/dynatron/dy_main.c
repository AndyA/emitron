/* dy_main.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

jd_var *dy_set_handler(jd_var *desp, const char *verb, jd_closure_func f) {
  jd_var cl  = JD_INIT;
  jd_var *slot;

  jd_set_closure(&cl, f);

  slot = jd_assign(jd_get_ks(desp, verb, 1), &cl);

  jd_release(&cl);

  return slot;
}

void dy_init(void) {
  /* NOTE init order matters */
  dy_despatch_init();
  dy_object_init();
  dy_listener_init();

  /* Objects */
  dy_core_init();
  dy_dummy_init();
}

void dy_destroy(void) {
  /* NOTE destroy order matters */
  dy_dummy_destroy();
  dy_core_destroy();

  dy_listener_destroy();
  dy_object_destroy();
  dy_despatch_destroy();
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
