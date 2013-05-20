PRXD=proxy
SRCD=wales
HLSD=hls
HLSAD=$(HLSD)/a
HLSBD=$(HLSD)/b

SRCD16BY9=$(SRCD)/16by9
MXF16BY9=$(wildcard $(SRCD16BY9)/*.mxf)
PRX16BY9=$(patsubst $(SRCD16BY9)/%.mxf, $(PRXD)/%.mov, $(MXF16BY9))

SRCD4BY3=$(SRCD)/4by3
MXF4BY3=$(wildcard $(SRCD4BY3)/*.mxf)
PRX4BY3=$(patsubst $(SRCD4BY3)/%.mxf, $(PRXD)/%.mov, $(MXF4BY3))

# LIMIT=-ss 00:03:00 -t 120
VID_BR="2500k"
AUD_BR="128k"
KEY_INT="200"
KEY_INT_MIN="100"

PRX=$(PRX4BY3) $(PRX16BY9)
HLSA=$(patsubst $(PRXD)/%.mov, $(HLSAD)/%/a.m3u8, $(PRX))
HLSB=$(patsubst $(PRXD)/%.mov, $(HLSBD)/%.m3u8, $(PRX))

all: $(HLSA) $(HLSB)

$(PRXD):
	mkdir -p $(PRXD)

$(HLSAD):
	mkdir -p $(HLSAD)

$(HLSBD):
	mkdir -p $(HLSBD)

$(PRX16BY9): $(PRXD)/%.mov: $(SRCD16BY9)/%.mxf $(PRXD)
	ffmpeg -y -i "$<" \
		$(LIMIT) \
		-vf format=yuv420p,yadif,crop=720:576:0:32 \
		-s 1024x576 \
		-c:a libfaac -b:a $(AUD_BR) \
		-c:v libx264 -b:v $(VID_BR) \
		-g $(KEY_INT) -keyint_min $(KEY_INT_MIN) \
		-aspect 16:9 \
		"$@"


$(PRX4BY3): $(PRXD)/%.mov: $(SRCD4BY3)/%.mxf $(PRXD)
	ffmpeg -y -i "$<" \
		$(LIMIT) \
		-vf 'format=yuv420p,yadif,crop=720:576:0:32,pad=1024:576:152:0' \
		-c:a libfaac -b:a $(AUD_BR) \
		-c:v libx264 -b:v $(VID_BR) \
		-g $(KEY_INT) -keyint_min $(KEY_INT_MIN) \
		-aspect 16:9 \
		"$@" 

$(HLSA): $(HLSAD)/%/a.m3u8: $(PRXD)/%.mov $(HLSAD)
	$(eval _DIR := $(shell dirname "$@"))
	rm -rf "$(_DIR)"
	mkdir -p "$(_DIR)"
	ffmpeg -y -i "$<" -bsf h264_mp4toannexb -c copy -hls_list_size 100000 -hls_time 8 "$@"

$(HLSB): $(HLSBD)/%.m3u8: $(PRXD)/%.mov $(HLSBD)
	$(eval _DIR := $(shell dirname "$@"))
	$(eval _BASE := $(shell basename "$@" .m3u8))
	$(eval _FRAG := $(_DIR)/$(_BASE))
	rm -rf "$(_FRAG)"
	mkdir -p "$(_FRAG)"
	cd "$(_DIR)" && ffmpeg -y \
		-i "../../$<" \
	       	-bsf h264_mp4toannexb \
		-map 0:0 \
		-map 0:1 \
		-c copy \
		-f segment \
		-segment_time 8 \
		-segment_format mpegts \
		-segment_list "$(_BASE).m3u8" \
		-segment_list_type m3u8 \
		"$(_BASE)/%08d.ts"

clean:
	rm -rf $(PRXD) $(HLSD)


