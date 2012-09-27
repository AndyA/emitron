.PHONY: all clean realclean send preview prores

SRCD=incoming
DSTD=media
FFATOMIC=tools/ffatomic

TS=$(wildcard $(SRCD)/*.ts)
MP4=$(patsubst $(SRCD)/%.ts, $(DSTD)/%.mp4, $(TS))

all: mp4

mp4: $(MP4)

$(MP4): $(DSTD)/%.mp4: $(SRCD)/%.ts
	$(FFATOMIC) mp4 $< $@

clean:
	rm -rf $(MP4)

