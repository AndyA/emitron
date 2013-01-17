/* dy_encoder.h */

#ifndef __DY_ENCODER_H
#define __DY_ENCODER_H

#include <libavcodec/avcodec.h>

typedef struct {
  AVCodec *codec;
  AVCodecContext *c;
} dy_encoder;

#endif

/* vim:ts=2:sw=2:sts=2:et:ft=c
 */
