.PHONY: all clean tags install

PREFIX ?= /usr/local

CFLAGS=-Wall -O2 -D_LARGEFILE64_SOURCE
LDFLAGS=-lc -lm -lpthread

BINS=fatcat
BINOBJS=$(addsuffix .o,$(BINS))
MISCOBJS=
OBJS=$(BINOBJS) $(MISCOBJS)
DEPS=$(OBJS:.o=.d) 
INST_BINS=$(PREFIX)/bin

all: $(BINS)

%: %.o $(MISCOBJS)
	cc -o $@ $^ $(LDFLAGS)

%.d: %.c
	@$(SHELL) -ec '$(CC) -MM $(CFLAGS) $< \
	| sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@; \
	[ -s $@ ] || rm -f $@'

include $(DEPS)

tags:
	ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .

clean:
	rm -f $(OBJS) $(DEPS) $(BINS) tags

install:
	install -s -m 770 $(BINS) $(INST_BINS)
