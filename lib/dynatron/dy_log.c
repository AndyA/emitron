/* dy_log.c */

#include "dynatron.h"
#include "utils.h"

#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define TS_FORMAT "%Y/%m/%d %H:%M:%S"

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

unsigned dy_log_level  = DEBUG;
unsigned dy_log_colour = 1;

#define X(x) #x,
static const char *lvl[] = {
  DY_ERROR_LEVELS
  NULL
};
#undef X

static const char *lvl_col[] = {
  "\x1b[41m" "\x1b[37m",  // ERROR    white on red
  "\x1b[41m" "\x1b[37m",  // FATAL    white on red
  "\x1b[31m",             // WARNING  red
  "\x1b[36m",             // INFO     cyan
  "\x1b[32m",             // DEBUG    green
};

#define COLOUR_RESET "\x1b[0m"

static void ts(char *buf, size_t sz) {
  struct timeval tv;
  struct tm *tmp;
  size_t len;
  gettimeofday(&tv, NULL);
  tmp = gmtime(&tv.tv_sec);
  if (!tmp) die("gmtime failed: %m");
  len = strftime(buf, sz, TS_FORMAT, tmp);
  snprintf(buf + len, sz - len, ".%06lu", (unsigned long) tv.tv_usec);
}

static void split_lines(jd_var *out, jd_var *v) {
  scope {
    JD_SV(sep, "\n");
    jd_split(out, v, sep);
  }
}

static void dy_log(unsigned level, const char *msg, va_list ap) {
  if (level <= dy_log_level) scope {
    char tmp[30];
    int i;
    size_t count;
    JD_3VARS(ldr, str, ln);

    ts(tmp, sizeof(tmp));
    jd_printf(ldr, "%s | %5lu | %-7s | ",
    tmp, (unsigned long) getpid(), lvl[level]);
    jd_vprintf(str, msg, ap);
    split_lines(ln, str);
    count = jd_count(ln);

    pthread_mutex_lock(&mutex);
    for (i = 0; i < count; i++) {
      fprintf(stderr, "%s%s%s%s\n",
              dy_log_colour ? lvl_col[level] : "",
              jd_bytes(ldr, NULL), jd_bytes(jd_get_idx(ln, i), NULL),
              dy_log_colour ? COLOUR_RESET : ""
             );
    }
    pthread_mutex_unlock(&mutex);
  }
}

#define LOGGER(name, level)          \
  void name(const char *msg, ...) {  \
    va_list ap;                      \
    va_start(ap, msg);               \
    dy_log(level, msg, ap);          \
    va_end(ap);                      \
  }

LOGGER(dy_debug,    DEBUG)
LOGGER(dy_info,     INFO)
LOGGER(dy_warning,  WARNING)
LOGGER(dy_error,    ERROR)
LOGGER(dy_fatal,    FATAL)

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
