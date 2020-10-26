#!/usr/bin/python

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

AGENT_INTERFACE = 'org.bluez.Agent1'
path = '/test/autoagent'

class Agent( dbus.service.Object ):
	@dbus.service.method( AGENT_INTERFACE, in_signature='os', out_signature='' )
	def AuthorizeService( self, device, uuid ):
		return

	@dbus.service.method( AGENT_INTERFACE, in_signature='o', out_signature='' )
	def RequestAuthorization( self, device ):
		return

if __name__ == '__main__':
	dbus.mainloop.glib.DBusGMainLoop( set_as_default=True )

	bus = dbus.SystemBus()
    
	Agent( bus, path )
    
	mainloop = GLib.MainLoop()

	obj = bus.get_object( 'org.bluez', '/org/bluez' );
	manager = dbus.Interface( obj, 'org.bluez.AgentManager1' )
	manager.RegisterAgent( path, 'NoInputNoOutput' )
	manager.RequestDefaultAgent( path )

	mainloop.run()
