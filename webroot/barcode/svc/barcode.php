<?php
  header('Content-type: application/json');
  $link = '../ace';
  $db = array();
  chdir(dirname(__FILE__) . "/../$link");
  $thumbs = glob("*/frames/barcode-thumb.jpeg");
  foreach ($thumbs as $tb) {
    $base = $link . '/' . dirname(dirname($tb));
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
