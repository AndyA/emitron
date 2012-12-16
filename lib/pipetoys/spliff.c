/* Spliff
 */

#include <ctype.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <getopt.h>

#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>

#include "buffer.h"
#include "utils.h"
#include "version.h"

#define BUFSIZE   (1024 * 1024)
#define SPLITSIZE (1024 * 1024)

static size_t bufsize = BUFSIZE;
static size_t splitsize = SPLITSIZE;
static const char *infile;

static size_t get_size(const char *opt) {
  ssize_t sz = parse_size(opt);
  if ((ssize_t) - 1 == sz) die("Badly formed size: %s", opt);
  return (size_t) sz;
}

static void usage(const char *prog) {
  fprintf(stderr, "Usage: %s [options] <file>\n\n"
          "Options:\n"
          "  -s, --size <size>    Chunk size\n"
          "  -i, --input  <file>  Input file\n"
          "  -b, --buffer <size>  Buffer size\n"
          "  -v, --verbose        Verbose output\n"
          "  -h, --help           See this text\n"
          "  -V, --version        Show version\n"
          "\n", prog);
  exit(1);
}

static void parse_options(int *argc, char ***argv) {
  const char *prog = (*argv)[0];
  int ch, oidx;

  static struct option opts[] = {
    {"help", no_argument, NULL, 'h'},
    {"verbose", no_argument, NULL, 'v'},
    {"input", required_argument, NULL, 'i'},
    {"size", required_argument, NULL, 's'},
    {"buffer", required_argument, NULL, 'b'},
    {"version", no_argument, NULL, 'V'},
    {NULL, 0, NULL, 0}
  };

  while (ch = getopt_long(*argc, *argv, "dhvVs:b:i:", opts, &oidx), ch != -1) {
    switch (ch) {
    case 'i':
      infile = optarg;
      break;
    case 'b':
      bufsize = get_size(optarg);
      break;
    case 's':
      splitsize = get_size(optarg);
      break;
    case 'V':
      version();
      break;
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

  if (*argc != 1) usage(prog);
}

static int inc_name(char *name) {
  int carry = 1;
  int pos = strlen(name) - 1;
  while (pos >= 0 && !isdigit(name[pos])) pos--;
  while (carry && pos >= 0 && isdigit(name[pos])) {
    name[pos]++;
    if (name[pos] == '9' + 1) name[pos--] = '0';
    else carry = 0;
  }
  return carry;
}

struct wtr_ctx {
  buffer_reader *br;
  char *file;
  pthread_t t;
};

static void next_name(struct wtr_ctx *cx) {
  char *nn = sstrdup(cx->file);
  if (inc_name(nn)) die("Can't increment %s", cx->file);
  free(cx->file);
  cx->file = nn;
}

static void clip_iov(struct iovec *iov, int *iovcnt, size_t limit) {
  size_t tot = 0;
  int i;
  for (i = 0; i < *iovcnt && tot < limit; i++) {
    if (tot + iov[i].iov_len > limit)
      iov[i].iov_len = limit - tot;
    tot += iov[i].iov_len;
  }
  *iovcnt = i;
}

static void *writer(void *ctx) {
  struct wtr_ctx *cx = (struct wtr_ctx *) ctx;
  int fd = -1;
  size_t cr = 0;
  int inc = 0;
  for (;;) {
    buffer_iov iov;
    size_t spc = b_wait_output(cx->br, &iov);
    if (spc == 0) break;

    if (fd == -1) {
      if (inc++) next_name(cx);
      fd = open(cx->file, O_WRONLY | O_CREAT
#ifdef O_LARGEFILE
                | O_LARGEFILE
#endif
                , 0666
               );
      if (fd < 0) die("Can't write %s: %s", cx->file, strerror(errno));
      mention("Writing %s", cx->file);
      cr = splitsize;
    }

    clip_iov(iov.iov, &iov.iovcnt, cr);
    ssize_t put = writev(fd, iov.iov, iov.iovcnt);
    if (put < 0) die("I/O error: %s", strerror(errno));
    b_commit_output(cx->br, put);
    cr -= put;

    if (cr == 0) {
      close(fd);
      fd = -1;
    }
  }
  if (fd > 2) close(fd);
  free(cx->file);
  return NULL;
}

static struct wtr_ctx *add_writer(buffer *b, char *file) {
  struct wtr_ctx *ctx = alloc(sizeof(struct wtr_ctx));
  ctx->br = b_add_reader(b);
  ctx->file = sstrdup(file);
  pthread_create(&ctx->t, NULL, writer, ctx);
  return ctx;
}

static void spliff(char *file) {
  buffer *b = b_new(bufsize);
  int ifd = 0;
  struct wtr_ctx *cx;

  if (infile) {
    ifd = open(infile, O_RDONLY
#ifdef O_LARGEFILE
               | O_LARGEFILE
#endif
              );
    if (ifd < 0) die("Can't read %s: %s", infile, strerror(errno));
  }

  cx = add_writer(b, file);

  for (;;) {
    buffer_iov iov;
    b_wait_input(b, &iov);
    ssize_t got = readv(ifd, iov.iov, iov.iovcnt);
    if (got < 0) die("I/O error: %s", strerror(errno));
    if (got == 0) break;
    b_commit_input(b, got);
  }

  b_eof(b);

  void *rv;
  pthread_join(cx->t, &rv);
  if (ifd > 2) close(ifd);
  b_free(b);
}

int main(int argc, char *argv[]) {
  parse_options(&argc, &argv);
  spliff(argv[0]);
  return 0;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
