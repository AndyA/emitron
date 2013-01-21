/* dynatron.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

jd_var *dy_set_handler(jd_var *desp, const char *verb, jd_closure_func f) {
  jd_var key = JD_INIT;
  jd_var cl  = JD_INIT;
  jd_var *slot;

  jd_set_string(&key, verb);
  jd_set_closure(&cl, f);

  slot = jd_assign(jd_get_key(desp, &key, 1), &cl);

  jd_release(&key);
  jd_release(&cl);

  return slot;
}

void dy_init(void) {
  dy_despatch_init();
}

void dy_destroy(void) {
  dy_despatch_destroy();
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
