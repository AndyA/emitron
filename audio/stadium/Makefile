all: stereo media/commentary.m4a media/millwall.m4a media/wigan.m4a

stereo: media/millwall.wav media/wigan.wav

media/millwall.wav: media/millwallleft.wav media/millwallright.wav
	sox -M media/millwallleft.wav media/millwallright.wav media/millwall.wav

media/wigan.wav: media/wiganleft.wav media/wiganright.wav
	sox -M media/wiganleft.wav media/wiganright.wav media/wigan.wav

media/commentary.m4a: media/commentary.wav
	ffmpeg -y -i "$<" -c:a libfaac -b:a 128k "$@"

%.m4a: %.wav
	ffmpeg -y -i "$<" -c:a libfaac -b:a 128k "$@"

clean:
	rm -f media/millwall.wav media/wigan.wav media/*.m4a

