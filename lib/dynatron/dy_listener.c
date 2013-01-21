/* dy_listener.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include "jsondata.h"
#include "dynatron.h"
#include "utils.h"

static int listener_cb(jd_var *ctx, jd_var *rv, jd_var *arg) {
  dy_debug("Start listener");

  return 0;
}

void dy_listener_init(void) {
  dy_despatch_register("listen", listener_cb);
}

void dy_listener_destroy(void) {
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
