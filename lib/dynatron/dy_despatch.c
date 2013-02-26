/* dy_despatch.c */

#include <pthread.h>

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

static jd_var despatch = JD_INIT;
static dy_queue *queue;

jd_var *dy_despatch_register(const char *verb, jd_closure_func f) {
  return dy_set_handler(&despatch, verb, f);
}

void dy_despatch_enqueue(jd_var *msg) {
  dy_queue_enqueue(queue, msg);
}

void dy_despatch_message(jd_var *msg) {
  jd_var *verb = jd_rv(msg, "$.verb");
  if (!verb) {
    dy_error("Message with no verb");
    return;
  }
  jd_var *cl = jd_get_key(&despatch, verb, 0);
  if (cl) jd_call(cl, msg);
  else dy_error("No handler for %s", jd_bytes(verb, NULL));
}

static void get_message(jd_var *msg) {
  dy_queue_dequeue(queue, msg);
}

void dy_despatch_thread(jd_var *arg) {
  dy_info("Starting despatcher");
  for (;;) {
    jd_var msg = JD_INIT;
    get_message(&msg);
    dy_despatch_message(&msg);
    jd_release(&msg);
  }
}

void dy_despatch_init(void) {
  jd_set_hash(&despatch, 10);
  queue = dy_queue_new();
}

void dy_despatch_destroy(void) {
  jd_release(&despatch);
  dy_queue_free(queue);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
