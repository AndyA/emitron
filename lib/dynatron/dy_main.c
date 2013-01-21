/* dy_main.c */

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

#include "jsondata.h"
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

int main(int argc, char *argv[]) {
  int argn;
  jd_var arg;

  parse_options(&argc, &argv);
  dy_init();

  for (argn = 0; argn < argc; argn++) {
    jd_set_string(&arg, argv[argn]);
    dy_despatch_json(&arg);
  }

  jd_release(&arg);

  dy_destroy();
  return 0;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
