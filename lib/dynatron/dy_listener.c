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

static void listener(int rd, int wr, jd_var *arg) {

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
    listener(sock, sock, arg);
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
