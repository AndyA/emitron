#!/usr/bin/env python

import sys, os, atexit
import gobject
import pygst
pygst.require("0.10")
import gst

class HLSPipe:
  def auto_link(self, src, sink):
    def try_link(elt, pad):
      try:
        src.link(sink)
        src.disconnect(h_id)
        return
      except (gst.LinkError):
        pass

    try:
      src.link(sink)
      return
    except (gst.LinkError):
      pass

    h_id = src.connect("pad-added", try_link)

  def __init__(self):
    build_pipe = True

    def pad_name(pad):
      return pad.get_parent_element().get_name() + '.' + pad.get_name()

    def dump_pad(pad, depth=0, seen={}):
      pd = pad.get_direction()
      if pd == gst.PAD_SINK: return
      indent = '  ' * depth + 'pad: ' + pad_name(pad)
      if pd == gst.PAD_UNKNOWN:
        print "%s (unknown direction)" % indent
        return
      peer = pad.get_peer()
      if peer:
        print "%s -> %s" % (indent, pad_name(peer))
        dump_elt(peer.get_parent_element(), depth + 1, seen)
      else:
        print "%s (not connected)" % indent

    def dump_elt(elt, depth=0, seen={}):
      en = elt.get_name()
      indent = '  ' * depth + 'elt: ' + en
      if en in seen:
        print "%s (already displayed)" % indent
        return
      seen[en] = seen
      print indent
      for p in elt.pads():
        dump_pad(p, depth + 1, seen)

    def mention(msg):
      print "HLSPIPE: %s" % msg

    def on_message(bus, message):
      t = message.type
      if t == gst.MESSAGE_EOS:
        pipeline.set_state(gst.STATE_NULL)
      elif t == gst.MESSAGE_ERROR:
        pipeline.set_state(gst.STATE_NULL)
        err, debug = message.parse_error()
        print "Error: %s" % err, debug

    if build_pipe:
      pipeline = gst.Pipeline("pipeline")
    else:
      pipeline = gst.parse_launch(
        'mpegtsmux name=muxer ! filesink location=hlspipe.ts '
        'rtspsrc location=rtsp://newstream.fenkle:5544/phool name=src '
        'src. ! rtpmp4gdepay ! queue ! muxer. '
        'src. ! rtph264depay ! queue ! muxer. ')

    def dump_pipe():
      dump_elt(pipeline.get_by_name("src"))

    atexit.register(dump_pipe)

    mention("PIPELINE: %s" % pipeline)

    if build_pipe:
      muxer = gst.element_factory_make("mpegtsmux", "muxer")
      depaya = gst.element_factory_make("rtpmp4gdepay", "depaya")
      depayv = gst.element_factory_make("rtph264depay", "depayv")

      src = gst.element_factory_make("rtspsrc", "src")
      src.set_property("location", "rtsp://newstream.fenkle:5544/phool")

      dst = gst.element_factory_make("filesink", "dst");
      dst.set_property("location", "hlspipe.ts")

      pipeline.add(src, depaya, depayv, muxer, dst)

      def qlink(src, dst):
        q = gst.element_factory_make("queue")
        pipeline.add(q)
        self.auto_link(src, q)
        self.auto_link(q, dst)

      self.auto_link(src, depaya)
      self.auto_link(src, depayv)
      qlink(depaya, muxer)
      qlink(depayv, muxer)
      self.auto_link(muxer, dst)

    bus = pipeline.get_bus()
    bus.add_signal_watch()
#    bus.enable_sync_message_emission()
    bus.connect("message", on_message)
#    bus.connect("sync-message::element", self.on_sync_message)

#    import pdb; pdb.set_trace()

    mention("PLAYING")
    pipeline.set_state(gst.STATE_PLAYING)

HLSPipe()
loop = gobject.MainLoop()
gobject.threads_init()
loop.run()
