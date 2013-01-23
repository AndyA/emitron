/* dy_object.c */

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

struct object_context {
  jd_var obj;
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
  jd_set_hash(&ctx->obj, 1);
  ctx->msg_queue = dy_queue_new();
  return ctx;
}

static void ctx_free(struct object_context *ctx) {
  dy_queue_free(ctx->msg_queue);
  jd_release(&ctx->obj);
  jd_free(ctx);
}

static void ctx_free_wrap(void *ctx) {
  ctx_free(ctx);
}

static struct object_context *find_obj(const char *name) {
  jd_var *slot = jd_get_ks(&registry, name, 0);
  if (slot) return (struct object_context *) jd_ptr(slot);
  return NULL;
}

void dy_object_invoke(jd_var *o, const char *method, jd_var *arg) {
  struct object_context *ctx = jd_ptr(o);
  jd_var *cl = jd_get_ks(&ctx->obj, method, 0);

  dy_debug("calling %s", method);

  if (!cl) {
    dy_listener_send_error("No method %s", method);
    return;
  }

  (void) jd_eval(cl, o, arg);
}

void dy_object_register(const char *name, jd_var *o, const char *inherit) {
  jd_var obj = JD_INIT;

  if (find_obj(name)) {
    dy_listener_send_error("Object %s already registered", name);
    return;
  }

  struct object_context *ctx = ctx_new();

  if (inherit) {
    struct object_context *super = find_obj(inherit);
    if (!super) {
      dy_listener_send_error("Can't find %s for %s to inherit from", inherit, name);
      return;
    }
    dy_debug("Inheriting %s from %s", name, inherit);
    jd_merge(&ctx->obj, &super->obj, 1);
  }

  jd_merge(&ctx->obj, o, 1);

  jd_set_object(&obj, ctx, ctx_free_wrap);
  jd_assign(jd_get_ks(&registry, name, 1), &obj);
  dy_info("Registered object %s", name);

  dy_object_invoke(&obj, "run", NULL);

  /* TODO send ack? */
  /* TODO start it */

  jd_release(&obj);
}

void dy_object_unregister(const char *name) {
  if (!find_obj(name)) {
    dy_listener_send_error("Object %s not registered", name);
    return;
  }

  jd_delete_ks(&registry, name, NULL);
  dy_info("Unregistered object %s", name);
  /* TODO send ack? */
}

/* helpers */

void dy_object_set_method(jd_var *obj, const char *name, jd_closure_func impl) {
  jd_var cl = JD_INIT;
  jd_set_closure(&cl, impl);
  jd_assign(jd_get_ks(obj, name, 1), &cl);
  jd_release(&cl);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
