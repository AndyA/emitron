.PHONY: all clean tags install version test valgrind

include common.mk

PREFIX ?= /usr/local

BINS=dynatron
BINOBJS=$(addsuffix .o,$(BINS))
MISCOBJS=
OBJS=$(BINOBJS) $(MISCOBJS)
DEPS=$(OBJS:.o=.d) 
INST_BINS=$(PREFIX)/bin

AVLIBS=libavcodec libavformat libavutil libswscale

CFLAGS+=$(shell pkg-config --cflags $(AVLIBS))
LDFLAGS+=$(shell pkg-config --libs $(AVLIBS))

LDFLAGS+=-lpthread

all: $(BINS)

version.h: VERSION
	perl tools/version.pl > version.h

%: %.o $(MISCOBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

%.d: %.c version.h
	@$(SHELL) -ec '$(CC) -MM $(CFLAGS) $< \
	| sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@; \
	[ -s $@ ] || rm -f $@'

include $(DEPS)

tags:
	ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .

clean:
	rm -f $(OBJS) $(DEPS) $(BINS) tags version.h
#         $(MAKE) -C t clean

version:
	perl tools/bump_version.pl VERSION

test: $(LIB)
#         $(MAKE) -C t test

valgrind: $(LIB)
#         $(MAKE) -C t valgrind

install: $(BINS)
	touch VERSION
	$(MAKE)
	install -s -m 775 $(BINS) $(INST_BINS)
