.PHONY: all clean tags install

PREFIX ?= /usr/local

VPATH = ../common

CFLAGS=-Wall -g3 -I../common -D_LARGEFILE64_SOURCE
LDFLAGS=-lc

BINS=bintail
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
	install -s -m 770 -t $(INST_BINS) $(BINS)
