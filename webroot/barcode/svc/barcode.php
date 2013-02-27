<?php
  header('Content-type: application/json');
  $link = '../ace';
  $db = array();
  chdir(dirname(__FILE__) . "/../$link");
  $thumbs = glob("*/frames/barcode-thumb.jpeg");
  foreach ($thumbs as $tb) {
    $base = dirname(dirname($tb));
    array_push($db, array(
      name  => $base, 
      thumb => "$link/$tb", 
      media => "$link/$base/$base.m3u8", 
      full  => "$link/$base/frames/barcode.jpeg", 
      raw   => "$link/$base/frames/barcode-raw.jpeg",
      data  => "$link/data/$base.json"
    ));
  }
  print json_encode($db);
?>
