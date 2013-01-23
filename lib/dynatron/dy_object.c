/* dy_object.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

struct object_context {
  jd_var handler;
  dy_queue *msg_queue;
};

static jd_var registry = JD_INIT;

static int object_tell(jd_var *rv, jd_var *ctx, jd_var *arg) {
  dy_debug("tell object, ctx=%lJ, rv=%lJ, arg=%lJ", ctx, rv, arg);

  return 0;
}

void dy_object_init(void) {
  jd_set_hash(&registry, 10);
  dy_despatch_register("tell", object_tell);
}

void dy_object_destroy(void) {
  jd_release(&registry);
}

static struct object_context *ctx_new(void) {
  struct object_context *ctx = jd_alloc(sizeof(struct object_context));
  ctx->msg_queue = dy_queue_new();
  return ctx;
}

static void ctx_free(struct object_context *ctx) {
  dy_queue_free(ctx->msg_queue);
  jd_release(&ctx->handler);
  jd_free(ctx);
}

static void ctx_free_wrap(void *ctx) {
  ctx_free(ctx);
}

void dy_object_register(const char *name, jd_var *h) {
  jd_var nv = JD_INIT;
  jd_set_string(&nv, name);

  if (jd_get_key(&registry, &nv, 0)) {
    dy_listener_send_error("Object %s already registered", name);
  }
  else {
    struct object_context *ctx = ctx_new();
    jd_assign(&ctx->handler, h);
    jd_set_object(jd_get_key(&registry, &nv, 1), ctx, ctx_free_wrap);
    dy_info("Registered object %s", name);
    /* TODO send ack? */
  }

  jd_release(&nv);
}

void dy_object_unregister(const char *name) {
  jd_var nv = JD_INIT;
  jd_set_string(&nv, name);

  if (jd_get_key(&registry, &nv, 0)) {
    jd_delete_key(&registry, &nv, NULL);
    dy_info("Unregistered object %s", name);
    /* TODO send ack? */
  }
  else {
    dy_listener_send_error("Object %s not registered", name);
  }

  jd_release(&nv);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
