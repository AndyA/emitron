/* Fat Cat
 */

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

#include "utils.h"
#include "buffer.h"

#define BUFSIZE (1024 * 1024)

static size_t bufsize = BUFSIZE;
static const char *infile;

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
          "  -h, --help                See this text\n"
          "\n", prog);
  exit(1);
}

static void parse_options(int *argc, char ***argv) {
  const char *prog = (*argv)[0];
  int ch, oidx;

  static struct option opts[] = {
    {"help", no_argument, NULL, 'h'},
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
    case 'h':
    default:
      usage(prog);
    }
  }

  *argc -= optind;
  *argv += optind;
}

struct wtr_ctx {
  buffer_reader *br;
  int fd;
  pthread_t t;
};

static void *writer(void *ctx) {
  struct wtr_ctx *cx = (struct wtr_ctx *) ctx;
  for (;;) {
    buffer_iov iov;
    size_t spc = b_wait_output(cx->br, &iov);
    if (spc == 0) break;
    ssize_t put = writev(cx->fd, iov.iov, iov.iovcnt);
    if (put < 0) die("I/O error: %s", strerror(errno));
    b_commit_output(cx->br, put);
  }
  return NULL;
}

static struct wtr_ctx *add_writer(buffer *b, int fd) {
  struct wtr_ctx *ctx = alloc(sizeof(struct wtr_ctx));
  ctx->br = b_add_reader(b);
  ctx->fd = fd;
  pthread_create(&ctx->t, NULL, writer, ctx);
  return ctx;
}

static void fatcat(int nfile, char *file[]) {
  buffer *b = b_new(bufsize);
  struct wtr_ctx **ws = alloc(nfile * sizeof(struct wtr_ctx *));
  int wi = 0, i;
  int ifd = 0;

  if (infile) {
    ifd = open(infile, O_RDONLY);
    if (ifd < 0) die("Can't read %s: %s", infile, strerror(errno));
  }

  if (nfile) {
    while (nfile) {
      int fd = open(file[wi], O_WRONLY | O_CREAT, 0666);
      if (fd < 0) die("Can't write %s: %s", file[wi], strerror(errno));
      ws[wi++] = add_writer(b, fd);
      nfile--;
    }
  }
  else {
    ws[wi++] = add_writer(b, 1); // stdout
  }

  for (;;) {
    buffer_iov iov;
    b_wait_input(b, &iov);
    ssize_t got = readv(ifd, iov.iov, iov.iovcnt);
    if (got < 0) die("I/O error: %s", strerror(errno));
    if (got == 0) break;
    b_commit_input(b, got);
  }

  b_eof(b);

  for (i = 0; i < wi; i++) {
    void *rv;
    pthread_join(ws[i]->t, &rv);
    if (ws[i]->fd > 2) close(ws[i]->fd);
  }

  if (ifd > 2) close(ifd);
  b_free(b);
}

int main(int argc, char *argv[]) {
  parse_options(&argc, &argv);
  fatcat(argc, argv);
  pthread_exit(NULL);
  return 0;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
