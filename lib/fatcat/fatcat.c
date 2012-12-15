/* Fat Cat
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>

#include <getopt.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>

#include "buffer.h"
#include "utils.h"

#define BUFSIZE (1024 * 1024)

static int verbose = 0;
static int decouple = 0;
static size_t bufsize = BUFSIZE;
static const char *infile;

static void mention(const char *msg, ...) {
  if (verbose) {
    va_list ap;
    va_start(ap, msg);
    vfprintf(stderr, msg, ap);
    fprintf(stderr, "\n");
    va_end(ap);
  }
}

static size_t get_size(const char *opt) {
  ssize_t sz = parse_size(opt);
  if ((ssize_t) - 1 == sz) die("Badly formed size: %s", opt);
  return (size_t) sz;
}

static void usage(const char *prog) {
  fprintf(stderr, "Usage: %s [options] <file>...\n\n"
          "Options:\n"
          "  -i             <file>     Input file\n"
          "  -b             <size>     Buffer size\n"
          "  -d, --decouple            Use a buffer for each writer\n"
          "  -h, --help                See this text\n"
          "  -v, --verbose             Verbose output\n"
          "\n", prog);
  exit(1);
}

static void parse_options(int *argc, char ***argv) {
  const char *prog = (*argv)[0];
  int ch, oidx;

  static struct option opts[] = {
    {"decouple", no_argument, NULL, 'd'},
    {"help", no_argument, NULL, 'h'},
    {"verbose", no_argument, NULL, 'v'},
    {NULL, 0, NULL, 0}
  };

  while (ch = getopt_long(*argc, *argv, "dhvb:i:", opts, &oidx), ch != -1) {
    switch (ch) {
    case 'i':
      infile = optarg;
      break;
    case 'b':
      bufsize = get_size(optarg);
      break;
    case 'd':
      decouple++;
      break;
    case 'h':
    default:
      usage(prog);
    case 'v':
      verbose++;
      break;
    }
  }

  *argc -= optind;
  *argv += optind;

  if (*argc == 0) {
    usage(prog);
  }
}

static void fatcat(int nfile, char *file[]) {
  printf("%lu\n", bufsize);
}

int main(int argc, char *argv[]) {
  parse_options(&argc, &argv);
  fatcat(argc, argv);
  return 0;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
