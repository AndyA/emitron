.PHONY: all clean tags install version test valgrind

include common.mk

PREFIX ?= /usr/local

BINS=dynatron
LIB=libdynatron.a
BINOBJS=$(addsuffix .o,$(BINS))
LIBOBJS=utils.o dy_message.o dy_despatch.o dy_main.o dy_log.o \
	 dy_listener.o dy_object.o dy_thread.o dy_io.o
OBJS=$(BINOBJS) $(LIBOBJS)
DEPS=$(OBJS:.o=.d) 
INST_BINS=$(PREFIX)/bin
MYLIBS=../jsondata/libjsondata.a

AVLIBS=libavcodec libavformat libavutil libswscale

CFLAGS+=-I../jsondata

CFLAGS+=$(shell pkg-config --cflags $(AVLIBS))
LDFLAGS+=$(shell pkg-config --libs $(AVLIBS))

LDFLAGS+=-lpthread

all: $(LIB) $(BINS)

$(LIB): $(LIBOBJS)
	ar rcs $@ $^

version.h: VERSION
	perl tools/version.pl > version.h

%: %.o $(LIB)
	$(CC) -o $@ $^ $(MYLIBS) $(LDFLAGS)

%.d: %.c version.h
	@$(SHELL) -ec '$(CC) -MM $(CFLAGS) $< \
	| sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@; \
	[ -s $@ ] || rm -f $@'

include $(DEPS)

tags:
	ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .

clean:
	rm -f $(OBJS) $(DEPS) $(BINS) tags version.h
	$(MAKE) -C t clean

version:
	perl tools/bump_version.pl VERSION

test: $(LIB)
	$(MAKE) -C t test

valgrind: $(LIB)
	$(MAKE) -C t valgrind

install: $(BINS)
	touch VERSION
	$(MAKE)
	install -s -m 775 $(BINS) $(INST_BINS)
