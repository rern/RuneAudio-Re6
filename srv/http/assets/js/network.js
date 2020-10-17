$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

function btRender( data ) {
	var html = '';
	data.forEach( function( list ) {
		html += '<li data-mac="'+ list.mac +'" data-connected="'+ list.connected +'"><i class="fa fa-bluetooth"></i>'
				+ ( list.connected ? '<grn>&bull;&ensp;</grn>' : '' )
				+'<a class="liname wh">'+ list.name +'</a>';
				+'</li>';
	} );
	$( '#listbt' ).html( html );
}
function btScan() {
	bash( '/srv/http/bash/network-scanbt.sh', function( data ) {
		if ( data.length ) btRender( data );
		intervalscan = setTimeout( btScan, 12000 );
	}, 'json' );
}
function connect( data ) { // [ ssid, dhcp, wpa, password, hidden, ip, gw ]
	clearTimeout( intervalscan );
	var ssid = data [ 0 ];
	var ip = data[ 5 ];
	if ( ip ) {
		$( '#loader' ).removeClass( 'hide' );
		location.href = 'http://'+ ip +'/index-settings.php?p=network';
		var text = ip.slice( -5 ) === 'local' ? 'Change URL to ' : 'Change IP to ';
		notify( ssid, text + ip, 'wifi-3' );
	} else {
		notify( ssid, 'Connect ...', 'wifi-3' );
	}
	bash( [ 'connect', G.wlcurrent ].concat( data ), function( std ) {
		if ( std == -1 ) {
			G.wlconnected =  '';
			info( {
				  icon      : 'wifi-3'
				, title     : 'Wi-Fi'
				, message   : 'Connect to <wh>'+ ssid +'</wh> failed.'
			} );
		}
	} );
}
function editLAN( data ) {
	var data0 = data;
	info( {
		  icon         : 'edit-circle'
		, title        : 'LAN IP'
		, message      : 'Current: <wh>'+ ( data.dhcp === 'dhcp' ? 'DHCP' : 'Static IP' ) +'</wh><br>&nbsp;'
		, textlabel    : [ 'IP', 'Gateway' ]
		, textvalue    : [ data.ip, data.gateway ]
		, textrequired : [ 0 ]
		, preshow      : function() {
			if ( data.dhcp === 'dhcp' ) $( '#infoButton' ).addClass( 'hide' );
		}
		, buttonlabel  : '<i class="fa fa-undo"></i>DHCP'
		, buttonwidth  : 1
		, button       : function() {
			notify( 'LAN IP Address', 'Change URL to '+ G.hostname +'.local ...', 'lan' );
			$( '#loader' ).removeClass( 'hide' );
			location.href = 'http://'+ G.hostname +'.local/index-settings.php?p=network';
			bash( [ 'editlan' ] );
		}
		, ok           : function() {
			var data1 = {}
			data1.ip = $( '#infoTextBox' ).val();
			data1.gateway = $( '#infoTextBox1' ).val();
			if ( data1.ip === data.ip && data1.gateway === data.gateway ) return
			
			notify( 'LAN IP Address', 'Change ip to '+ data1.ip, 'lan' );
			bash( [ 'editlan', data1.ip, data1.gateway ], function( used ) {
				if ( used == -1 ) {
					info( {
						  icon    : 'lan'
						, title   : 'Duplicate IP'
						, message : 'IP <wh>'+ data1.ip +'</wh> already in use.'
						, ok      : function() {
							editLAN( data0 );
						}
					} );
				}
				bannerHide();
			} );
			
		}
	} );
}
function editWiFi( ssid, data ) {
	var data0 = data;
	var icon = ssid ? 'edit-circle' : 'wifi-3';
	var title = ssid ? 'Wi-Fi IP' : 'Add Wi-Fi';
	info( {
		  icon          : icon
		, title         : title
		, textlabel     : [ 'SSID', 'IP', 'Gateway' ]
		, checkbox      : { 'Static IP': 1, 'Hidden SSID': 1, 'WEP': 1 }
		, passwordlabel : 'Password'
		, preshow       : function() {
			if ( !ssid ) {
				$( '#infotextlabel a:eq( 1 ), #infoTextBox1, #infotextlabel a:eq( 2 ), #infoTextBox2' ).hide();
			} else {
				if ( data ) {
					editWiFiSet( ssid, data );
				} else {
					bash( [ 'statuswifi', ssid ], function( data ) {
						data.Address = 'Address' in data ? data.Address.replace( '/24', '' ) : '';
						editWiFiSet( ssid, data );
					}, 'json' );
				}
			}
		}
		, ok            : function() {
			var ssid = ssid || $( '#infoTextBox' ).val();
			var password = $( '#infoPasswordBox' ).val();
			var ip = $( '#infoTextBox1' ).val();
			var gw = $( '#infoTextBox2' ).val();
			var dhcp = $( '#infoCheckBox input:eq( 0 )' ).prop( 'checked' ) ? 'static' : 'dhcp';
			var hidden = $( '#infoCheckBox input:eq( 1 )' ).prop( 'checked' ) ? 'hidden' : '';
			var security = $( '#infoCheckBox input:eq( 2 )' ).prop( 'checked' ) ? 'wep' : 'wpa';
			if ( data0 && ip === data0.Address && gw === data0.Gateway ) return
			
			// [ wlan, ssid, dhcp, wpa, password, hidden, ip, gw ]
			var data = [ ssid, dhcp ];
			if ( password ) {
				data.push( security, password, hidden );
			} else {
				data.push( '', '', hidden );
			}
			if ( dhcp === 'dhcp' ) {
				connect( data );
			} else {
				data.push( ip, gw );
				if ( ip === data0.Address ) {
					connect( data );
				} else {
					bash( [ 'ipused', ip ], function( used ) {
						if ( used == 1 ) {
							info( {
								  icon    : 'wifi-3'
								, title   : 'Duplicate IP'
								, message : 'IP <wh>'+ ip +'</wh> already in use.'
								, ok      : function() {
									editWiFi( ssid, data0 );
								}
							} );
						} else {
							connect( data );
						}
					} );
				}
			}
		}
	} );
	$( '#infoCheckBox' ).on( 'click', 'input:eq( 0 )', function() {
		$( '#infotextlabel a:eq( 1 ), #infoTextBox1, #infotextlabel a:eq( 2 ), #infoTextBox2' ).toggle( $( this ).prop( 'checked' ) );
	} );
}
function editWiFiSet( ssid, data ) {
	$( '#infoMessage' ).html(
		 '<i class="fa fa-wifi-3"></i>&ensp;<wh>'+ ssid +'</wh>'
		+'<br>Current: <wh>'+ ( data.dhcp === 'dhcp' ? 'DHCP' : 'Static IP' ) +'</wh><br>&nbsp;'
	).css( 'text-align', 'center' );
	$( '#infoTextBox1' ).val( data.Address );
	$( '#infoTextBox2' ).val( data.Gateway );
	$( '#infoPasswordBox' ).val( data.Key );
	$( '#infoCheckBox input:eq( 0 )' ).prop( 'checked', 1 );
	$( '#infoCheckBox input:eq( 2 )' ).prop( 'checked', data.Security === 'wep' );
	$( '#infoTextBox' ).val( ssid );
	$( '#infotextlabel a:eq( 0 ), #infoTextBox, #infotextlabel a:eq( 3 ), #infoPasswordBox, #infotextbox .eye, #infoCheckBox' ).hide();
	if ( data.Address ) {
		$( '#infoFooter' ).hide();
	} else {
		$( '#infoFooter' ).html( '<br>*Connect to get DHCP IPs' );
	}
	if ( data.dhcp === 'static' ) {
		$( '#infoOk' ).before( '<a id="infoButton" class="infobtn extrabtn infobtn-default"><i class="fa fa-undo"></i>DHCP</a>' );
		$( '#infoButton' ).click( function() {
			$( '#infoX' ).click();
			$( '#loader' ).removeClass( 'hide' );
			notify( ssid, 'DHCP ...', 'wifi-3' );
			location.href = 'http://'+ G.hostname +'.local/index-settings.php?p=network';
			bash( [ 'editwifidhcp', ssid ] );
		} );
	}
}
function getIfconfig() {
	bash( [ 'statusifconfig' ], function( status ) {
		$( '#codeifconfig' )
			.html( status )
			.removeClass( 'hide' );
	} );
}
function getNetctl() {
	bash( [ 'statusnetctl' ], function( data ) {
		$( '#codenetctl' )
			.html( data )
			.removeClass( 'hide' );
	} );
}
function nicsStatus() {
	bash( '/srv/http/bash/network-data.sh', function( list ) {
		var extra = list.pop();
		if ( extra.hostapd ) {
			G = extra.hostapd;
			$( '#ssid' ).text( G.ssid );
			$( '#passphrase' ).text( G.passphrase )
			$( '#ipwebuiap' ).text( G.hostapdip );
			$( '#accesspoint' ).prop( 'checked', G.hostapd );
			$( '#settings-accesspoint, #boxqr' ).toggleClass( 'hide', !G.hostapd );
		}
		G.reboot = extra.reboot ? extra.reboot.split( '\n' ) : [];
		if ( 'bluetooth' in extra ) G.bluetooth = extra.bluetooth;
		G.hostname = extra.hostname;
		var html = '';
		$.each( list, function( i, val ) {
			html += '<li class="'+ val.interface +'"';
			html += val.ip ? ' data-ip="'+ val.ip +'"' : '';
			html += val.gateway ? ' data-gateway="'+ val.gateway +'"' : '';
			html += ' data-dhcp="'+ val.dhcp +'"';
			html += '><i class="fa fa-';
			html += val.interface === 'eth0' ? 'lan"></i>LAN' : 'wifi-3"></i>Wi-Fi';
			if ( val.interface === 'eth0' ) {
				html += val.ip ? '&ensp;<grn>&bull;</grn>&ensp;'+ val.ip : '';
				html += val.gateway ? '<gr>&ensp;&raquo;&ensp;'+ val.gateway +'&ensp;</gr>' : '';
			} else if ( val.ip ) {
				if ( accesspoint && G.hostapd && val.ip === G.hostapdip ) {
					html += '&ensp;<grn>&bull;</grn>&ensp;<gr>RPi access point&ensp;&raquo;&ensp;</gr>'+ G.hostapdip
				} else {
					G.wlconnected = val.interface;
					html += '&ensp;<grn>&bull;</grn>&ensp;'+ val.ip +'<gr>&ensp;&raquo;&ensp;'+ val.gateway +'&ensp;&bull;&ensp;</gr>'+ val.ssid;
				}
			} else {
				html += '&emsp;<i class="fa fa-search"></i><gr>Scan</gr>';
			}
			html += '</li>';
		} );
		if ( 'bluetooth' in G ) {
			if ( G.bluetooth ) {
				G.bluetooth.forEach( function( list ) {
					html += '<li class="bt" data-name="'+ list.name +'" data-connected="'+ list.connected +'" data-mac="'+ list.mac +'"><i class="fa fa-bluetooth"></i>Bluetooth&ensp;';
					html += ( list.connected ? '<grn>&bull;</grn>&ensp;' : '<gr>&bull;</gr>&ensp;' ) + list.name +'</li>';
				} );
			} else {
				html += '<li class="bt"><i class="fa fa-bluetooth"></i>Bluetooth&ensp;<i class="fa fa-search"></i></i><gr>Scan</gr></li>';
			}
			$( '#ifconfig' ).next().find( 'code' ).text( 'ifconfig; bluetoothctl show' );
		}
		$( '#refreshing' ).addClass( 'hide' );
		$( '#listinterfaces' ).html( html );
		if ( $( '#divinterface' ).hasClass( 'hide' ) ) return
		
		renderQR();
		bannerHide();
		$( '#divaccesspoint' ).toggleClass( 'hide', !extra.wlan );
		if ( !$( '#codeifconfig' ).hasClass( 'hide' ) ) getIfconfig();
		if ( !$( '#codenetctl' ).hasClass( 'hide' ) ) getNetctl();
		showContent();
	}, 'json' );
}
function qr( msg ) {
	return new QRCode( {
		  msg : msg
		, dim : 130
		, pad : 0
	} );
}
function renderQR() {
	$( 'li' ).each( function() {
		var ip = $( this ).data( 'ip' );
		var gateway = $( this ).data( 'gateway' );
		if ( ip && gateway ) {
			$( '#ipwebui' ).text( ip );
			$( '#qrwebui' ).html( qr( 'http://'+ ip ) );
			$( '#divwebui' ).removeClass( 'hide' );
			return false
		}
	} );
	if ( !accesspoint || !G.hostapd ) return
	
	$( '#qraccesspoint' ).html( qr( 'WIFI:S:'+ G.ssid +';T:WPA;P:'+ G.passphrase +';' ) );
	$( '#qrwebuiap' ).html( qr( 'http://'+ G.hostapdip ) );
	$( '#boxqr' ).removeClass( 'hide' );
}
function wlanScan() {
	bash( '/srv/http/bash/network-scanwlan.sh '+ G.wlcurrent, function( list ) {
		var good = -60;
		var fair = -67;
		var html = '';
		if ( list.length ) {
			$.each( list, function( i, val ) {
				var profile = val.profile;
				html += '<li data-db="'+ val.dbm +'" data-ssid="'+ val.ssid +'" data-encrypt="'+ val.encrypt +'" data-wpa="'+ val.wpa +'"';
				html += val.connected  ? ' data-connected="1"' : '';
				html += val.gateway ? ' data-gateway="'+ val.gateway +'"' : '';
				html += val.ip ? ' data-ip="'+ val.ip +'"' : '';
				html += ' data-dhcp="'+ val.dhcp +'"';
				html += val.password ? ' data-password="'+ val.password +'"' : '';
				html += profile ? ' data-profile="'+ profile +'"' : '';
				html += '><i class="fa fa-wifi-'+ ( val.dbm > good ? 3 : ( val.dbm < fair ? 1 : 2 ) ) +'"></i>';
				html += val.connected ? '<grn>&bull;</grn>&ensp;' : '';
				html += val.dbm < fair ? '<gr>'+ val.ssid +'</gr>' : val.ssid;
				html += val.encrypt === 'on' ? ' <i class="fa fa-lock"></i>' : '';
				html += '<gr>'+ val.dbm +' dBm</gr>';
				html += profile && !val.connected ? '&ensp;<i class="fa fa-save-circle wh"></i>' : '';
			} );
		} else {
			html += '<li><i class="fa fa-lock"></i><gr>(no accesspoints found)</gr></li>';
		}
		$( '#listwifi' ).html( html +'</li>' );
		intervalscan = setTimeout( wlanScan, 12000 );
	}, 'json' );
}
function wlanStatus() {
	$( '#divinterface, #divwebui, #divaccesspoint' ).addClass( 'hide' );
	$( '#divwifi' ).removeClass( 'hide' );
	wlanScan();
}

refreshData = function() {
	if ( !$( '#divwifi' ).hasClass( 'hide' ) ) {
		wlanStatus();
	} else if ( !$( '#divbluetooth' ).hasClass( 'hide' ) ) {
		btScan();
	} else {
		nicsStatus();
	}
	resetLocal();
}
refreshData();
//---------------------------------------------------------------------------------------
var accesspoint = $( '#accesspoint' ).length;
$( '.back' ).click( function() {
	G.wlcurrent = '';
	clearTimeout( intervalscan );
	$( '#divinterface, #divwebui, #divaccesspoint' ).removeClass( 'hide' );
	$( '#divwifi, #divbluetooth' ).addClass( 'hide' );
	$( '#listwifi, #listbt' ).empty();
	nicsStatus();
} );
$( '#listinterfaces' ).on( 'click', 'li', function( e ) {
	var $this = $( this );
	G.wlcurrent = $this.prop( 'class' );
	if ( G.wlcurrent !== 'eth0' ) {
		if ( G.wlcurrent !== 'bt' ) {
			if ( G.hostapd && G.wlcurrent === 'wlan0' ) {
				info( {
					  icon    : 'wifi-3'
					, title   : 'Wi-Fi'
					, message : 'Access Point must be disabled.'
				} );
				return
			} else {
				wlanStatus();
			}
		} else {
			var name = $( this ).data( 'name' );
			var connected = $( this ).data( 'connected' );
			var mac = $( this ).data( 'mac' );
			if ( $( e.target ).hasClass( 'fa-bluetooth' ) && name ) {
				info( {
					  icon    : 'bluetooth'
					, title   : 'Bluetooth'
					, message : name
					, buttonwidth : 1
					, buttonlabel : '<i class="fa fa-minus-circle"></i>Forget'
					, buttoncolor : '#bb2828'
					, button      : function() {
						console.log( "/srv/http/bash/network.sh btremove$'\n'"+ mac )
						bash( "/srv/http/bash/network.sh btremove$'\n'"+ mac );
					}
					, oklabel : connected ? 'Disconnect' : 'Connect'
					, okcolor : connected ? '#de810e' : ''
					, ok      : function() {
						if ( connected ) {
							bash( '/srv/http/bash/network.sh btdisconnect' );
						} else {
							bash( '/srv/http/bash/network.sh btpair' );
						}
					}
				} );
			} else {
				$( '#divinterface, #divwebui, #divaccesspoint' ).addClass( 'hide' );
				$( '#divbluetooth' ).removeClass( 'hide' );
				btScan();
			}
		}
	} else {
		if ( !$this.find( 'grn' ).length ) return
		
		editLAN( {
			  ip      : $this.data( 'ip' ) || ''
			, gateway : $this.data( 'gateway' ) || ''
			, dhcp    : $this.data( 'dhcp' )
		} );
		$( '#infoCheckBox' ).on( 'click', 'input', function() {
			$( '#infoText' ).toggle( $( this ).prop( 'checked' ) );
		} );
	}
} );
$( '#listwifi' ).on( 'click', 'li', function( e ) {
	var $this = $( this );
	var connected = $this.data( 'connected' );
	var profile = $this.data( 'profile' ) || connected;
	var ssid = $this.data( 'ssid' );
	var ip = $this.data( 'ip' );
	var gw = $this.data( 'gateway' );
	var wpa = $this.data( 'wpa' ) || 'wep';
	var dhcp = $this.data( 'dhcp' );
	var encrypt = $this.data( 'encrypt' ) === 'on';
	var password = $this.data( 'password' );
	if ( !profile ) {
		if ( encrypt ) {
			info( {
				  icon          : 'wifi-3'
				, title         : ssid
				, passwordlabel : 'Password'
				, oklabel       : 'Connect'
				, ok            : function() {
					connect( [ ssid, 'dhcp', wpa, $( '#infoPasswordBox' ).val() ] );
				}
			} );
		} else {
			connect( [ ssid, 'dhcp' ] );
		}
		return
	}
	
	info( {
		  icon        : 'wifi-3'
		, title       : ssid
		, message     : !connected ? 'Saved connection' : '<div class="colL">'
				+ ( dhcp === 'dhcp' ? 'DHCP IP' : 'Static IP' ) +'<br>'
				+'Gateway :'
			+'</div>'
			+'<div class="colR wh" style="text-align: left;">'
				+ ip +'<br>'
				+ gw
			+'</div>'
		, buttonwidth : 1
		, buttonlabel : [
			  '<i class="fa fa-minus-circle"></i> Forget'
			, '<i class="fa fa-save-circle"></i> IP'
		]
		, buttoncolor : [
			  '#bb2828'
			, ''
		]
		, button      : [
			  function() {
				clearTimeout( intervalscan );
				notify( ssid, 'Forget ...', 'wifi-3' );
				bash( [ 'disconnect', G.wlcurrent, ssid ] );
			}
			, function() {
				if ( connected ) {
					var data = {
						  Address  : ip
						, Gateway  : gw
						, Security : wpa
						, Key      : password
						, dhcp     : dhcp
					}
					editWiFi( ssid, data );
				} else {
					editWiFi( ssid, 0 );
				}
			}
		]
		, oklabel : connected ? 'Disconnect' : 'Connect'
		, okcolor : connected ? '#de810e' : ''
		, ok      : function() {
			clearTimeout( intervalscan );
			notify( ssid, connected ? 'Disconnect ...' : 'Connect ...', 'wifi-3 blink' );
			if ( connected ) {
				bash( [ 'disconnect', G.wlcurrent ] );
			} else {
				connect( [ ssid ] );
			}
		}
	} );
} );
$( '#add' ).click( function() {
	editWiFi();
} );
$( '#listbt' ).on( 'click', 'li', function( e ) {
	$this = $( this );
	var mac = $this.data( 'mac' );
	var name = '<wh>'+ $this.find( '.liname' ).text() +'</wh>';
	if ( $this.data( 'connected' ) ) {
		notify( 'Bluetooth', 'Disconnect ...', 'bluetooth' );
		bash( [ 'btdisconnect', mac ], function( data ) {
			bannerHide();
			btScan();
		} );
	} else {
		notify( 'Bluetooth', 'Pair ...', 'bluetooth' );
		bash( [ 'btpair', mac ], function( data ) {
			bannerHide();
			if ( data != -1 ) {
				$( '.back' ).click();
			} else {
				info( {
					  icon      : 'bluetooth'
					, title     : 'Bluetooth'
					, message   : 'Pair '+ name +' failed'
				} );
			}
		} );
	}
} );
$( '#accesspoint' ).change( function() {
	if ( !$( '#divinterface li.wlan0' ).length ) {
		info( {
			  icon    : 'wifi-3'
			, title   : 'Wi-Fi'
			, message : 'Wi-Fi device not available.'
					   +'<br>Enable in Sysytem settings.'
		} );
		$( this ).prop( 'checked', 0 );
		return
	}
	
	hostapd = $( this ).prop( 'checked' );
	if ( hostapd ) {
		if ( $( '#divinterface li.wlan0' ).data( 'connected' ) ) {
			info( {
				  icon    : 'network'
				, title   : 'Access Point'
				, message : 'Wi-Fi wlan0 must be disconnected.'
			} );
			$( this ).prop( 'checked', 0 );
			return
		}
		
	} else {
		$( '#boxqr, #settings-accesspoint' ).addClass( 'hide' );
	}
	G.hostapd = hostapd;
	notify( 'RPi Access Point', G.hostapd, 'wifi-3' );
	bash( [ 'accesspoint', G.hostapd, G.hostapdip ] );
} );
$( '#settings-accesspoint' ).click( function() {
	info( {
		  icon      : 'network'
		, title     : 'Access Point Settings'
		, message   : 'Password - at least 8 characters'
		, textlabel : [ 'Password', 'IP' ]
		, textvalue : [ G.passphrase, G.hostapdip ]
		, textrequired : [ 0, 1 ]
		, ok      : function() {
			var ip = $( '#infoTextBox1' ).val();
			var passphrase = $( '#infoTextBox' ).val();
			if ( ip === G.hostapdip && passphrase === G.passphrase ) return
			
			if ( passphrase.length < 8 ) {
				info( 'Password must be at least 8 characters.' );
				return
			}
			
			G.hostapdip = ip;
			G.passphrase = passphrase;
			var ips = ip.split( '.' );
			var ip3 = ips.pop();
			var ip012 = ips.join( '.' );
			var iprange = ip012 +'.'+ ( +ip3 + 1 ) +','+ ip012 +'.254,24h';
			notify( 'RPi Access Point', 'Change ...', 'wifi-3' );
			bash( [ 'accesspointset', iprange, ip, passphrase ] );
		}
	} );
} );
$( '#ifconfig' ).click( function( e ) {
	codeToggle( e.target, this.id, getIfconfig );
} );
$( '#netctl' ).click( function( e ) {
	codeToggle( e.target, this.id, getNetctl );
} );

} );
