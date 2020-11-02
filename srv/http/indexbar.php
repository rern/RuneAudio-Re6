<?php
function indexbar( $indexes ) {
	$indexbar = '<a class="wh">#</a>';
	$chars = range( 'A', 'Z' );
	for ( $i =0; $i < 26; $i++ ) {
		$char = $chars[ $i ];
		if ( in_array( $char, $indexes ) ) $char = '<wh>'.$char.'</wh>';
		$indexbar.= '<a>'.$char.'</a>';
	}
	$indexbar1 = '<a class="wh">#</a>';
	for ( $i =0; $i < 26; $i++ ) {
		$char = $chars[ $i ];
		$char1 = $chars[ $i + 1 ];
		if ( in_array( $char, $indexes ) ) $char = '<wh>'.$char.'</wh>';
		if ( in_array( $char1, $indexes ) ) $char1 = '<wh>'.$char1.'</wh>';
		$indexbar1.= '<a>'.$char.$char1.'</a>';
		$i++;
	}
	return [ $indexbar, $indexbar1 ];
}
