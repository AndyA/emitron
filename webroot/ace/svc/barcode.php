<?php
  header('Content-type: application/json');
  $db = array();
  chdir(dirname(__FILE__) . '/..');
  $thumbs = glob("*/frames/barcode-thumb.jpeg");
  foreach ($thumbs as $tb) {
    $base = dirname(dirname($tb));
    array_push($db, array(
      name  => $base, 
      thumb => $tb,
      media => "$base/$base.m3u8", 
      full  => "$base/frames/barcode.jpeg", 
      raw   => "$base/frames/barcode-raw.jpeg",
      data  => "data/$base.json"
    ));
  }
  print json_encode($db);
?>
