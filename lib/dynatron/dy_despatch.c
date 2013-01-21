/* dy_despatch.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

static jd_var despatch = JD_INIT;

jd_var *dy_despatch_register(const char *verb, jd_closure_func f) {
  return dy_set_handler(&despatch, verb, f);
}

void dy_despatch_message(jd_var *msg) {
  jd_var *verb = jd_rv(msg, "$.verb");
  if (!verb) die("Missing verb in message");
  jd_var *cl = jd_get_key(&despatch, verb, 0);
  if (!cl) die("No handler: %s\n", jd_bytes(verb, NULL));
  jd_call(cl, msg);
}

void dy_despatch_json(jd_var *json) {
  jd_var msg = JD_INIT;
  jd_from_json(&msg, json);
  dy_despatch_message(&msg);
  jd_release(&msg);
}

void dy_despatch_init(void) {
  jd_set_hash(&despatch, 10);
}

void dy_despatch_destroy(void) {
  jd_release(&despatch);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
