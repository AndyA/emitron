SRCD16BY9=wales/16by9
PRXD16BY9=proxy/16by9
WRPD16BY9=wrap/16by9
MXF16BY9=$(wildcard $(SRCD16BY9)/*.mxf)
PRX16BY9=$(patsubst $(SRCD16BY9)/%.mxf, $(PRXD16BY9)/%.mov, $(MXF16BY9))

SRCD4BY3=wales/4by3
PRXD4BY3=proxy/4by3
WRPD4BY3=wrap/4by3
MXF4BY3=$(wildcard $(SRCD4BY3)/*.mxf)
PRX4BY3=$(patsubst $(SRCD4BY3)/%.mxf, $(PRXD4BY3)/%.mov, $(MXF4BY3))

# LIMIT=-ss 00:03:00 -t 120
VID_BR="2000k"
AUD_BR="128k"
KEY_INT="800"
KEY_INT_MIN="400"

all: $(PRXD4BY3) $(PRX4BY3) $(PRXD16BY9) $(PRX16BY9) 

$(PRXD4BY3):
	mkdir -p $(PRXD4BY3)

$(PRXD16BY9):
	mkdir -p $(PRXD16BY9)

$(PRX16BY9): $(PRXD16BY9)/%.mov: $(SRCD16BY9)/%.mxf
	ffmpeg -y -i "$<" \
		$(LIMIT) \
		-vf format=yuv420p,yadif,crop=720:576:0:32 \
		-s 1024x576 \
		-c:a libfaac -b:a $(AUD_BR) \
		-c:v libx264 -b:v $(VID_BR) \
		-g $(KEY_INT) -keyint_min $(KEY_INT_MIN) \
		-aspect 16:9 \
		"$@"


$(PRX4BY3): $(PRXD4BY3)/%.mov: $(SRCD4BY3)/%.mxf
	ffmpeg -y -i "$<" \
		$(LIMIT) \
		-vf 'format=yuv420p,yadif,crop=720:576:0:32,pad=1024:576:152:0' \
		-c:a libfaac -b:a $(AUD_BR) \
		-c:v libx264 -b:v $(VID_BR) \
		-g $(KEY_INT) -keyint_min $(KEY_INT_MIN) \
		-aspect 16:9 \
		"$@"

clean:
	rm -rf $(PRXD4BY3) $(PRXD16BY9)


