/* dy_queue.c */

#include <pthread.h>

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

dy_queue *dy_queue_new(void) {
  dy_queue *q = jd_alloc(sizeof(dy_queue));
  jd_set_array(&q->queue, 10);
  pthread_mutex_init(&q->mutex, NULL);
  pthread_cond_init(&q->cond, NULL);
  return q;
}

void dy_queue_free(dy_queue *q) {
  jd_release(&q->queue);
  pthread_cond_destroy(&q->cond);
  pthread_mutex_destroy(&q->mutex);
  jd_free(q);
}

void dy_queue_enqueue(dy_queue *q, jd_var *msg) {
  pthread_mutex_lock(&q->mutex);
  jd_clone(jd_push(&q->queue, 1), msg, 1);
  pthread_cond_signal(&q->cond);
  pthread_mutex_unlock(&q->mutex);
}

void dy_queue_dequeue(dy_queue *q, jd_var *msg) {
  pthread_mutex_lock(&q->mutex);
  for (;;) {
    if (jd_count(&q->queue)) {
      jd_shift(&q->queue, 1, msg);
      pthread_mutex_unlock(&q->mutex);
      return;
    }
    pthread_cond_wait(&q->cond, &q->mutex);
  }
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
