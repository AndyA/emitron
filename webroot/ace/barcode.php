<!DOCTYPE html>
<html>
  <head>
    <title>ACE Barcodes</title>
    <link rel="stylesheet" href="css/style.css" />
  </head>
  <body>
    <?php
      chdir(dirname(__FILE__));
      $thumbs = glob("*/frames/barcode-thumb.jpeg");
      foreach ($thumbs as $tb) {
        $mov = dirname(dirname($tb)) . "/index.html";
        $big = dirname($tb) . "/barcode.jpeg";
        print "<a href=\"$big\"><img src=\"$tb\" /></a>";
      }
    ?>
  </body>
</html>

