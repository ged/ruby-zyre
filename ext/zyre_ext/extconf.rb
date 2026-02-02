#!/usr/bin/env ruby

require 'rbconfig'
require 'mkmf'

dir_config( 'libzyre' )

have_library( 'zyre' ) or
	abort "No zyre library!"
have_library( 'czmq' ) or
	abort "No czmq library!"
have_library( 'zmq' ) or
	abort "No zmq library!"

have_header( 'zyre.h' ) or
	abort "No zyre.h header!"
have_header( 'czmq.h' ) or
	abort "No czmq.h header!"
have_header( 'zmq.h' ) or
	abort "No zmq.h header!"
have_header( 'ruby/thread.h' ) or
	abort "Your Ruby is too old!"

have_func( 'zyre_set_name', 'zyre.h' )
have_func( 'zyre_set_silent_timeout', 'zyre.h' )
have_func( 'zyre_set_beacon_peer_port', 'zyre.h' )
have_func( 'zyre_set_contest_in_group', 'zyre.h' )
have_func( 'zyre_set_zcert', 'zyre.h' )

have_func( 'zmq_z85_encode', 'zmq.h' )
have_func( 'zmq_z85_decode', 'zmq.h' )

have_func( 'zcert_unset_meta', 'czmq.h' )
have_func( 'zcert_new_from_txt', 'czmq.h' )

create_header()
create_makefile( 'zyre_ext' )

