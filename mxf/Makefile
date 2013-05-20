
SRCD=wales
PRXD=proxy
WRPD=wrap
MXF=$(wildcard $(SRCD)/*.mxf)
PRX=$(patsubst $(SRCD)/%.mxf, $(PRXD)/%.mov, $(MXF))

all: $(PRXD) $(PRX) 

$(PRXD):
	mkdir -p $(PRXD)

$(PRX): $(PRXD)/%.mov: $(SRCD)/%.mxf
	ffmpeg -y -i "$<" \
		-vf format=yuv420p,yadif,crop=720:576:0:32 \
		-s 1024x576 \
		-c:a libfaac -b:a 192k \
		-c:v libx264 -b:v 2000k \
		-g 800 -keyint_min 400 \
		-aspect 16:9 \
		"$@"

clean:
	rm -rf $(PRXD)
