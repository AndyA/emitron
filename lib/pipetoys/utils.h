/* utils.h */

#ifndef __UTILS_H
#define __UTILS_H

extern int verbose;

char *sstrdup(const char *s);
ssize_t parse_size(const char *opt);
void *alloc(size_t sz);
void die(const char *msg, ...);
void warn(const char *msg, ...);
void mention(const char *msg, ...);
void version();

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
