<?php
/*
find, list, ls, search, track, webradio

Album
	/srv/http/data/mpd/album: album-artist^-file
	/srv/http/data/mpd/albumbyartist: artist-album-file
			track list: mpc ls -f %*% $path
Artist
	mpc list artist > /srv/http/data/mpd/artist
		album list: mpc find -f %artist%^^%album% artist $artist
			track list: mpc find -f %*% album $album artist $artist
AlbumArtist
	mpc list albumartist > /srv/http/data/mpd/albumartist
		album list: mpc find -f %albumartist%^^%album% albumartist $albumartist
			track list: mpc find -f %*% album $album albumartist $albumartist
Composer
	mpc list composer > /srv/http/data/mpd/composer
		album list: mpc find -f %composer%^^%album% composer composer
			track list: mpc find -f %*% album $album composer composer
Genre
	mpc list genre > /srv/http/data/mpd/genre
		artist-album list: mpc find -f %artist%^^%album% genre $genre
			track list: mpc find -f %*% album $album artist $artist
Date
	mpc list date > /srv/http/data/mpd/date
		artist-album list: mpc find -f %artist%^^%album% date $date
			track list: mpc find -f %*% album $album artist $artist
File
	mpc ls -f %file% $path
			track list: mpc ls -f %*% $path
search
			track list: mpc search -f %*% any $keyword
*/
include '/srv/http/bash/cmd-listsort.php';

$mode = $_POST[ 'mode' ] ?? null;
$string = $_POST[ 'string' ] ?? null;
$string = escape( $string );
$formatall = [ 'album', 'albumartist', 'artist', 'composer', 'date', 'file', 'genre', 'time', 'title', 'track' ];
$f = $_POST[ 'format' ] ?? $formatall;
$format = '%'.implode( '%^^%', $f ).'%';
$indexarray = range( 'A', 'Z' );
$indexbar = '<a class="wh">#</a>';
$modes = [ 'album' => 0, 'albumartist' => 1, 'artist' => 2, 'composer' => 3, 'date' => 4, 'genre' => 5 ];

switch( $_POST[ 'query' ] ) {

case 'find':
	$format = str_replace( '%artist%', '[%artist%|%albumartist%]', $format );
	if ( is_array( $mode ) ) {
		$file = exec( 'mpc -f %file% find '.$mode[ 0 ].' "'.$string[ 0 ].'" '.$mode[ 1 ].' "'.$string[ 1 ].'" 2> /dev/null | head -1' );
		if ( substr( $file, -14, 4 ) !== '.cue' ) {
			exec( 'mpc find -f "'.$format.'" '.$mode[ 0 ].' "'.$string[ 0 ].'" '.$mode[ 1 ].' "'.$string[ 1 ].'" 2> /dev/null'." | awk 'NF && !a[$0]++'"
				, $lists );
			if ( !count( $lists ) ) { // find with albumartist
				exec( 'mpc find -f "'.$format.'" '.$mode[ 0 ].' "'.$string[ 0 ].'" albumartist "'.$string[ 1 ].'" 2> /dev/null'." | awk 'NF && !a[$0]++'"
				, $lists );
			}
		} else { // $file = '/path/to/file.cue/track0001'
			$format = '%'.implode( '%^^%', $f ).'%';
			exec( 'mpc -f "'.$format.'" playlist "'.dirname( $file ).'"'
					, $lists );
		}
	} else {
		$lists = shell_exec( 'mpc find -f "'.$format.'" '.$mode.' "'.$string.'" 2> /dev/null'." | awk 'NF && !a[$0]++'" );
		$lists = explode( "\n", $lists ); // NO: exec( $cmd, $lists ) > 502 (Bad Gateway) error
	}
	if ( count( $f ) > 2 ) {
		$array = htmlTracks( $lists, $f );
	} else { // modes - album, artist, albumartist, composer, genre: 2 fields format
		$array = htmlFind( $mode, $lists, $f );
	}
	break;
case 'list':
	$filemode = '/srv/http/data/mpd/'.$mode;
	if ( $mode === 'album' && exec( 'grep "albumbyartist.*true" /srv/http/data/system/display' ) ) $filemode.= 'byartist';
	$lists = file( $filemode, FILE_IGNORE_NEW_LINES );
	$array = htmlList( $mode, $lists );
	break;
case 'ls':
	$subdirs = 0;
	if ( $mode !== 'album' ) {
		exec( 'mpc ls "'.$string.'"', $mpcls );
		foreach( $mpcls as $mpdpath ) {
			if ( is_dir( '/mnt/MPD/'.$mpdpath ) ) {
				$subdirs = 1;
				break;
			}
		}
	}
	if ( $subdirs  ) {
		exec( 'mpc ls -f %file% "'.$string.'" 2> /dev/null'
			, $lists );
		$count = count( $lists );
		if ( !$count ) exit( '-1' );
		
		foreach( $lists as $list ) {
			$dir = str_replace( $string.'/', '', $list );
			$each = ( object )[];
			$each->path = $list;
			$each->dir  = $dir;
			$each->sort = stripSort( $dir );
			$array[] = $each;
		}
		usort( $array, function( $a, $b ) {
			return strnatcasecmp( $a->sort, $b->sort );
		} );
		$nas200 = $count > 200 && substr( $string, 0, 3 ) === 'NAS';
		$time = time();
		$html = '';
		foreach( $array as $each ) {
			$path = $each->path;
			$index = mb_substr( $each->sort, 0, 1, 'UTF-8' );
			$indexes[] = $index;
			$pathnoext = '/mnt/MPD/'.$path.'/thumb';
			if ( $nas200 || file_exists( $pathnoext.'.jpg' ) ) {
				$ext = '.jpg';
			} else if ( file_exists( $pathnoext.'.gif' ) ) {
				$ext = '.gif';
			} else {
				$ext = '';
			}
			if ( $ext ) {
				$thumbsrc = '/mnt/MPD/'.rawurlencode( $path ).'/thumb.'.$time.$ext;
				$icon = '<img class="lazy iconthumb lib-icon" data-src="'.$thumbsrc.'" data-target="#menu-folder">';
			} else {
				$icon = '<i class="fa fa-folder lib-icon" data-target="#menu-folder"></i>';
			}
			$html.=  '<li data-mode="file" data-index="'.$index.'">'
					.$icon
					.'<a class="lipath">'.$path.'</a>'
					.'<span class="single">'.$each->dir.'</span>'
					.'</li>';
		}
		$indexes = array_keys( array_flip( $indexes ) );
		foreach( $indexarray as $i => $char ) {
			$white = in_array( $char, $indexes ) ? 'wh' : '';
			$half = $i % 2 ? ' half' : '';
			$indexbar.= '<a class="'.$white.$half.'">'.$char."</a>\n";
		}
		$array = [ 'html' => $html, 'index' => $indexbar ];
	} else {
		$f = $formatall; // set format for directory with files only - track list
		$format = '%'.implode( '%^^%', $f ).'%';
		// parse if cue|m3u,|pls files (sort -u: mpc ls list *.cue twice)
		exec( 'mpc ls "'.$string.'" | grep ".cue$\|.m3u$\|.m3u8$\|.pls$" | sort -u'
			, $plfiles );
		if ( count( $plfiles ) ) {
			asort( $plfiles );
			$ext = end( explode( '.', $plfiles[ 0 ] ) );
			$lists = [];
			foreach( $plfiles as $file ) {
				exec( 'mpc -f "'.$format.'" playlist "'.$file.'"'
					, $lists ); // exec appends to existing array
			}
			$array = htmlTracks( $lists, $f, $ext, $file );
		} else {
			exec( 'mpc ls -f "'.$format.'" "'.$string.'" 2> /dev/null'
				, $lists );
			if ( strpos( $lists[ 0 ],  '.wav^^' ) ) { // MPD not sort *.wav
				$lists = '';
				exec( 'mpc ls -f "%track%__'.$format.'" "'.$string.'" 2> /dev/null | sort -h | sed "s/^.*__//"'
					, $lists );
			}
			$array = htmlTracks( $lists, $f, $mode !== 'album' ? 'file' : '' );
		}
	}
	break;
case 'search':
	exec( 'mpc search -f "'.$format.'" any "'.$string.'" | awk NF'
		, $lists );
	$array = htmlTracks( $lists, $f, 'search', $string );
	break;
case 'track': // for tag editor
	$track = $_POST[ 'track' ] ?? '';
	$file = escape( $_POST[ 'file' ] );
	if ( $track ) { // cue
		if ( $track === 'cover' ) {
			$filter = 'head -1';
		} else {
			$filter = 'grep "\^\^'.$track.'"';
		}
		$lists = exec( 'mpc playlist -f "'.$format.'" "'.$file.'" | '.$filter );
		$array = explode( '^^', $lists );
	} else {
		if ( is_dir( '/mnt/MPD/'.$file ) ) {
			$wav = glob( '/mnt/MPD/'.$file.'/*.wav', GLOB_BRACE ); // MPD not read albumartist in *.wav
			if ( $wav ) {
				$albumartist = exec( 'kid3-cli -c "get albumartist" "'.$wav[ 0 ].'"' );
				if ( $albumartist ) $format = str_replace( '%albumartist%', $albumartist, $format );
			}
			exec( 'mpc ls -f "'.$format.'" "'.$file.'"'
				, $lists );
			foreach( $lists as $list ) {
				$each = explode( '^^', $list );
				$artist[]   = $each[ 2 ];
				$composer[] = $each[ 3 ];
				$date[]     = $each[ 4 ];
				$genre[]    = $each[ 5 ];
				$array[]    = $each;
			}
			$array = $array[ 0 ];
			if ( count( array_unique( $artist ) )   > 1 ) $array[ 2 ] = '*';
			if ( count( array_unique( $composer ) ) > 1 ) $array[ 3 ] = '*';
			if ( count( array_unique( $date ) )     > 1 ) $array[ 3 ] = '*';
			if ( count( array_unique( $genre ) )    > 1 ) $array[ 4 ] = '*';
		} else {
			// MPD not read albumartist in *.wav
			if ( substr( $file, -3 ) === 'wav' ) {
				$albumartist = exec( 'kid3-cli -c "get albumartist" "/mnt/MPD/'.$file.'"' );
				if ( $albumartist ) $format = str_replace( '%albumartist%', $albumartist, $format );
			}
			$lists = exec( 'mpc ls -f "'.$format.'" "'.$file.'"' );
			$array = explode( '^^', $lists );
		}
	}
	if ( isset( $_POST[ 'coverart' ] ) ) $array[] = exec( '/srv/http/bash/status-coverart.sh "'.escape( $file ).'"' );
	break;
case 'webradio':
	$dirwebradios = '/srv/http/data/webradios';
	$lists = array_slice( scandir( $dirwebradios ), 2 );
	if ( !count( $lists ) ) exit( '-1' );
	foreach( $lists as $list ) {
		$each = ( object )[];
		$name = exec( "sed -n 1p '$dirwebradios/$list'" );
		$each->name  = $name;
		$each->url   = str_replace( '|', '/', $list );
		$each->sort  = stripSort( $name );
		$array[] = $each;
	}
	usort( $array, function( $a, $b ) {
		return strnatcasecmp( $a->sort, $b->sort );
	} );
	$time = time();
	$html = '';
	foreach( $array as $each ) {
		$indexes[] = mb_substr( $each->sort, 0, 1, 'UTF-8' );
		$name = str_replace( '/', '|', $each->url );
		$pathnoext = '/srv/http/data/webradiosimg/'.$name.'-thumb';
		if ( file_exists( $pathnoext.'.jpg' ) ) {
			$ext = '.jpg';
		} else if ( file_exists( $pathnoext.'.gif' ) ) {
			$ext = '.gif';
		} else {
			$ext = '';
		}
		if ( $ext ) {
			$thumbsrc = '/data/webradiosimg/'.rawurlencode( $name ).'-thumb.'.$time.$ext;
			$icon = '<img class="lazy iconthumb lib-icon" data-src="'.$thumbsrc.'" data-target="#menu-webradio">';
		} else {
			$icon = '<i class="fa fa-webradio lib-icon" data-target="#menu-webradio"></i>';
		}
		$html.= '<li class="file">'
					.$icon
					.'<a class="lipath">'.$each->url.'</a>'
					.'<a class="liname">'.$each->name.'</a>'
					.'<span class="li1">'.$each->name.'</span>'
					.'<span class="li2">'.$each->url.'</span>'
				.'</li>';
	}
	$indexes = array_keys( array_flip( $indexes ) );
	foreach( $indexarray as $i => $char ) {
		$white = in_array( $char, $indexes ) ? 'wh' : '';
		$half = $i % 2 ? ' half' : '';
		$indexbar.= '<a class="'.$white.$half.'">'.$char."</a>\n";
	}
	$array = [ 'html' => $html, 'index' => $indexbar ];
	break;
}

echo json_encode( $array );

//-------------------------------------------------------------------------------------
function escape( $string ) { // for passing bash arguments
	return preg_replace( '/(["`])/', '\\\\\1', $string );
}
function HMS2second( $time ) {
	$HMS = explode( ':', $time );
	$count = count( $HMS );
	switch( $count ) {
		case 1: return $HMS[ 0 ]; break;
		case 2: return $HMS[ 0 ] * 60 + $HMS[ 1 ]; break;
		case 3: return $HMS[ 0 ] * 60 * 60 + $HMS[ 1 ] * 60 + $HMS[ 0 ]; break;
	}
}
function htmlFind( $mode, $lists, $f ) { // non-file 'find' command
	if ( !count( $lists ) ) exit( '-1' );
	
	$fL = count( $f );
	foreach( $lists as $list ) {
		if ( $list === '' ) continue;
		
		$list = explode( '^^', $list ); // album^^artist 
		$sort = in_array( $mode, [ 'artist', 'albumartist' ] ) ? $list[ 0 ] : $list[ 1 ]; // sort by artist
		$each = ( object )[];
		for ( $i = 0; $i < $fL; $i++ ) {
			$key = $f[ $i ];
			$each->$key = $list[ $i ];
			$each->sort = stripSort( $sort );
		}
		if ( isset( $list[ $fL ] ) ) $each->path = $list[ $fL ];
		$array[] = $each;
	}
	usort( $array, function( $a, $b ) {
		return strnatcasecmp( $a->sort, $b->sort );
	} );
	$html = '';
	foreach( $array as $each ) {
		$key0 = $f[ 0 ];
		$key1 = $f[ 1 ];
		$val0 = $each->$key0;
		$val1 = $each->$key1;
		$index = mb_substr( $each->sort, 0, 1, 'UTF-8' );
		$indexes[] = $index;
		if ( in_array( $mode, [ 'artist', 'albumartist' ] ) ) { // display as artist - album
			$name = $fL > 1 ? $val0.'<gr> • </gr>'.$val1 : $val0;
		} else {
			$name = $fL > 1 ? $val1.'<gr> • </gr>'.$val0 : $val0;
		}
		if ( $name === '<gr> • </gr>' || !name ) continue;
		
		if ( property_exists( $each, 'path' ) ) { // cue //////////////////////////
			$path = $each->path;
			$datamode = 'file';
		} else {
			$path = $val1;
			$datamode = 'album';
		} // cue //////////////////////////////////////////////////////////////////
		$html.= '<li data-mode="'.$datamode.'" data-index="'.$index.'">'
					.'<a class="lipath">'.$path.'</a>'
					.'<a class="liname">'.$val0.'</a>'
					.'<i class="fa fa-'.$mode.' lib-icon" data-target="#menu-album"></i>'
					.'<span class="single">'.$name.'</span>'
				.'</li>';
	}
	$indexes = array_keys( array_flip( $indexes ) );
	$indexarray = range( 'A', 'Z' );
	$indexbar = '<a class="wh">#</a>';
	foreach( $indexarray as $i => $char ) {
		$white = in_array( $char, $indexes ) ? 'wh' : '';
		$half = $i % 2 ? ' half' : '';
		$indexbar.= '<a class="'.$white.$half.'">'.$char."</a>\n";
	}
	return [ 'html' => $html, 'index' => $indexbar ];
}
function htmlList( $mode, $lists ) { // non-file 'list' command
	if ( !count( $lists ) ) exit( '-1' );
	
	$html = '';
	if ( $mode !== 'album' ) {
		foreach( $lists as $list ) {
			$data = explode( '^^', $list );
			$index = $data[ 0 ];
			$indexes[] = $index;
			$name = $data[ 1 ];
			$html.= '<li data-mode="'.$mode.'" data-index="'.$index.'">'
						.'<a class="lipath">'.$name.'</a>'
						.'<i class="fa fa-'.$mode.' lib-icon" data-target="#menu-'.$mode.'"></i>'
						.'<span class="single">'.$name.'</span>'
					.'</li>';
		}
	} else {
		$time = time();
		foreach( $lists as $list ) {
			$data = explode( '^^', $list );
			$index = $data[ 0 ];
			$indexes[] = $index;
			$path = $data[ 3 ];
			$coverfile = '/mnt/MPD/'.rawurlencode( $path ).'/coverart.'.$time.'.jpg';
			$html.= '<div class="coverart" data-index="'.$index.'">
						<a class="lipath">'.$path.'</a>
						<div><img class="lazy" data-src="'.$coverfile.'"></div>
						<span class="coverart1">'.$data[ 1 ].'</span>
						<gr class="coverart2">'.( $data[ 2 ] ?: '&nbsp;' ).'</gr>
					</div>';
		}
	}
	$indexes = array_keys( array_flip( $indexes ) ); // faster than array_unique
	$indexarray = range( 'A', 'Z' );
	$indexbar = '<a class="wh">#</a>';
	foreach( $indexarray as $i => $char ) {
		$white = in_array( $char, $indexes ) ? 'wh' : '';
		$half = $i % 2 ? ' half' : '';
		$indexbar.= '<a class="'.$white.$half.'">'.$char."</a>\n";
	}
	return [ 'html' => $html, 'index' => $indexbar ];
}
function htmlTracks( $lists, $f, $filemode = '', $string = '' ) { // track list - no sort ($string: cuefile or search)
	if ( !count( $lists ) ) exit( '-1' );
	
	$fL = count( $f );
	foreach( $lists as $list ) {
		if ( $list === '' ) continue;
		
		$list = explode( '^^', $list );
		$each = ( object )[];
		for ( $i = 0; $i < $fL; $i++ ) {
			$key = $f[ $i ];
			$each->$key = $list[ $i ];
		}
		$array[] = $each;
	}
	$each0 = $array[ 0 ];
	$file0 = $each0->file;
	$ext = pathinfo( $file0, PATHINFO_EXTENSION );
	$litime = 0;
	
	$hidecover = exec( 'grep "hidecover.*true" /srv/http/data/system/display' );
	$searchmode = $filemode === 'search';
//	$cue = exec( 'mpc ls "'.dirname( $file0 ).'" | grep ".cue$" | wc -l' )
//			|| substr( $file0, -14, 4 ) === '.cue'; // $file0 = '/path/to/file.cue/track0001'
	$cuefile = exec( 'mpc ls "'.dirname( $file0 ).'" | grep ".cue$" | head -1' );
	if ( $cuefile ) {
		$cue = true;
		$file0 = $cuefile;
	} else if ( substr( $file0, -14, 4 ) === '.cue' ) { // $file0 = '/path/to/file.cue/track0001'
		$cue = true;
		$file0 = dirname( $file0 );
		$musicfile = exec( 'mpc ls "'.dirname( $file0 ).'" | grep -v ".cue$" | head -1' );
		$ext = pathinfo( $musicfile, PATHINFO_EXTENSION );
	}
	$i = 0;
	$html = '';
	foreach( $array as $each ) {
		$path = $cue ? $file0 : $each->file;
		$litime += HMS2second( $each->time );
		$title = $each->title;
		$datatrack = $cue ? 'data-track="'.$each->track.'"' : '';
		if ( $searchmode ) {
			$title = preg_replace( "/($string)/i", '<bl>$1</bl>', $title );
			$name = $each->artist.' - '.$each->album;
			$trackname = preg_replace( "/($string)/i", '<bl>$1</bl>', $name );
		} else {
			$trackname = basename( $path );
		}
		if ( !$title ) $title = pathinfo( $each->file, PATHINFO_FILENAME );
		$li0 = ( $i || $searchmode || $hidecover ) ? '' : ' class="track1"';
		$i++;
		$html.= '<li data-mode="file" '.$datatrack.$li0.'>'
					.'<a class="lipath">'.$path.'</a>'
					.'<i class="fa fa-music lib-icon" data-target="#menu-file"></i>'
					.'<span class="li1">'.$title.'<span class="time">'.$each->time.'</span></span>'
					.'<span class="li2">'.$i.' • '.$trackname.'</span>'
				.'</li>';
	}
	if ( $searchmode ) return [ 'html' => $html, 'count' => count( $array ) ];
	
	if ( !$hidecover ) {
		// fix - mpd cannot read albumartist from *.wav
		if ( $ext === 'wav' ) $albumartist = exec( 'kid3-cli -c "get albumartist" "/mnt/MPD/'.$file0.'"' );
		if ( $each0->albumartist || $albumartist ) {
			$artist = $each0->albumartist ?: $albumartist;
			$icon = 'albumartist';
		} else {
			$artist = $each0->artist;
			$icon = 'artist';
		}
		$album = $each0->album;
		$dir = dirname( $file0 );
		$sh = [ ( $cue ? $dir : $file0 ), $artist, $album, 'licover' ];
		$script = '/usr/bin/sudo /srv/http/bash/status-coverart.sh "';
		$script.= escape( implode( "\n", $sh ) ).'"';
		$coverart = exec( $script );
		$nocover = '';
		if ( !$coverart ) {
			$coverart = '/assets/img/cover.'.time().'.svg';
			$nocover = ' nocover';
		}
		$coverhtml.= '<li data-mode="file" class="licover">'
					.'<a class="lipath">'.( $cue ? $file0 : $dir ).'</a>'
					.'<div class="licoverimg'.$nocover.'"><img id="liimg" src="'.$coverart.'"></div>'
					.'<div class="liinfo">'
					.'<div class="lialbum">'.$album.'</div>'
					.'<div class="liartist"><i class="fa fa-'.$icon.'"></i>'.$artist.'</div>';
			if ( $each0->composer ) {
		$coverhtml.= '<div class="licomposer"><i class="fa fa-composer"></i>'.$each0->composer.'</div>';
			}
			if ( $each0->genre ) {
		$coverhtml.= '<span class="ligenre"><i class="fa fa-genre"></i>'.$each0->genre.'</span>&emsp;';
			}
			if ( $each0->date ) {
		$coverhtml.= '<span class="lidate"><i class="fa fa-date"></i>'.$each0->date.'</span>';
			}
			if ( $each0->genre || $each0->date ) {
		$coverhtml.= '<br>';
			}
		$coverhtml.= '<div class="liinfopath"><i class="fa fa-folder"></i>'.str_replace( '\"', '"', $dir ).'</div>'
					.'<i class="fa fa-music lib-icon" data-target="#menu-folder"></i>'.( count( $array ) )
					.'<gr> • </gr>'.second2HMS( $litime )
					.'<gr> • </gr>'.strtoupper( $ext );
			$plfile = exec( 'mpc ls "'.$dir.'" 2> /dev/null | grep ".cue$\|.m3u$\|.m3u8$\|.pls$"' );
			if ( $plfile ) {
		$coverhtml.= '&emsp;<i class="fa fa-file-playlist"></i><gr>'.pathinfo( $plfile, PATHINFO_EXTENSION ).'</gr>';
			}
		$coverhtml.= '</div></li>';
	} else {
		$coverhtml = '';
	}
		
	return [ 'html' => $coverhtml.$html ];
}
function second2HMS( $second ) {
	$hh = floor( $second / 3600 );
	$mm = floor( ( $second % 3600 ) / 60 );
	$ss = $second % 60;
	
	$hh = $hh ? $hh.':' : '';
	$mm = $hh ? ( $mm > 9 ? $mm.':' : '0'.$mm.':' ) : ( $mm ? $mm.':' : '' );
	$ss = $mm ? ( $ss > 9 ? $ss : '0'.$ss ) : $ss;
	return $hh.$mm.$ss;
}
