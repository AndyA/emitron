
SRCD=wales
PRXD=proxy
WRPD=wrap
MXF=$(wildcard $(SRCD)/*.mxf)
PRX=$(patsubst $(SRCD)/%.mxf, $(PRXD)/%.mov, $(MXF))
WRP=$(patsubst $(SRCD)/%.mxf, $(WRPD)/%.mov, $(MXF))

all: $(PRXD) $(WRPD) $(WRP) $(PRX) 

$(PRXD):
	mkdir -p $(PRXD)

$(WRPD):
	mkdir -p $(WRPD)

$(WRP): $(WRPD)/%.mov: $(SRCD)/%.mxf
	ffmpeg -y -i $< -c:a copy -c:v copy -r 25 -threads 0 $@

$(PRX): $(PRXD)/%.mov: $(WRPD)/%.mov
	ffmpeg -y -i $< -vf yadif -vf crop=720:576:0:32 -c:a libfaac -b:a 192k -c:v libx264 -b:v 5000k -s 1024x576 -aspect 16:9 -threads 0 $@

clean:
	rm -rf $(PRXD) $(WRPD)



