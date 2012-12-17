/* Binary Tail.
 *
 * Follow a growing binary file starting at any offset
 * Follow a sequentially named series of files
 *
 */

#include <ctype.h>
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
#include <time.h>

#include "utils.h"
#include "version.h"

#define PROG "tailpipe"
#define BUFSIZE (1024 * 1024)
#define SLEEP 100000

static int timeout = 0;
static int increment = 0;
static int filecount = -1;
static int waitfor = 0;
static int waitdelay = 0;
static int rmeach = 0;
static int outfd = 1;

static void usage() {
  fprintf(stderr, "Usage: " PROG " [options] <file>...\n\n"
          "Options:\n"
          "  -i, --increment           Follow numbered files\n"
          "  -t, --timeout <seconds>   How long to wait for file growth\n"
          "      --wait [=<seconds>]   Wait for first file\n"
          "  -D, --delete              Delete each file after reading it\n"
          "  -c, --count=<n>           Stop after n files\n"
          "  -o, --output=<file>       Output to file instead of stdout\n"
          "      --fd=<fd>             Output to fd instead of stdout\n"
          "  -h, --help                See this text\n"
          "  -v, --verbose             Verbose output\n"
          "  -V, --version             Show version\n"
          "\n" PROG " " V_INFO "\n");
  exit(1);
}

static void parse_options(int *argc, char ***argv) {
  int ch, oidx;

  static struct option opts[] = {
    {"delete", no_argument, NULL, 'D'},
    {"help", no_argument, NULL, 'h'},
    {"increment", no_argument, NULL, 'v'},
    {"fd", required_argument, NULL, 2},
    {"output", required_argument, NULL, 'o'},
    {"timeout", required_argument, NULL, 't'},
    {"count", required_argument, NULL, 'c'},
    {"verbose", no_argument, NULL, 'v'},
    {"wait", optional_argument, NULL, 1},
    {"version", no_argument, NULL, 'V'},
    {NULL, 0, NULL, 0}
  };

  while (ch = getopt_long(*argc, *argv, "DhivVc:t:o:", opts, &oidx), ch != -1) {
    switch (ch) {
    case 1:
      waitfor = 1;
      waitdelay = optarg ? atoi(optarg) : 0;
      break;
    case 2:
      outfd = atoi(optarg);
      break;
    case 'o':
      outfd = open(optarg, O_WRONLY | O_CREAT
#ifdef O_LARGEFILE
                   | O_LARGEFILE
#endif
                   , 0666
                  );
      if (outfd < 0) die("Can't write %s: %s", optarg, strerror(errno));
      break;
    case 'D':
      rmeach++;
      break;
    case 'h':
    default:
      usage();
    case 'i':
      increment++;
      break;
    case 't':
      timeout = atoi(optarg);
      break;
    case 'c':
      filecount = atoi(optarg);
      break;
    case 'V':
      version();
      break;
    case 'v':
      verbose++;
      break;
    }
  }

  *argc -= optind;
  *argv += optind;

  if (*argc == 0) {
    usage();
  }
}

static int exists(const char *fn) {
  struct stat st;
  return 0 == stat(fn, &st);
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

static char *next_name(char *name) {
  if (!increment) return NULL;
  char *nn = sstrdup(name);
  if (inc_name(nn)) {
    warn("Can't increment %s", name);
    free(nn);
    return NULL;
  }
  return nn;
}

static int wait_for(const char *fn, int seconds) {
  time_t deadline = time(NULL) + seconds;
  mention("Waiting for %s to be created", fn);
  while (seconds == 0 || time(NULL) < deadline) {
    if (exists(fn)) return 1;
    usleep(SLEEP);
  }
  return 0;
}

static void tail(int outfd, int nfile, char *file[]) {
  unsigned char *buf = alloc(BUFSIZE);
  enum { READING, WAITING } state = READING;
  time_t deadline;
  char *fn = sstrdup(*file++);
  nfile--;

  if (waitfor && !exists(fn) && !wait_for(fn, waitdelay)) {
    warn("%s didn't appear, giving up", fn);
    return;
  }

  while (fn && (filecount == -1 || filecount--)) {
    char *ifn = next_name(fn);
    char *nfn = nfile > 0 ? sstrdup(*file) : NULL;
    char *ofn = fn;

    int fd = open(fn, O_RDONLY
#ifdef O_LARGEFILE
                  | O_LARGEFILE
#endif
                 );

    if (fd < 0) {
      warn("Can't read %s: %s", fn, strerror(errno));
      fn = NULL;
      goto skip2;
    }

    mention("Tailing %s", fn);

    for (;;) {
      ssize_t got = read(fd, buf, BUFSIZE);

      if ((ssize_t) - 1 == got)
        die("I/O error on %s: %s", fn, strerror(errno));

      if (got == 0) { // eof
        time_t now = time(NULL);
        if (state == READING) {
          state = WAITING;
          deadline = now + timeout;
        }

        if (timeout && now >= deadline) {
          mention("Giving up waiting for %s to grow", fn);
          fn = NULL;
          goto skip;
        }

        if (ifn && exists(ifn)) {
          fn = ifn;
          ifn = NULL;
          goto skip;
        }

        if (nfn && exists(nfn)) {
          fn = nfn;
          nfn = NULL;
          file++;
          nfile--;
          goto skip;
        }

        usleep(SLEEP);

        if ((off_t) - 1 == lseek(fd, 0, SEEK_CUR)) {
          warn("Failed to tail %s: %s", fn, strerror(errno));
          fn = NULL;
          goto skip;
        }
      }
      else {
        while (got) {
          ssize_t put = write(outfd, buf, got);
          if ((ssize_t) - 1 == put)
            die("Write error: %s", strerror(errno));
          got -= put;
        }
        state = READING;
      }
    }

  skip:
    close(fd);
    if (rmeach) {
      mention("Deleting %s", ofn);
      if (unlink(ofn) < 0)
        warn("Failed to remove %s: %s", ofn, strerror(errno));
    }
  skip2:
    free(ofn);
    free(nfn);
    free(ifn);
  }

  free(buf);
}

int main(int argc, char *argv[]) {
  parse_options(&argc, &argv);
  tail(outfd, argc, argv);
  return 0;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
