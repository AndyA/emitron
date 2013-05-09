.PHONY: test valgrind

include ../common.mk

CTESTS=$(wildcard *.xt)
PERLTESTS=$(wildcard *.t)
LIBS=../../jsondata/libjsondata.a ../libdynatron.a
TESTOBJ=$(CTESTS:.xt=.o)
TESTBIN=$(TESTOBJ:.o=.T) $(PERLTESTS:.t=.T)
MISCOBJ=tap.o util.o jd_test.o
OBJ=$(CTESTOBJ) $(MISCOBJ)
DEPS=$(OBJ:.o=.d) 

CFLAGS+=-I.. -I../../jsondata

%.T: %.o $(MISCOBJ) $(LIBS)
	$(CC) -o $@ $^ $(LDFLAGS)

%.T: %.t
	perl tools/wrapperl.pl $< | gcc -o $@ -x c -

%.o: %.xt
	$(CC) -o $@ $(CFLAGS) -x c -c $<

%.d: %.c
	@$(SHELL) -ec '$(CC) -MM $(CFLAGS) $< \
	| sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@; \
	[ -s $@ ] || rm -f $@'

%.d: %.xt
	@$(SHELL) -ec '$(CC) -MM $(CFLAGS) -x c $< \
	| sed '\''s/\($*\)\.o[ :]*/\1.o $@ : /g'\'' > $@; \
	[ -s $@ ] || rm -f $@'

include $(DEPS)

clean:
	rm -f $(OBJ) $(DEPS) $(TESTBIN)

test: $(TESTBIN)
	prove -e '' $(addprefix ./,$(TESTBIN))

valgrind: $(TESTBIN)
	prove -e 'valgrind -q' $(addprefix ./,$(TESTBIN))

