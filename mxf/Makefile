
SRCD=ftp.kw.bbc.co.uk/ingex/as11_dpp_workshop_update20120419/
DSTD=mxf-mov
MXF=$(wildcard $(SRCD)/*.mxf)
MOV=$(patsubst $(SRCD)/%.mxf, $(DSTD)/%.mov, $(MXF))

all: mov

$(DSTD):
	mkdir -p $(DSTD)

mov: $(DSTD) $(MOV)

$(MOV): $(DSTD)/%.mov: $(SRCD)/%.mxf
	ffmpeg -t 60 -y -i $< -map 0:0 -map 0:1 -pix_fmt yuv420p -c:a libfaac -b:a 192k -c:v libx264 -b:v 5000k -r 25 $@

clean:
	rm -rf $(DSTD)



