<?php
  header('Content-type: application/json');
  $db = array();
  chdir(dirname(__FILE__) . '/..');
  $thumbs = glob("*/frames/barcode-thumb.jpeg");
  foreach ($thumbs as $tb) {
    $base = dirname(dirname($tb));
    $big = "$base/frames/barcode.jpeg";
    $raw = "$base/frames/barcode-raw.jpeg";
    $mov = "$base/$base.m3u8";
    array_push($db, array(
      name  => $base, 
      media => $mov,
      thumb => $tb,
      full  => $big,
      raw   => $raw
    ));
  }
  print json_encode($db);
?>
