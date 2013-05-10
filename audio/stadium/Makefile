INDIR=media
OUTDIR=../../webroot/stadium/media

WAV=$(wildcard $(INDIR)/*.wav)
M4A=$(patsubst $(INDIR)/%.wav, $(OUTDIR)/%.m4a, $(WAV))

all: $(M4A)

$(OUTDIR)/%.m4a: $(INDIR)/%.wav
	ffmpeg -y -i "$<" -c:a libfaac -b:a 96k "$@"

clean:
	rm -f $(M4A)

