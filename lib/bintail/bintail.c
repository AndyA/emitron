/* Binary Tail.
 *
 * Follow a growing binary file starting at any offset
 * Follow a sequentially named series of files
 *
 */

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <getopt.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>

#define BUFSIZE (1024 * 1024)
#define SLEEP 100000

static int verbose = 0;

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

static void usage(const char *prog) {
  fprintf(stderr, "Usage: %s [options] <file>...\n\n"
          "Options:\n"
          "  -v,      --verbose        Verbose output\n"
          "  -h,      --help           See this text\n\n", prog);
  exit(1);
}

static void parse_options(int *argc, char ***argv) {
  const char *prog = (*argv)[0];
  int ch;

  static struct option opts[] = {
    {"help", no_argument, NULL, 'h'},
    {"verbose", no_argument, NULL, 'v'},
    {NULL, 0, NULL, 0}
  };

  while (ch = getopt_long(*argc, *argv, "hv", opts, NULL), ch != -1) {
    switch (ch) {
    case 'v':
      verbose++;
      break;
    case 'h':
    default:
      usage(prog);
    }
  }

  *argc -= optind;
  *argv += optind;

  if (*argc == 0) {
    usage(prog);
  }
}

static void tail(int outfd, int nfile, char *file[]) {
  unsigned char *buf = alloc(BUFSIZE);

  while (nfile-- > 0) {
    const char *fn = *file++;
    const char *nfn = nfile > 0 ? *file : NULL;
    int fd = open(fn, O_RDONLY | O_LARGEFILE);

    if (!fd) {
      warn("Can't read %s: %s", fn, strerror(errno));
      continue;
    }

    mention("Tailing %s", fn);

    for (;;) {
      ssize_t got = read(fd, buf, BUFSIZE);

      if (got == (ssize_t) - 1) {
        warn("I/O error on %s: %s", fn, strerror(errno));
        goto skip;
      }

      if (got == 0) { // eof
        if (nfn) {
          struct stat st;
          if (0 == stat(nfn, &st)) goto skip;
        }

        usleep(SLEEP);

        if ((off_t) - 1 == lseek(fd, 0, SEEK_CUR)) {
          warn("Failed to tail %s: %s", fn, strerror(errno));
          goto skip;
        }

        continue;
      }
      write(outfd, buf, got);
    }

  skip:
    close(fd);
  }

  free(buf);
}

int main(int argc, char *argv[]) {
  parse_options(&argc, &argv);
  tail(1, argc, argv);
  return 0;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
