#!/usr/bin/env python

import sys, os
import gobject
import pygst
pygst.require("0.10")
import gst

class HLSPipe:

  def __init__(self):
    self.player = gst.Pipeline("player")

    muxer = gst.element_factory_make("mpegtsmux", "muxer")

    depaya = gst.element_factory_make("rtpmp4gdepay", "depaya")
    depayv = gst.element_factory_make("rtph264depay", "depayv")

    def dump_caps(elt):
      print "Element: %s" % elt.get_name()
      for p in elt.pads():
        print p.get_caps()

    def src_complete(src):
      src.link(depayv)
      src.link(depaya)

    src = gst.element_factory_make("rtspsrc", "src")
    src.connect("no-more-pads", src_complete)
    src.set_property("location", "rtsp://newstream.fenkle:5544/phool")

    dst = gst.element_factory_make("filesink", "dst");
    dst.set_property("location", "hlspipe.ts")

    self.player.add(src, depaya, depayv, muxer, dst)

    depaya.link(muxer) 
    depayv.link(muxer) 

    muxer.link(dst)

    bus = self.player.get_bus()
    bus.add_signal_watch()
#    bus.enable_sync_message_emission()
    bus.connect("message", self.on_message)
#    bus.connect("sync-message::element", self.on_sync_message)

    self.player.set_state(gst.STATE_PLAYING)

  def on_message(self, bus, message):
    t = message.type
    if t == gst.MESSAGE_EOS:
      self.player.set_state(gst.STATE_NULL)
    elif t == gst.MESSAGE_ERROR:
      self.player.set_state(gst.STATE_NULL)
      err, debug = message.parse_error()
      print "Error: %s" % err, debug

HLSPipe()
loop = gobject.MainLoop()
gobject.threads_init()
loop.run()
