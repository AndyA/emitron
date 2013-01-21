/* dynatron.h */

#ifndef __DYNATRON_H
#define __DYNATRON_H

#include "jsondata.h"

enum {
  DEBUG,
  NOTICE,
  INFO,
  WARNING,
  ERROR,
  FATAL
};

extern unsigned dy_log_level;

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
void *dy_despatch_thread(void *tid);
void dy_despatch_init(void);
void dy_despatch_destroy(void);

void dy_listener_init(void);
void dy_listener_destroy(void);

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
