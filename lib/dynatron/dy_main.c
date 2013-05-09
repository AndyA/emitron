/* dy_main.c */

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

jd_var *dy_set_handler(jd_var *desp, const char *verb, jd_closure_func f) {
  scope {
    JD_RETURN(jd_assign(jd_get_ks(desp, verb, 1), jd_ncv(f)));
  }
  return NULL;
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
