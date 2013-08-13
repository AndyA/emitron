INDIR=media
TMPDIR=tmp
OUTDIR=../../webroot/stadium/media

WAV=$(TMPDIR)/commentary.wav $(TMPDIR)/millwall.wav $(TMPDIR)/wigan.wav
M4A=$(patsubst $(TMPDIR)/%.wav, $(OUTDIR)/%.m4a, $(WAV))

all: $(M4A)

$(TMPDIR)/commentary.wav: $(INDIR)/commentary.wav
	mkdir -p $(TMPDIR)
	sox -M $(INDIR)/commentary.wav $(INDIR)/commentary.wav $(TMPDIR)/commentary.wav

$(TMPDIR)/millwall.wav: $(INDIR)/millwallleft.wav $(INDIR)/millwallright.wav
	mkdir -p $(TMPDIR)
	sox -M $(INDIR)/millwallleft.wav $(INDIR)/millwallright.wav $(TMPDIR)/millwall.wav

$(TMPDIR)/wigan.wav: $(INDIR)/wiganleft.wav $(INDIR)/wiganright.wav
	mkdir -p $(TMPDIR)
	sox -M $(INDIR)/wiganleft.wav $(INDIR)/wiganright.wav $(TMPDIR)/wigan.wav

$(OUTDIR)/%.m4a: $(TMPDIR)/%.wav
	ffmpeg -y -i "$<" -c:a libfaac -b:a 128k "$@"

clean:
	rm -f $(M4A)
