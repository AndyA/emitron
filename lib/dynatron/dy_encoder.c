/* dy_encoder.c */

#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#include <libavutil/mathematics.h>
#include <libavutil/opt.h>
#include <libavutil/pixfmt.h>

#include "dynatron.h"
#include "dy_encoder.h"
#include "utils.h"
#include "jsondata.h"

dy_encoder *dy_encoder_new(jd_var *options) {
#if 0
  AVCodec *codec;
  AVCodecContext *c = NULL;
  int i, ret, x, y, got_output;
  FILE *f;
  AVFrame *frame;
  AVPacket pkt;



  mention("Encode video file %s\n", filename);

  codec = avcodec_find_encoder(codec_id);
  if (!codec)die("Codec %d unknown", codec_id);

  c = avcodec_alloc_context3(codec);
  if (!c) die("Can't allocate codec context");

  c->bit_rate = 3000000;;
  c->width = 1920;
  c->height = 1080;
  /* 25 frames per second */
  c->time_base = (AVRational) {
    1, 25
  };
  c->gop_size = 10; /* emit one intra frame every ten frames */
  c->max_b_frames = 1;
  c->pix_fmt = PIX_FMT_YUV420P;

  if (codec_id == AV_CODEC_ID_H264)
    av_opt_set(c->priv_data, "preset", "slow", 0);

  /* open it */
  if (avcodec_open2(c, codec, NULL) < 0)
    die("Couldn't open codec");

  f = fopen(filename, "wb");
  if (!f) die("Can't write %s", filename);

  frame = avcodec_alloc_frame();
  if (!frame) die("Can't allocate frame");

  frame->format = c->pix_fmt;
  frame->width  = c->width;
  frame->height = c->height;

  /* the image can be allocated by any means and av_image_alloc() is
   * just the most convenient way if av_malloc() is to be used */
  ret = av_image_alloc(frame->data, frame->linesize,
                       c->width, c->height, c->pix_fmt, 32);
  if (ret < 0)
    die("Can't allocate raw picture buffer");

  for (i = 0; i < 250; i++) {
    av_init_packet(&pkt);
    pkt.data = NULL;    // packet data will be allocated by the encoder
    pkt.size = 0;

    fflush(stdout);
    /* prepare a dummy image */
    /* Y */
    for (y = 0; y < c->height; y++) {
      for (x = 0; x < c->width; x++) {
        frame->data[0][y * frame->linesize[0] + x] = x + y + i * 3;
      }
    }

    /* Cb and Cr */
    for (y = 0; y < c->height / 2; y++) {
      for (x = 0; x < c->width / 2; x++) {
        frame->data[1][y * frame->linesize[1] + x] = 128 + y + i * 2;
        frame->data[2][y * frame->linesize[2] + x] = 64 + x + i * 5;
      }
    }

    frame->pts = i;

    /* encode the image */
    ret = avcodec_encode_video2(c, &pkt, frame, &got_output);
    if (ret < 0) die("Error encoding frame");

    if (got_output) {
      printf("Write frame %3d (size=%5d)\n", i, pkt.size);
      fwrite(pkt.data, 1, pkt.size, f);
      av_free_packet(&pkt);
    }
  }

  /* get the delayed frames */
  for (got_output = 1; got_output; i++) {
    fflush(stdout);

    ret = avcodec_encode_video2(c, &pkt, NULL, &got_output);
    if (ret < 0) die("Error encoding frame");

    if (got_output) {
      printf("Write frame %3d (size=%5d)\n", i, pkt.size);
      fwrite(pkt.data, 1, pkt.size, f);
      av_free_packet(&pkt);
    }
  }

  fwrite(endcode, 1, sizeof(endcode), f);
  fclose(f);

  avcodec_close(c);
  av_free(c);
  av_freep(&frame->data[0]);
  avcodec_free_frame(&frame);
  printf("\n");
#endif
  return NULL;
}

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
