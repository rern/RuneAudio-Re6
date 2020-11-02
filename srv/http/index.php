<?php
$login = file_exists( '/srv/http/data/system/login' );
if ( $login ) session_start(); // for login
$time = time();  // for cache busting
$localhost = in_array( $_SERVER[ 'REMOTE_ADDR' ], ['127.0.0.1', '::1'] );
$desktop = isset( $_SERVER[ 'HTTP_USER_AGENT' ] )
			&& !preg_match( 
				  '/(Mobile|Android|Tablet|GoBrowser|[0-9]x[0-9]*|uZardWeb\/|Mini|Doris\/|Skyfire\/|iPhone|Fennec\/|Maemo|Iris\/|CLDC\-|Mobi\/)/uis'
				, $_SERVER[ 'HTTP_USER_AGENT' ]
			);
?>

<!DOCTYPE html>
<html lang="en">
<head>

<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="msapplication-tap-highlight" content="no" />
<title>RuneAudio+R</title>
<link rel="apple-touch-icon" sizes="152x152" href="/assets/img/apple-touch-icon-152x152.<?=$time?>.png">
<link rel="apple-touch-icon" sizes="167x167" href="/assets/img/apple-touch-icon-167x167.<?=$time?>.png">
<link rel="apple-touch-icon" sizes="180x180" href="/assets/img/apple-touch-icon-180x180.<?=$time?>.png">
<link rel="icon" type="image/png" href="/assets/img/favicon.<?=$time?>.png" sizes="192x192">
<meta name="apple-mobile-web-app-title" content="RuneAudio">
<meta name="msapplication-TileColor" content="#000000">
<meta name="msapplication-TileImage" content="/assets/img/mstile-144x144.<?=$time?>.png">
<meta name="application-name" content="RuneAudio">
<style>
	@font-face {
		font-family: enhance;
		src        : url( "/assets/fonts/enhance.<?=$time?>.woff" ) format( 'woff' ),
		             url( "/assets/fonts/enhance.<?=$time?>.ttf" ) format( 'truetype' );
		font-weight: normal;
		font-style : normal;
	}
</style>
<link rel="stylesheet" href="/assets/css/colors.<?=$time?>.css">
	<?php if ( $localhost ) { ?> 
<link rel="stylesheet" href="/assets/css/simple-keyboard.min.<?=$time?>.css">
<link rel="stylesheet" href="/assets/css/keyboard.<?=$time?>.css">
	<?php } ?>
<link rel="stylesheet" href="/assets/css/info.<?=$time?>.css">
<link rel="stylesheet" href="/assets/css/roundslider.min.<?=$time?>.css">
<link rel="stylesheet" href="/assets/css/main.<?=$time?>.css">
<link rel="stylesheet" href="/assets/css/banner.<?=$time?>.css">
	<?php if ( $desktop ) { ?> 
<link rel="stylesheet" href="/assets/css/desktop.<?=$time?>.css">
	<?php } ?>
	
</head>
<body<?=( $localhost ? ' class="dragscroll"' : '' )?>>

<?php include 'index-body.php';?>

<script src="/assets/js/plugin/jquery-2.2.4.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/jquery.mobile.custom.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/pushstream.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/Sortable.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/roundslider.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/lazyload.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/pica.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/html5kellycolorpicker.min.<?=$time?>.js"></script>
<script src="/assets/js/plugin/qrcode.min.<?=$time?>.js"></script>
<script src="/assets/js/info.<?=$time?>.js"></script>
<script src="/assets/js/function.<?=$time?>.js"></script>
<script src="/assets/js/main.<?=$time?>.js"></script>
<script src="/assets/js/passive.<?=$time?>.js"></script>
<script src="/assets/js/banner.<?=$time?>.js"></script>
<script src="/assets/js/context.<?=$time?>.js"></script>
<script src="/assets/js/lyrics.<?=$time?>.js"></script>
	<?php if ( $desktop ) { ?>
<script src="/assets/js/shortcut.<?=$time?>.js"></script>
	<?php } ?>
	<?php if ( $localhost ) { ?>
<script src="/assets/js/plugin/simple-keyboard.min.<?=$time?>.js"></script>
<script src="/assets/js/keyboard.<?=$time?>.js"></script>
	<?php } ?>
	
</body>
</html>
