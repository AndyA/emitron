/* dy_thread.c */

#include <pthread.h>

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

typedef void (*dy_worker)(jd_var *arg);

struct thread_context {
  pthread_t thd;
  dy_worker worker;
  jd_var arg;
  struct thread_context *next;
};

static struct thread_context *active = NULL;
static pthread_mutex_t active_mutex = PTHREAD_MUTEX_INITIALIZER;

static struct thread_context *unlink(struct thread_context *this,
                                     struct thread_context *node) {
  if (this == node) return this->next;
  this->next = unlink(this->next, node);
  return this;
}

static void free_thread(struct thread_context *ctx) {
  jd_release(&ctx->arg);
  jd_free(ctx);
}

static void remove_thread(struct thread_context *ctx) {
  pthread_mutex_lock(&active_mutex);
  active = unlink(active, ctx);
  pthread_mutex_unlock(&active_mutex);
  free_thread(ctx);
}

static void add_thread(struct thread_context *ctx) {
  pthread_mutex_lock(&active_mutex);
  ctx->next = active;
  active = ctx;
  pthread_mutex_unlock(&active_mutex);
}

size_t dy_thread_count(void) {
  struct thread_context *ctx;
  size_t count;
  for (count = 0, ctx = active; ctx; ctx = ctx->next)
    count++;
  return count;
}

static void *wrapper(void *ctxp) {
  struct thread_context *ctx = ctxp;
  ctx->worker(&ctx->arg);
  remove_thread(ctx);
  return NULL;
}

static void create_thread(dy_worker worker, jd_var *arg) {
  struct thread_context *ctx = jd_alloc(sizeof(struct thread_context));
  pthread_attr_t attr;

  ctx->worker = worker;
  jd_clone(&ctx->arg, arg, 1);

  if (pthread_attr_init(&attr)) goto fail;
  /* TODO explicit stack size? */
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
  if (pthread_create(&ctx->thd, NULL, wrapper, ctx)) goto fail;
  pthread_attr_destroy(&attr);

  add_thread(ctx);
  return;

fail:
  die("Can't create thread: %m");
}

void dy_thread_create(dy_worker worker, jd_var *arg) {
  if (arg) {
    create_thread(worker, arg);
  }
  else {
    jd_var tmp = JD_INIT;
    create_thread(worker, &tmp);
    jd_release(&tmp);
  }
}

static void join_thread(struct thread_context *ctx) {
  void *status;
  pthread_join(ctx->thd, &status);
  free_thread(ctx);
}

void dy_thread_join_all(void) {
  struct thread_context *ctx, *next;
  dy_info("Waiting for threads to terminate");
  for (ctx = active; ctx; ctx = next) {
    next = ctx->next;
    join_thread(ctx);
  }
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
