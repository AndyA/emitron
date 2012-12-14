/* Fat Cat
 */

#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <math.h>

#include <getopt.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

#include "buffer.h"

#define BUFSIZE (1024 * 1024)

static int verbose = 0;
static int decouple = 0;
static size_t bufsize = BUFSIZE;
static const char *infile;

static void die(const char *msg, ...) {
  va_list ap;
  va_start(ap, msg);
  fprintf(stderr, "Fatal: ");
  vfprintf(stderr, msg, ap);
  fprintf(stderr, "\n");
  va_end(ap);
  exit(1);
}

static void warn(const char *msg, ...) {
  va_list ap;
  va_start(ap, msg);
  fprintf(stderr, "Warning: ");
  vfprintf(stderr, msg, ap);
  fprintf(stderr, "\n");
  va_end(ap);
}

static void mention(const char *msg, ...) {
  if (verbose) {
    va_list ap;
    va_start(ap, msg);
    vfprintf(stderr, msg, ap);
    fprintf(stderr, "\n");
    va_end(ap);
  }
}

static void *alloc(size_t sz) {
  void *m = malloc(sz);
  if (!m) die("Out of memory");
  return m;
}

static char *sstrdup(const char *s) {
  size_t sz = strlen(s) + 1;
  char *ss = alloc(sz);
  memcpy(ss, s, sz);
  return ss;
}

// Slightly messy: if scale < 100 it's treated as a power of two.
// I can't think of any other way to express a large (>long long)
// power of two as a constant.
static struct {
  const char *name;
  double scale;
} size_unit[] = {
  // Standard units
  { "kB", 1e3 }, // kilobyte
  { "MB", 1e6 }, // megabyte
  { "GB", 1e9 }, // gigabyte
  { "TB", 1e12 }, // terabyte
  { "PB", 1e15 }, // petabyte
  { "EB", 1e18 }, // exabyte
  { "ZB", 1e21 }, // zettabyte
  { "YB", 1e24 }, // yottabyte
  { "KiB", 10 }, // kibibyte
  { "MiB", 20 }, // mebibyte
  { "GiB", 30 }, // gibibyte
  { "TiB", 40 }, // tebibyte
  { "PiB", 50 }, // pebibyte
  { "EiB", 60 }, // exbibyte
  { "ZiB", 70 }, // zebibyte
  { "YiB", 80 }, // yobibyte
  // Popular aliases
  { "K", 10 }, // kibibyte
  { "M", 20 }, // mebibyte
  { "G", 30 }, // gibibyte
  { "T", 40 }, // tebibyte
  { "P", 50 }, // pebibyte
  { "E", 60 }, // exbibyte
  { "Z", 70 }, // zebibyte
  { "Y", 80 }, // yobibyte
  // Let's be kind; we know what they mean
  { "k", 10 }, // kibibyte
  { "m", 20 }, // mebibyte
  { "g", 30 }, // gibibyte
  { "t", 40 }, // tebibyte
  { "p", 50 }, // pebibyte
  { "e", 60 }, // exbibyte
  { "z", 70 }, // zebibyte
  { "y", 80 }, // yobibyte
};

static ssize_t parse_size(const char *opt) {
  int i;
  char *end;
  double scale = 1;
  unsigned long val = strtoul(opt, &end, 10);

  if (end == opt) return -1;

  if (!*end)
    return (ssize_t) val * scale;

  for (i = 0; i < sizeof(size_unit) / sizeof(size_unit[0]); i++) {
    if (!strcmp(end, size_unit[i].name)) {
      scale = size_unit[i].scale;
      if (scale < 100) scale = pow(2, scale);
      return (ssize_t) val * scale;
    }
  }

  return -1;
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
