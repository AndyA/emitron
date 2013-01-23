/* dy_core.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

static int clone_h(jd_var *self, jd_var *ctx, jd_var *arg) {
  dy_debug("clone object, self=%lJ, ctx=%lJ, arg=%lJ", self,  ctx, arg);
  return 0;
}

static void despatch_message(jd_var *self, jd_var *msg) {
  jd_var *verb = jd_get_ks(msg, "verb", 0);
  if (!verb) {
    dy_listener_send_error("Message %lJ has no verb");
    return;
  }
  if (!dy_object_invokev(self, verb, msg)) {
    dy_debug("Message %J rejected", msg);
  }
}

static int run_h(jd_var *self, jd_var *ctx, jd_var *arg) {
  for (;;) {
    jd_var msg = JD_INIT;
    dy_object_get_message(self, &msg);
    dy_debug("%J got message %lJ", self, &msg);
    despatch_message(self, &msg);
    jd_release(&msg);
  }
  return 0;
}

void dy_core_init(void) {
  jd_var obj = JD_INIT;
  jd_set_hash(&obj, 1);

  dy_object_set_method(&obj, "clone", clone_h);
  dy_object_set_method(&obj, "run", run_h);

  dy_object_register("core", &obj, NULL);
  jd_release(&obj);
}

void dy_core_destroy(void) {
  dy_object_unregister("core");
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
