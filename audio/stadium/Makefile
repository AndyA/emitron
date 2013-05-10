INDIR=media
OUTDIR=../../webroot/stadium/media

all: stereo $(OUTDIR)/commentary.m4a $(OUTDIR)/millwall.m4a $(OUTDIR)/wigan.m4a

stereo: $(INDIR)/millwall.wav $(INDIR)/wigan.wav

$(INDIR)/millwall.wav: $(INDIR)/millwallleft.wav $(INDIR)/millwallright.wav
	sox -M $(INDIR)/millwallleft.wav $(INDIR)/millwallright.wav $(INDIR)/millwall.wav

$(INDIR)/wigan.wav: $(INDIR)/wiganleft.wav $(INDIR)/wiganright.wav
	sox -M $(INDIR)/wiganleft.wav $(INDIR)/wiganright.wav $(INDIR)/wigan.wav

$(OUTDIR)/commentary.m4a: $(INDIR)/commentary.wav
	ffmpeg -y -i "$<" -c:a libfaac -b:a 128k "$@"

$(OUTDIR)/%.m4a: $(INDIR)/%.wav
	ffmpeg -y -i "$<" -c:a libfaac -b:a 128k "$@"

clean:
	rm -f $(INDIR)/millwall.wav $(INDIR)/wigan.wav

