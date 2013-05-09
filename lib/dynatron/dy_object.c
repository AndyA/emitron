/* dy_object.c */

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

struct object_context {
  jd_var name, obj;
  dy_queue *queue;
};

static jd_var registry = JD_INIT;

static struct object_context *ctx_new(void) {
  struct object_context *ctx = jd_alloc(sizeof(struct object_context));
  jd_set_hash(&ctx->obj, 1);
  ctx->queue = dy_queue_new();
  return ctx;
}

static void ctx_free(struct object_context *ctx) {
  dy_queue_free(ctx->queue);
  jd_release(&ctx->obj);
  jd_release(&ctx->name);
  jd_free(ctx);
}

static void ctx_free_wrap(void *ctx) {
  ctx_free(ctx);
}

static struct object_context *get_ctx(jd_var *o) {
  return (struct object_context *) jd_ptr(o);
}

static struct object_context *find_obj(const char *name) {
  jd_var *slot = jd_get_ks(&registry, name, 0);
  return slot ? get_ctx(slot) : NULL;
}

/* TODO this is the top level of the worker thread so need to catch
 * exceptions here so they don't try to propagate back into the main
 * thread. That would be bad. 
 */
static void object_worker(jd_var *obj) {
  dy_object_invoke(obj, "run", NULL);
}

static int object_tell(jd_var *rv, jd_var *ctx, jd_var *arg) {

  /* TODO make this more general; dy_object_broadcast perhaps */

  jd_var *targ = jd_get_ks(arg, "target", 0);
  if (!targ) {
    dy_listener_send_error("No target in %lJ", arg);
    return 0;
  }

  jd_var *msg = jd_get_ks(arg, "msg", 0);
  if (!msg) {
    dy_listener_send_error("No message in %lJ", arg);
    return 0;
  }

  dy_debug("tell %J message %lJ", targ, msg);
  size_t count = jd_count(targ);
  unsigned i;

  for (i = 0; i < count; i++) {
    jd_var *name = jd_get_idx(targ, i);
    jd_var *obj = jd_get_key(&registry, name, 0);
    if (!obj) {
      dy_listener_send_error("No object %J", name);
      continue;
    }
    struct object_context *ctx = get_ctx(obj);
    dy_queue_enqueue(ctx->queue, msg);
  }

  return 0;
}

void dy_object_init(void) {
  jd_set_hash(&registry, 10);
  dy_despatch_register("tell", object_tell);
}

void dy_object_destroy(void) {
  jd_release(&registry);
}

void dy_object_register(const char *name, jd_var *o, const char *inherit) {
  scope {
    JD_VAR(obj);

    if (find_obj(name)) {
      dy_listener_send_error("Object %s already registered", name);
      JD_RETURN_VOID;
    }

    struct object_context *ctx = ctx_new();
    jd_set_string(&ctx->name, name);

    if (inherit) {
      struct object_context *super = find_obj(inherit);
      if (!super) {
        dy_listener_send_error("Can't find %s for %s to inherit from", inherit, name);
        JD_RETURN_VOID;
      }
      dy_debug("Inheriting %s from %s", name, inherit);
      jd_merge(&ctx->obj, &super->obj, 1);
    }

    jd_merge(&ctx->obj, o, 1);

    jd_set_object(obj, ctx, ctx_free_wrap);
    jd_assign(jd_get_ks(&registry, name, 1), obj);
    dy_info("Registered object %s", name);


    /* TODO send ack? */
    dy_thread_create(object_worker, obj);
  }
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

void dy_object_set_method(jd_var *obj, const char *method, jd_closure_func impl) {
  scope {
    jd_assign(jd_get_ks(obj, method, 1), jd_ncv(impl));
  }
}

int dy_object_invokev(jd_var *o, jd_var *method, jd_var *arg) {
  struct object_context *ctx = get_ctx(o);
  jd_var *cl = jd_get_key(&ctx->obj, method, 0);

  if (!cl) {
    dy_warning("%J has no method %V", o, method);
    return 0;
  }

  dy_debug("calling %V on %J", method, o);
  (void) jd_eval(cl, o, arg);
  return 1;
}

int dy_object_invoke(jd_var *o, const char *method, jd_var *arg) {
  scope {
    JD_RETURN(dy_object_invokev(o, jd_nsv(method), arg));
  }
  return 0;
}

void dy_object_get_message(jd_var *o, jd_var *msg) {
  struct object_context *ctx = get_ctx(o);
  dy_queue_dequeue(ctx->queue, msg);
}

void dy_object_name(jd_var *o, jd_var *name) {
  struct object_context *ctx = get_ctx(o);
  jd_assign(name, &ctx->name);
}

void dy_object_stash(jd_var *o, jd_var *stash) {
  struct object_context *ctx = get_ctx(o);
  jd_assign(stash, &ctx->obj);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
