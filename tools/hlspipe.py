#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import os
import atexit
import gobject
import pygst
pygst.require('0.10')
import gst


class HLSPipe:

  def auto_link(self, src, sink):

    def try_link(elt, pad):
      try:
        src.link(sink)
        src.disconnect(h_id)
        return
      except gst.LinkError:
        pass

    try:
      src.link(sink)
      return
    except gst.LinkError:
      pass

    h_id = src.connect('pad-added', try_link)

  def __init__(self):
    build_pipe = True

    def pad_name(pad):
      return pad.get_parent_element().get_name() + '.' \
        + pad.get_name()

    def dump_pad(pad, depth=0, seen={}):
      pd = pad.get_direction()
      if pd == gst.PAD_SINK:
        return
      indent = '  ' * depth + 'pad: ' + pad_name(pad)
      if pd == gst.PAD_UNKNOWN:
        print '%s (unknown direction)' % indent
        return
      peer = pad.get_peer()
      if peer:
        print '%s -> %s' % (indent, pad_name(peer))
        dump_elt(peer.get_parent_element(), depth + 1, seen)
      else:
        print '%s (not connected)' % indent

    def dump_elt(elt, depth=0, seen={}):
      en = elt.get_name()
      indent = '  ' * depth + 'elt: ' + en
      if en in seen:
        print '%s (already displayed)' % indent
        return
      seen[en] = seen
      print indent
      for p in elt.pads():
        dump_pad(p, depth + 1, seen)


    def dump_buffer_flags(buffer):
      flags = {
        'BUFFER_FLAG_DELTA_UNIT':  gst.BUFFER_FLAG_DELTA_UNIT,
        'BUFFER_FLAG_DISCONT':     gst.BUFFER_FLAG_DISCONT,
        'BUFFER_FLAG_GAP':         gst.BUFFER_FLAG_GAP,
        'BUFFER_FLAG_IN_CAPS':     gst.BUFFER_FLAG_IN_CAPS,
        'BUFFER_FLAG_LAST':        gst.BUFFER_FLAG_LAST,
        'BUFFER_FLAG_PREROLL':     gst.BUFFER_FLAG_PREROLL,
        'BUFFER_FLAG_READONLY':    gst.BUFFER_FLAG_READONLY,
      }

      for flag in flags.keys():
        print "%-24s: %s" % ( flag,
          "TRUE" if buffer.flag_is_set(flags[flag]) else "FALSE" )

    def mention(msg):
      print 'HLSPIPE: %s' % msg

    def on_message(bus, message):
      t = message.type
      if t == gst.MESSAGE_EOS:
        pipeline.set_state(gst.STATE_NULL)
      elif t == gst.MESSAGE_ERROR:
        pipeline.set_state(gst.STATE_NULL)
        (err, debug) = message.parse_error()
        print 'Error: %s' % err, debug

    def on_sync_message(bus, message):
      mention('sync message')

    def dump_pipe():
      dump_elt(pipeline.get_by_name('src'))

    atexit.register(dump_pipe)

    if build_pipe:
      pipeline = gst.Pipeline('pipeline')

      def qlink(src, dst):
        q = gst.element_factory_make('queue')
        pipeline.add(q)
        self.auto_link(src, q)
        self.auto_link(q, dst)

      # Make some elements
      src = gst.element_factory_make('rtspsrc', 'src')
      src.set_property('location',
        'rtsp://newstream.fenkle:5544/phool')

      depaya = gst.element_factory_make('rtpmp4gdepay', 'depaya')
      depayv = gst.element_factory_make('rtph264depay', 'depayv')
      muxer = gst.element_factory_make('mpegtsmux', 'muxer')

      parser = gst.element_factory_make('h264parse', 'parser')
      ident = gst.element_factory_make('identity', 'ident')

      def on_handoff(ident, buffer):
        if not buffer.flag_is_set(gst.BUFFER_FLAG_DELTA_UNIT):
          mention('KEY FRAME')
          valve.set_property('drop', False)
          ident.set_property('signal-handoffs', False)

#        import pdb; pdb.set_trace()

      ident.connect('handoff', on_handoff)
      ident.set_property('signal-handoffs', False)

      valve = gst.element_factory_make('valve', 'valve')
      valve.set_property('drop', False)

      dst = gst.element_factory_make("filesink", "dst");
      dst.set_property("location", "hlspipe.ts")

      pipeline.add(src, parser, ident, valve, depaya, depayv, muxer, dst)

      # Join them up
      self.auto_link(src, depaya)
      qlink(depaya, muxer)
      self.auto_link(src, depayv)
      qlink(depayv, parser)
      self.auto_link(parser, muxer)

      self.auto_link(muxer, ident)
      self.auto_link(ident, valve)

      self.auto_link(valve, dst)

    else:
      pipeline = gst.parse_launch(
        'mpegtsmux name=muxer ! filesink location=hlspipe.ts '
        'rtspsrc location=rtsp://newstream.fenkle:5544/phool name=src '
        'src. ! rtpmp4gdepay ! queue ! muxer. '
        'src. ! rtph264depay ! queue ! muxer. ')

    mention('PIPELINE: %s' % pipeline)

    bus = pipeline.get_bus()
    bus.add_signal_watch()
    bus.enable_sync_message_emission()
    bus.connect('message', on_message)
    bus.connect("sync-message::element", on_sync_message)

    mention('PLAYING')
    pipeline.set_state(gst.STATE_PLAYING)

HLSPipe()
loop = gobject.MainLoop()
gobject.threads_init()
loop.run()
