
SRCD=ftp.kw.bbc.co.uk/ingex/as11_dpp_workshop_update20120419/
PRXD=proxy
WRPD=wrap
MXF=$(wildcard $(SRCD)/*.mxf)
PRX=$(patsubst $(SRCD)/%.mxf, $(PRXD)/%.mov, $(MXF))
WRP=$(patsubst $(SRCD)/%.mxf, $(WRPD)/%.mov, $(MXF))

all: $(PRXD) $(PRX) $(WRPD) $(WRP)

$(PRXD):
	mkdir -p $(PRXD)

$(WRPD):
	mkdir -p $(WRPD)

$(PRX): $(PRXD)/%.mov: $(SRCD)/%.mxf
	ffmpeg -y -i $< -pix_fmt yuv420p -c:a libfaac -b:a 192k -c:v libx264 -b:v 5000k -r 25 -threads 0 $@

$(WRP): $(WRPD)/%.mov: $(SRCD)/%.mxf
	ffmpeg -y -i $< -c:a copy -c:v copy -r 25 -threads 0 $@

clean:
	rm -rf $(PRXD)



