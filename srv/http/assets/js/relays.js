$( function() { //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

var newvalues, pinprev;

function data2json() {
	var form = document.getElementById( 'relaysform' );
	var data = Object.fromEntries( new FormData( form ).entries() );
	for( key in data ) {
		var name = {}
		var on = {}
		var off = {}
		for ( i = 1; i < 5; i++ ) {
			name[ data[ 'pin'+ i ] ] = data[ 'name'+ i ];
			on[ 'on'+ i ] = Number( data[ 'on'+ i ] ) || 0;
			off[ 'off'+ i ] = Number( data[ 'off'+ i ] ) || 0;
			if ( i < 4 ) {
				on[ 'ond'+ i ] = Number( data[ 'ond'+ i ] ) || 0;
				off[ 'offd'+ i ] = Number( data[ 'offd'+ i ] ) || 0;
			}
		}
	}
	newvalues = {
		  name  : name
		, on    : on
		, off   : off
		, timer : Number( data.timer )
	}
	return newvalues
}
function dataDiff() {
	var json1 = relaysset;
	var json2 = data2json();
	if ( json1.timer !== json2.timer ) {
		$( '.btn' ).removeClass( 'disabled' );
		return
	}
	var on1 = json1.on;
	var on2 = json2.on;
	var off1 = json1.off;
	var off2 = json2.off;
	for ( i = 1; i < 4; i++ ) {
		if ( on1[ 'ond' + i ] !== on2[ 'ond' + i ] || on1[ 'offd' + i ] !== on2[ 'offd' + i ] ) {
			$( '.btn' ).removeClass( 'disabled' );
			return
		}
	}
	for ( i = 1; i < 5; i++ ) {
		if ( on1[ 'on' + i ] !== on2[ 'on' + i ] || off1[ 'off' + i ] !== off2[ 'off' + i ] ) {
			$( '.btn' ).removeClass( 'disabled' );
			return
		}
	}
	var pins1 = Object.keys( json1.name );
	var pins2 = Object.keys( json2.name );
	var names1 = Object.values( json1.name );
	var names2 = Object.values( json2.name );
	for ( i = 0; i < 4; i++ ) {
		if ( pins1[ i ] !== pins2[ i ] || names1[ i ] !== names2[ i ] ) {
			$( '.btn' ).removeClass( 'disabled' );
			return
		}
	}
	$( '.btn' ).addClass( 'disabled' );
}
function renderOptions( json ) {
	var r = json;
	var pins = Object.keys( r.name );
	var names = Object.values( r.name );
	var name, pin;
	var optnamepin = '<option value="0">none</option>';
	for ( i = 0; i < 4; i++ ) {
		pin = pins[ i ];
		namepin = ( names[ i ] || '(no name)' ) +' - '+ pin;
		optnamepin += '<option value="'+ pin +'">'+ namepin +'</option>';
	}
	var htmlon = '';
	var htmloff = '';
	var optsec = '<option value="0">none</option>';
	for ( i = 1; i < 11; i++ ) optsec += '<option value="'+ i +'">'+ i +'</option>';
	htmlsec = '</select><span class="sec">sec.</span>';
	for ( i = 1; i < 5; i++ ) {
		htmlon +=  '<select id="on'+ i +'" name="on'+ i +'" class="on">'+ optnamepin +'</select>';
		htmloff += '<select id="off'+ i +'" name="off'+ i +'" class="off">'+ optnamepin +'</select>';
		if ( i < 4 && r.on[ 'ond'+ i ] ) {
			htmlon += '<select id="ond'+ i +'" name="ond'+ i +'" class="ond delay">'+ optsec + htmlsec;
			htmloff += '<select id="offd'+ i +'" name="offd'+ i +'" class="offd delay">'+ optsec + htmlsec;
		}
	}
	$( '#timer' )
		.html( optsec )
		.find( 'option[value='+ r.timer +']' ).prop( 'selected', 1 );
	$( '#on' ).html( htmlon );
	$( '#off' ).html( htmloff );
	for ( i=1; i < 5; i++ ) {
		$( '#pin'+ i ).val( pins[ i - 1 ] );
		var ex = pins.slice( 0 ); // clone
		ex.splice( i - 1, 1 );
		for ( x = 0; x < 3; x++ ) $( '#pin'+ i +' option[value='+ ex[ x ] +']' ).toggleClass( 'hide' );
		$( '#name'+ i ).val( names[ i - 1 ] );
		$( '#on'+ i +' option[value='+ r.on[ 'on'+ i ] +']' ).prop( 'selected', 1 );
		$( '#off'+ i +' option[value='+ r.off[ 'off'+ i ] +']' ).prop( 'selected', 1 );
		if ( i < 4 && r.on[ 'ond'+ i ] ) {
			$( '#ond'+ i +' option[value='+ r.on[ 'ond'+ i ] +']' ).prop( 'selected', 1 );
			$( '#offd'+ i +' option[value='+ r.off[ 'offd'+ i ] +']' ).prop( 'selected', 1 );
		}
	}
	$( 'select' ).selectric();
}

renderOptions( relaysset );

$( '.close-root' ).click( function() {
	location.href = '/';
} );
$( '#help' ).click( function() {
	$( this ).toggleClass( 'blue' );
	$( '.help-block' ).toggleClass( 'hide' );
} );
$( '#gpioimgtxt, #close-img' ).click( function() {
	if ( $( '#gpiopin, #gpiopin1' ).is( ':visible' ) && $( '#gpiopin' ).is( ':hidden' ) ) $( '#gpiopin, #gpiopin1' ).toggle();
	$( '#gpiopin' ).slideToggle();
	$( '#fliptxt, #close-img' ).toggle();
	$( this ).find( 'i' ).toggleClass('fa-chevron-circle-down fa-chevron-circle-up')
} );
$( '#gpiopin, #gpiopin1' ).click( function() {
	$( '#gpiopin, #gpiopin1' ).toggle();
} );
$( '.name' ).keyup( function() {
	dataDiff();
} ).change( function() {
	renderOptions( data2json() );
} );
$( '#gpio-num' ).on( 'mousedown touchdown', function( e ) {
	pinprev = Number( $( e.target ).parent().prev().find( 'option:selected' ).val() );
} );
$( '.pin' ).change( function() {
	var pinnew = Number( $( this ).find( 'option:selected' ).val() );
	var r = data2json();
	[ r.on, r.off ].forEach( function( json ) {
		$.each( json, function( k, v ) {
			if ( v === pinprev ) json[ k ] = pinnew;
		} );
	} );
	$( 'select' ).selectric( 'refresh' );
	renderOptions( r );
	dataDiff();
} );
$( '#on, #off, #timer' ).change( function() {
	dataDiff();
} );
$( '#undo' ).click( function() {
	renderOptions( relaysset );
	$( '.btn' ).addClass( 'disabled' );
} );
$( '#save' ).click( function() {
	$.post(
		'/cmd.php'
		, { cmd : 'sh' , sh  : [ 'cmd.sh', 'relaysset', JSON.stringify( newvalues ) ] }
		, function() {
			relaysset = newvalues;
			$( '.btn' ).addClass( 'disabled' );
			$( '#bannerMessage' ).text( 'Done' );
			setTimeout( bannerHide, 2000 );
		}
	);
	banner( 'GPIO Relays', 'Change ...', 'relays' );
} );

} ); //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
