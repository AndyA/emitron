/* dy_despatch.c */

#include <pthread.h>

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

static jd_var despatch = JD_INIT;
static pthread_mutex_t qmutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t qcond = PTHREAD_COND_INITIALIZER;

static jd_var queue = JD_INIT;

jd_var *dy_despatch_register(const char *verb, jd_closure_func f) {
  return dy_set_handler(&despatch, verb, f);
}

void dy_despatch_enqueue(jd_var *msg) {
  pthread_mutex_lock(&qmutex);
  jd_assign(jd_push(&queue, 1), msg);
  pthread_cond_signal(&qcond);
  pthread_mutex_unlock(&qmutex);
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
  pthread_mutex_lock(&qmutex);
  for (;;) {
    if (jd_count(&queue)) {
      jd_shift(&queue, 1, msg);
      pthread_mutex_unlock(&qmutex);
      return;
    }
    pthread_cond_wait(&qcond, &qmutex);
  }
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
  jd_set_array(&queue, 10);
}

void dy_despatch_destroy(void) {
  jd_release(&despatch);
  jd_release(&queue);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
