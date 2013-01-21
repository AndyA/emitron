/* dynatron.h */

#ifndef __DYNATRON_H
#define __DYNATRON_H

jd_var *dy_set_handler(jd_var *desp, const char *verb, jd_closure_func f);
void dy_init(void);
void dy_destroy(void);

jd_var *dy_despatch_register(const char *verb, jd_closure_func f);
void dy_despatch_message(jd_var *msg);
void dy_despatch_json(jd_var *json);
void dy_despatch_init(void);
void dy_despatch_destroy(void);

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
