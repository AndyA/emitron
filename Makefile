.PHONY: all clean realclean send preview prores

SOURCED=STREAM
WORKD=work
PREVIEWD=preview
PRORES25D=prores25
PRORES50D=prores50
REMOTE=andy@phool:~/Desktop
FFATOMIC=tools/ffatomic

MTS=$(wildcard $(SOURCED)/*.MTS)
MOV=$(patsubst $(SOURCED)/%.MTS, $(WORKD)/%.mov, $(MTS))
PREVIEW=$(patsubst $(WORKD)/%.mov, $(PREVIEWD)/%.mp4, $(MOV))
PRORES25=$(patsubst $(WORKD)/%.mov, $(PRORES25D)/%.mov, $(MOV))
PRORES50=$(patsubst $(WORKD)/%.mov, $(PRORES50D)/%.mov, $(MOV))

OUTD=$(PREVIEWD) $(PRORES25D) $(PRORES50D)

all: preview prores

preview: $(PREVIEW)

prores: $(PRORES25) $(PRORES50)

$(MOV): $(WORKD)/%.mov: $(SOURCED)/%.MTS
	$(FFATOMIC) movwrap $< $@

$(PREVIEW): $(PREVIEWD)/%.mp4: $(WORKD)/%.mov
	$(FFATOMIC) preview $< $@

$(PRORES25): $(PRORES25D)/%.mov: $(WORKD)/%.mov
	$(FFATOMIC) prores25 $< $@

$(PRORES50): $(PRORES50D)/%.mov: $(WORKD)/%.mov
	$(FFATOMIC) prores50 $< $@

clean:
	rm -rf $(WORKD)

realclean: clean
	rm -rf $(OUTD)

send:
	mkdir -p $(OUTD)
	rsync -avP $(OUTD) $(REMOTE)

links:
	tools/mklinks.sh

# TODO: stacked undos
undo:
	[ -x ./.undo ] && ./.undo && rm ./.undo
