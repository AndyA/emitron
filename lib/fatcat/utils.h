/* utils.h */

#ifndef __UTILS_H
#define __UTILS_H

char *sstrdup(const char *s);
ssize_t parse_size(const char *opt);
void *alloc(size_t sz);
void die(const char *msg, ...);
void warn(const char *msg, ...);

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
