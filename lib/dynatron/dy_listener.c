/* dy_listener.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <pthread.h>

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

static void listener(dy_io_reader *rd, dy_io_writer *wr, jd_var *arg) {
  jd_var msg = JD_INIT;
  while (dy_message_read(&msg, rd)) {
    jd_var json;
    jd_to_json_pretty(&json, &msg);
    dy_debug("Got message %s", jd_bytes(&json, NULL));
    jd_release(&json);
  }
  jd_release(&msg);
}

static void shim(int r, int w, jd_var *arg) {
  dy_io_reader *rd = dy_io_new_reader(r, 16384);
  dy_io_writer *wr = dy_io_new_writer(w);

  listener(rd, wr, arg);

  dy_io_free_writer(wr);
  dy_io_free_reader(rd);
}

static void socket_listener(jd_var *arg) {
  int proto;
  struct sockaddr_in addr;

  dy_debug("Starting socket_listener");

  proto = socket(AF_INET, SOCK_STREAM, 0);
  if (proto < 0) die("Socket create failed: %m");

  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons(6809);
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

static int listener_cb(jd_var *ctx, jd_var *rv, jd_var *arg) {
  dy_thread_create(socket_listener, arg);
  return 0;
}

void dy_listener_init(void) {
  dy_despatch_register("listen", listener_cb);
}

void dy_listener_destroy(void) {
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
