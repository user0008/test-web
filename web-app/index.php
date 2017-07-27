<!DOCTYPE html>
<html>
<?php
  date_default_timezone_set('Asia/Tokyo');
  $INFO = array(gethostname(), $_SERVER['SERVER_ADDR'], date('H:i:s'));
  $HX   = str_split(sha1($INFO[0].$INFO[1]), 2);
  $BG   = array(hexdec($HX[0]), hexdec($HX[1]), hexdec($HX[2]));
  $MM   = max($BG) + min($BG);
  $FG   = array($MM - $BG[0], $MM - $BG[1], $MM - $BG[2]);
  $BGS  = vsprintf('#%02x%02x%02x', $BG);
  $FGS  = vsprintf('#%02x%02x%02x', $FG);
?>
<head>
  <meta http-equiv="refresh" content="5;URL=./">
  <title><?php echo $INFO[0];?></title>
  <style>
    body{font-size:250%;font-family:monospace;color:<?php echo $FGS;?>;background:<?php echo $BGS;?>;}
  </style>
</head>
<body>
  <h1>Hello world</h1>
  <ul><?php foreach($INFO as $e){echo '<li>', $e, '</li>';}?></ul>
</body>
</html>
