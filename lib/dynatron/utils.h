/* utils.h */

#ifndef __UTILS_H
#define __UTILS_H

extern int verbose;
extern const char *v_git_hash;
extern const char *v_date;
extern const char *v_version;
extern const char *v_info;

char *sstrdup(const char *s);
void *alloc(size_t sz);
void die(const char *msg, ...);
void warn(const char *msg, ...);
void mention(const char *msg, ...);
void version();

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
