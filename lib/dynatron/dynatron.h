/* dynatron.h */

#ifndef __DYNATRON_H
#define __DYNATRON_H

#include <stdlib.h>

#include "jsondata.h"

enum {
  DEBUG,
  NOTICE,
  INFO,
  WARNING,
  ERROR,
  FATAL
};

typedef enum {
  NATIVE,
  VAR
} dy_io_type;

typedef struct {
  dy_io_type type;
  union {
    struct {
      int fd;
      size_t size, used;
      char *buf;
    } n;
    jd_var v;
  } h;
  unsigned pos;
} dy_io_reader;

typedef struct {
  dy_io_type type;
  union {
    int fd;
    jd_var v;
  } h;
} dy_io_writer;

extern unsigned dy_log_level;

typedef void (*dy_worker)(jd_var *arg);

jd_var *dy_set_handler(jd_var *desp, const char *verb, jd_closure_func f);
void dy_init(void);
void dy_destroy(void);

void dy_debug(const char *msg, ...);
void dy_notice(const char *msg, ...);
void dy_info(const char *msg, ...);
void dy_warning(const char *msg, ...);
void dy_error(const char *msg, ...);
void dy_fatal(const char *msg, ...);

jd_var *dy_despatch_register(const char *verb, jd_closure_func f);
void dy_despatch_enqueue(jd_var *msg);
void dy_despatch_message(jd_var *msg);
void dy_despatch_thread(jd_var *arg);
void dy_despatch_init(void);
void dy_despatch_destroy(void);

void dy_listener_init(void);
void dy_listener_destroy(void);

void dy_object_init(void);
void dy_object_destroy(void);

void dy_thread_create(dy_worker worker, jd_var *arg);
void dy_thread_join_all(void);

dy_io_reader *dy_io_new_reader(int fd, size_t size);
dy_io_reader *dy_io_new_var_reader(jd_var *v);
void dy_io_free_reader(dy_io_reader *rd);
void dy_io_consume(dy_io_reader *rd, size_t len);
ssize_t dy_io_read(dy_io_reader *rd, char **bp);
dy_io_writer *dy_io_new_writer(int fd);
dy_io_writer *dy_io_new_var_writer(jd_var *v);
void dy_io_free_writer(dy_io_writer *wr);
ssize_t dy_io_write(dy_io_writer *wr, const void *buf, size_t len);
jd_var *dy_io_getvar(dy_io_writer *wr);

jd_var *dy_message_read(jd_var *out, dy_io_reader *rd);
void dy_message_write(jd_var *v, dy_io_writer *wr);

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
