#!/usr/bin/env python

import sys, os
import gobject
import pygst
pygst.require("0.10")
import gst

class HLSPipe:

  def __init__(self):
    player = gst.Pipeline("player")

    def on_message(bus, message):
      t = message.type
  #    print "***** %s" % message
      if t == gst.MESSAGE_EOS:
        player.set_state(gst.STATE_NULL)
      elif t == gst.MESSAGE_ERROR:
        player.set_state(gst.STATE_NULL)
        err, debug = message.parse_error()
        print "Error: %s" % err, debug

    muxer = gst.element_factory_make("mpegtsmux", "muxer")

    depaya = gst.element_factory_make("rtpmp4gdepay", "depaya")
    depayv = gst.element_factory_make("rtph264depay", "depayv")

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
      indent = '  ' * depth + 'elt: ' + elt.get_name()
      if id(elt) in seen:
        print "%s (already displayed)" % indent
        return
      seen[id(elt)] = seen
      print indent
      for p in elt.pads():
        dump_pad(p, depth + 1, seen)

    def dump_caps(elt):
      print "Element: %s" % elt.get_name()
      for p in elt.pads():
        print p.get_caps()

    def src_complete(src):
      src.link(depayv)
      src.link(depaya)
      dump_elt(src)

    src = gst.element_factory_make("rtspsrc", "src")
    src.connect("no-more-pads", src_complete)
    src.set_property("location", "rtsp://newstream.fenkle:5544/phool")

    dst = gst.element_factory_make("filesink", "dst");
    dst.set_property("location", "hlspipe.ts")

    player.add(src, depaya, depayv, muxer, dst)

    depaya.link(muxer) 
    depayv.link(muxer) 

    muxer.link(dst)

    bus = player.get_bus()
    bus.add_signal_watch()
#    bus.enable_sync_message_emission()
    bus.connect("message", on_message)
#    bus.connect("sync-message::element", self.on_sync_message)

#    import pdb; pdb.set_trace()

    player.set_state(gst.STATE_PLAYING)

HLSPipe()
loop = gobject.MainLoop()
gobject.threads_init()
loop.run()
