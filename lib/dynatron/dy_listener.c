/* dy_listener.c */

#include <netinet/in.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

static dy_queue *queue;

static void listener(dy_io_reader *rd) {
  scope {
    JD_VAR(msg);
    while (dy_message_read(msg, rd)) {
      dy_debug("received: %lJ", msg);
      dy_despatch_enqueue(msg);
    }
  }
}

static void sender(dy_io_writer *wr) {
  for (;;) scope {
    JD_VAR(msg);
    dy_queue_dequeue(queue, msg);
    dy_message_write(msg, wr);
    dy_debug("sent: %lJ", msg);
  }
}

static void *li_shim(void *arg) {
  listener((dy_io_reader *) arg);
  return NULL;
}

static void shim(int r, int w, jd_var *arg) {
  dy_io_reader *rd = dy_io_new_reader(r, 16384);
  dy_io_writer *wr = dy_io_new_writer(w);
  pthread_t li;

  /* TODO thread creation here? */
  if (pthread_create(&li, NULL, li_shim, rd))
    die("Can't create thread: %m");

  sender(wr);
  pthread_join(li, NULL);

  dy_io_free_writer(wr);
  dy_io_free_reader(rd);
}

static void socket_listener(jd_var *arg) {
  int proto;
  struct sockaddr_in addr;

  dy_debug("Starting socket_listener");
  dy_debug("config: %lJ", arg);

  proto = socket(AF_INET, SOCK_STREAM, 0);
  if (proto < 0) die("Socket create failed: %m");

  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons(jd_get_int(jd_rv(arg, "$.config.port")));
  if (bind(proto, (struct sockaddr *)&addr, sizeof(addr)) < 0)
    die("Bind failed: %m");

  if (listen(proto, 0)) die("Listen failed: %m");

  for (;;) {
    struct sockaddr_in addr;
    socklen_t addrlen = sizeof(addr);
    int sock = accept(proto, (struct sockaddr *) &addr, &addrlen);
    dy_info("Control connection");
    shim(sock, sock, arg);
    close(sock);
  }
  close(proto);
}

static void merge(jd_var *out, const char *dflt, jd_var *in) {
  scope {
    JD_SV(json, dflt);
    jd_from_json(out, json);
    jd_merge(out, in, 0);
  }
}

static int listen_cb(jd_var *rv, jd_var *ctx, jd_var *arg) {
  scope {
    JD_VAR(conf);
    merge(conf, "{\"config\":{\"port\":6809}}", arg);
    dy_thread_create(socket_listener, conf);
  }
  return 0;
}

static int ping_cb(jd_var *rv, jd_var *ctx, jd_var *arg) {
  scope {
    JD_HV(info, 3);
    jd_set_string(jd_lv(info, "$.date"), v_date);
    jd_set_string(jd_lv(info, "$.version"), v_version);
    jd_set_string(jd_lv(info, "$.git_hash"), v_git_hash);
    dy_listener_send(info);

  }
  return 0;
}

void dy_listener_send(jd_var *msg) {
  dy_queue_enqueue(queue, msg);
}

void dy_listener_send_error(const char *msg, ...) {
  scope {
    JD_HV(vm, 4);
    JD_VAR(err);
    va_list ap;

    jd_set_hash(vm, 4);
    jd_set_string(jd_lv(vm, "$.type"), "error");
    va_start(ap, msg);
    jd_vprintf(err, msg, ap);
    dy_error("Sending error: %V", err);
    jd_assign(jd_lv(vm, "$.message"), err);
    va_end(ap);
    dy_listener_send(vm);
  }
}

void dy_listener_init(void) {
  queue = dy_queue_new();
  dy_despatch_register("listen", listen_cb);
  dy_despatch_register("ping", ping_cb);
}

void dy_listener_destroy(void) {
  dy_queue_free(queue);
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
