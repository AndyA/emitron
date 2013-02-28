<?php
  $type = empty($_GET['callback']) ? 'json' : 'javascript';
  header("Content-type: application/$type");
  $root = (empty($_SERVER['HTTPS']) ? 'http' : 'https') . '://' . $_SERVER['SERVER_NAME'];
  $uri = $_SERVER['REQUEST_URI'];
  $dir = $root . dirname($uri);
  $self = $root . $uri;
  $base = "../../ace";
  $db = array();
  if (empty($_GET['id'])) {
    chdir(dirname(__FILE__) . "/$base");
    $thumbs = glob("*/frames/barcode-thumb.jpeg");
    foreach ($thumbs as $tb) {
      $name = dirname(dirname($tb));
      array_push($db, array(
        'name'  => $name, 
        'base'  => "$dir/$base/", 
        'thumb' => "$tb", 
        'media' => "$name/$name.m3u8", 
        'full'  => "$name/frames/barcode.jpeg", 
        'raw'   => "$name/frames/barcode-raw.jpeg",
        'data'  => empty($_GET['callback']) ? "data/$name.json" : "$self&id=$name"
      ));
    }
  }
  else {
    $id = $_GET['id'];
    if (!preg_match('/^\w+$/', $id)) die("Bad ID");
    $df = dirname(__FILE__) . "/../../ace/data/$id.json";
    $db = json_decode(file_get_contents($df));
  }
  print empty($_GET['callback']) 
      ? json_encode($db) 
      : $_GET['callback'] . '(' . json_encode($db) . ')';
  print "\n";
?>
