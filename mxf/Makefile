PRXD=proxy
SRCD=wales
HLSD=../webroot/wales
HLSAD=$(HLSD)/a
HLSBD=$(HLSD)/b
THBD=$(HLSD)/t
INDEX=$(HLSD)/index.json

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
META=$(patsubst $(PRXD)/%.mov, $(PRXD)/%.xml, $(PRX))
HLSA=$(patsubst $(PRXD)/%.mov, $(HLSAD)/%/a.m3u8, $(PRX))
HLSAM=$(patsubst $(PRXD)/%.mov, $(HLSAD)/%/a.json, $(PRX))
HLSB=$(patsubst $(PRXD)/%.mov, $(HLSBD)/%.m3u8, $(PRX))
HLSBM=$(patsubst $(PRXD)/%.mov, $(HLSBD)/%.json, $(PRX))
THB=$(patsubst $(PRXD)/%.mov, $(THBD)/%/index.json, $(PRX))
BAR=$(patsubst $(PRXD)/%.mov, $(THBD)/%/barcode.jpeg, $(PRX))

all: $(HLSA) $(HLSB) $(THB) $(BAR) $(INDEX) $(HLSAM) $(HLSBM)

$(PRX16BY9): $(SRCD16BY9)

$(PRX4BY3): $(SRCD4BY3)

$(HLSA): $(PRX)
$(HLSB): $(PRX)
$(THB): $(PRX)
$(BAR): $(THB)
$(META): $(PRX)
$(HLSAM): $(META)
$(HLSBM): $(META)

$(PRXD)/%.xml: $(PRXD)/%.mov
	mediainfo -f --Output=META "$<" > "$@"

$(PRXD)/%.mov: $(SRCD16BY9)/%.mxf
	mkdir -p $(PRXD)
	ffmpeg -y -i "$<" \
		$(LIMIT) \
		-vf 'format=yuv420p,yadif,crop=720:576:0:32' \
		-s 1024x576 \
		-c:a libfaac -b:a $(AUD_BR) \
		-c:v libx264 -b:v $(VID_BR) \
		-g $(KEY_INT) -keyint_min $(KEY_INT_MIN) \
		-aspect 16:9 \
		"$@"

$(PRXD)/%.mov: $(SRCD4BY3)/%.mxf
	mkdir -p $(PRXD)
	ffmpeg -y -i "$<" \
		$(LIMIT) \
		-vf 'format=yuv420p,yadif,crop=720:576:0:32,pad=1024:576:152:0' \
		-c:a libfaac -b:a $(AUD_BR) \
		-c:v libx264 -b:v $(VID_BR) \
		-g $(KEY_INT) -keyint_min $(KEY_INT_MIN) \
		-aspect 16:9 \
		"$@" 

$(HLSAD)/%/a.m3u8: $(PRXD)/%.mov
	$(eval _DIR := $(shell dirname "$@"))
	mkdir -p "$(_DIR)"
	ffmpeg -y -i "$<" -bsf h264_mp4toannexb -c copy -hls_list_size 100000 -hls_time 8 "$@"

$(HLSBD)/%.m3u8: $(PRXD)/%.mov
	$(eval _DIR := $(shell dirname "$@"))
	$(eval _BASE := $(shell basename "$@" .m3u8))
	$(eval _FRAG := $(_DIR)/$(_BASE))
	mkdir -p "$(_FRAG)"
	cd "$(_DIR)" && ffmpeg -y \
		-i "../../../mxf/$<" \
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

$(HLSAD)/%/a.json: $(PRXD)/%.xml
	$(eval _DIR := $(shell dirname "$@"))
	mkdir -p "$(_DIR)"
	perl tools/tech_meta.pl < "$<" > "$@"

$(HLSBD)/%.json: $(PRXD)/%.xml
	$(eval _DIR := $(shell dirname "$@"))
	mkdir -p "$(_DIR)"
	perl tools/tech_meta.pl < "$<" > "$@"

$(THBD)/%/index.json: $(PRXD)/%.mov
	$(eval _DIR := $(shell dirname "$@"))
	rm -rf "$(_DIR)"
	mkdir -p "$(_DIR)"
	ffmpeg -i "$<" -r 0.05 -s 192x108 -f image2 "$(_DIR)/%05d.jpg"
	echo '[' > "$@"; \
	find "$(_DIR)" -name '*.jpg' -printf "\"%f\",\n" >> "$@"
	echo ']' >> "$@"

$(THBD)/%/barcode.jpeg: $(THBD)/%/index.json
	$(eval _DIR := $(shell dirname "$@"))
	perl ../tools/barcode.pl --width 1024 "$(_DIR)"

$(INDEX): $(THB) index.csv
	perl tools/make_index.pl index.csv > "$@"

clean:
	rm -rf $(PRXD) $(HLSD)


