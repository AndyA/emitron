/* dynatron.c */

#include <getopt.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "jd_pretty.h"
#include "dynatron.h"
#include "utils.h"

#define PROG "dynatron"

static void usage() {
  fprintf(stderr, "Usage: " PROG " [options] <json>...\n\n"
          "Options:\n"
          "  -h, --help           See this text\n"
          "  -V, --version        Show version\n"
          "\n" PROG " %s\n", v_info);
  exit(1);
}

static void parse_options(int *argc, char ***argv) {
  int ch, oidx;

  static struct option opts[] = {
    {"help", no_argument, NULL, 'h'},
    {"version", no_argument, NULL, 'V'},
    {NULL, 0, NULL, 0}
  };

  while (ch = getopt_long(*argc, *argv, "hV", opts, &oidx), ch != -1) {
    switch (ch) {
    case 'V':
      version();
      break;
    case 'h':
    default:
      usage();
    }
  }

  *argc -= optind;
  *argv += optind;
}

static void monitor(void) {
  for (;;) {
    sleep(10);
    dy_info("threads: %lu", (unsigned long) dy_thread_count());
  }
}

int main(int argc, char *argv[]) {
  int argn;
  parse_options(&argc, &argv);
  dy_init();

  dy_thread_create(dy_despatch_thread, NULL);

  for (argn = 0; argn < argc; argn++) scope {
    JD_SV(arg, argv[argn]);
    JD_VAR(msg);
    jd_from_json(msg, arg);
    dy_despatch_enqueue(msg);
  }

  monitor();
  dy_thread_join_all();

  dy_destroy();
  pthread_exit(NULL);
  return 0;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
