<?php
  header('Content-type: application/json');
  $self = (empty($_SERVER['HTTPS']) ? 'http' : 'https')
    . '://' . $_SERVER['SERVER_NAME'] . dirname($_SERVER['REQUEST_URI']);
  $base = "../../ace";
  $db = array();
  chdir(dirname(__FILE__) . "/$base");
  $thumbs = glob("*/frames/barcode-thumb.jpeg");
  foreach ($thumbs as $tb) {
    $name = dirname(dirname($tb));
    array_push($db, array(
      'name'  => $name, 
      'base'  => "$self/$base/", 
      'thumb' => "$tb", 
      'media' => "$name/$name.m3u8", 
      'full'  => "$name/frames/barcode.jpeg", 
      'raw'   => "$name/frames/barcode-raw.jpeg",
      'data'  => "data/$name.json"
    ));
  }
  print json_encode($db);
?>
