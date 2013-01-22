/* dy_log.c */

#include "dynatron.h"
#include "utils.h"

#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <time.h>

#define TS_FORMAT "%Y/%m/%d %H:%M:%S"

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

unsigned dy_log_level = DEBUG;

static const char *lvl[] = {
  "DEBUG",
  "NOTICE",
  "INFO",
  "WARNING",
  "ERROR",
  "FATAL"
};

static void ts(char *buf, size_t sz) {
  time_t t = time(NULL);
  struct tm *tmp;
  tmp = gmtime(&t);
  if (!tmp) die("gmtime failed: %m");
  strftime(buf, sz, TS_FORMAT, tmp);
}

static void split_lines(jd_var *out, jd_var *v) {
  jd_var sep = JD_INIT;
  jd_set_string(&sep, "\n");
  jd_split(out, v, &sep);
  jd_release(&sep);
}

static void dy_log(unsigned level, const char *msg, va_list ap) {
  if (level >= dy_log_level) {
    char tmp[30];
    int i;
    size_t count;
    jd_var ldr = JD_INIT, str = JD_INIT, ln = JD_INIT;

    pthread_mutex_lock(&mutex);

    ts(tmp, sizeof(tmp));
    jd_printf(&ldr, "%s | %-7s | ", tmp, lvl[level]);
    jd_vprintf(&str, msg, ap);
    split_lines(&ln, &str);
    count = jd_count(&ln);
    for (i = 0; i < count; i++) {
      printf("%s%s\n", jd_bytes(&ldr, NULL),
             jd_bytes(jd_get_idx(&ln, i), NULL));
    }

    jd_release(&ldr);
    jd_release(&ln);
    jd_release(&str);

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
LOGGER(dy_notice,   NOTICE)
LOGGER(dy_info,     INFO)
LOGGER(dy_warning,  WARNING)
LOGGER(dy_error,    ERROR)
LOGGER(dy_fatal,    FATAL)

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
