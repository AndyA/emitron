CFLAGS=-Wall -Werror -g2 -D_LARGEFILE64_SOURCE --std=c99
LDFLAGS=-lc -lm

ifneq ($(shell $(CC) -v 2>&1 | grep -i clang),)
CFLAGS+=-Qunused-arguments
endif

ifneq ($(COVER),)
CFLAGS+=-fprofile-arcs -ftest-coverage
LDFLAGS+=-lgcov
endif

ifneq ($(PROFILE),)
CFLAGS+=-pg
LDFLAGS+=-pg
endif
