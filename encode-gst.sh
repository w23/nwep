W=1280
H=720

gst-launch-1.0 -v -m --gst-debug=0 \
	filesrc location=video.raw blocksize=$(($W*$H*3)) ! \
	videoparse format=rgb width=$W height=$H framerate=60/1 ! \
	videoconvert ! video/x-raw,format=I420,width=$W,height=$H,framerate=60/1 ! \
	videoflip method=vertical-flip ! \
	vaapih264enc rate-control=cbr bitrate=7500 init-qp=17 cabac=true keyframe-period=30 max-bframes=2 tune=high-compression ! \
	h264parse ! \
	queue ! qtmux0. \
	filesrc location=music/nwep_full8_q16.flac ! flacparse ! flacdec ! \
	faac ! aacparse ! \
	qtmux ! \
	progressreport ! \
	filesink location=video_h264_2.mp4

	#	audio/x-raw, format=f32le, rate=44100, channels=2, layout=interleaved ! \
#	queue ! qtmux0. \
#	filesrc location=music/audio.raw ! \
#		audio/x-raw, format=f32le, rate=44100, channels=2, layout=interleaved ! \
#	audioconvert ! \
#	faac ! \

# ! mpegtsmux ! filesink location=final.ts
