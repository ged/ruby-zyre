/*
 *  node.c - A node in a Zyre cluster
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "zyre_ext.h"


VALUE rzyre_cZyreNode;

static void rzyre_node_free( void *ptr );

static const rb_data_type_t rzyre_node_t = {
	"Zyre::Node",
	{
		NULL,
		rzyre_node_free
	},
	0,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY,
};


/*
 * Free function
 */
static void
rzyre_node_free( void *ptr )
{
	if ( ptr ) {
		zyre_destroy( (zyre_t **)&ptr );
	}
}


/*
 * Alloc function
 */
static VALUE
rzyre_node_alloc( VALUE klass )
{
	return TypedData_Wrap_Struct( klass, &rzyre_node_t, NULL );
}


/*
 * Fetch the data pointer and check it for sanity.
 */
inline zyre_t *
rzyre_get_node( VALUE self )
{
	if ( !IsZyreNode(self) ) {
		rb_raise( rb_eTypeError, "wrong argument type %s (expected Zyre::Node)",
			rb_class2name(CLASS_OF( self )) );
	}

	return DATA_PTR( self );
}


/*
 * call-seq:
 *    Zyre::Node.new           -> node
 *    Zyre::Node.new( name )   -> node
 *
 * Create a new (unstarted) Zyre node. If the +name+ is not given, Zyre generates a
 * randomized node name from the UUID
 *
 */
static VALUE
rzyre_node_initialize( int argc, VALUE *argv, VALUE self )
{
	zyre_t *ptr;
	VALUE name;
	char *name_str = NULL;

	rb_scan_args( argc, argv, "01", &name );

	if ( !NIL_P(name) ) {
		name_str = StringValueCStr( name );
	}

	TypedData_Get_Struct( self, zyre_t, &rzyre_node_t, ptr );
	if ( !ptr ) {
		RTYPEDDATA_DATA( self ) = ptr = zyre_new( name_str );
		assert( ptr );
	}

	return self;
}


/*
 * call-seq:
 *    node.uuid   -> str
 *
 * Return the node's UUID as a String.
 *
 */
static VALUE
rzyre_node_uuid( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *uuid_str = zyre_uuid( ptr );
	VALUE uuid = rb_str_new2( uuid_str );

	return rb_str_freeze( uuid );
}


/*
 * call-seq:
 *    node.name   -> str
 *
 * Return the node name.
 *
 */
static VALUE
rzyre_node_name( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *name_str = zyre_name( ptr );
	VALUE name = rb_str_new2( name_str );

	return rb_str_freeze( name );
}


/*
 * call-seq:
 *    node.name = str
 *
 * Set the public name of this node overriding the default. The name is
 * provided during discovery and come in each ENTER message.
 *
 */
static VALUE
rzyre_node_name_eq( VALUE self, VALUE new_name )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *name_str = StringValueCStr( new_name );

	zyre_set_name( ptr, name_str );

	return Qtrue;
}


/*
 * call-seq:
 *    node.port = integer
 *
 * Set UDP beacon discovery port. Defaults to 5670. This call overrides
 * the default so that you can create independent clusters on the same network, for
 * e.g. development vs. production. Has no effect after #start.
 *
 */
static VALUE
rzyre_node_port_eq( VALUE self, VALUE new_port )
{
	zyre_t *ptr = rzyre_get_node( self );
	int port_nbr = FIX2INT( new_port );

	zyre_set_port( ptr, port_nbr );

	return Qtrue;
}


/*
 * call-seq:
 *    node.evasive_timeout = milliseconds
 *
 * Set the peer evasiveness timeout in milliseconds. Default is 5000.
 * This can be tuned in order to deal with expected network conditions
 * and the response time expected by the application. This is tied to
 * the beacon interval and rate of messages received.
 *
 */
static VALUE
rzyre_node_evasive_timeout_eq( VALUE self, VALUE timeout )
{
	zyre_t *ptr = rzyre_get_node( self );
	int timeout_ms = FIX2INT( timeout );

	zyre_set_evasive_timeout( ptr, timeout_ms );

	return Qtrue;
}


/*
 * call-seq:
 *    node.silent_timeout = milliseconds
 *
 * Set the peer silence timeout, in milliseconds. Default is 5000.
 * This can be tuned in order to deal with expected network conditions
 * and the response time expected by the application. This is tied to
 * the beacon interval and rate of messages received.
 * Silence is triggered one second after the timeout if peer has not
 * answered ping and has not sent any message.
 *
 * NB: this is currently redundant with the evasiveness timeout. Both
 * affect the same timeout value.
 *
 */
#ifdef HAVE_ZYRE_SET_SILENT_TIMEOUT
static VALUE
rzyre_node_silent_timeout_eq( VALUE self, VALUE timeout )
{
	zyre_t *ptr = rzyre_get_node( self );
	int timeout_ms = FIX2INT( timeout );

	zyre_set_silent_timeout( ptr, timeout_ms );

	return Qtrue;
}
#endif // HAVE_ZYRE_SET_SILENT_TIMEOUT


/*
 * call-seq:
 *    node.expired_timeout = milliseconds
 *
 * Set the peer expiration timeout, in milliseconds. Default is 30000.
 * This can be tuned in order to deal with expected network conditions
 * and the response time expected by the application. This is tied to
 * the beacon interval and rate of messages received.
 *
 */
static VALUE
rzyre_node_expired_timeout_eq( VALUE self, VALUE timeout )
{
	zyre_t *ptr = rzyre_get_node( self );
	int timeout_ms = FIX2INT( timeout );

	zyre_set_expired_timeout( ptr, timeout_ms );

	return Qtrue;
}


/*
 * call-seq:
 *    node.interval = milliseconds
 *
 * Set UDP beacon discovery interval in milliseconds. Default is instant
 * beacon exploration followed by pinging every 1000 msecs.
 *
 */
static VALUE
rzyre_node_interval_eq( VALUE self, VALUE interval )
{
	zyre_t *ptr = rzyre_get_node( self );
	size_t interval_ms = FIX2INT( interval );

	zyre_set_interval( ptr, interval_ms );

	return Qtrue;
}


/*
 * call-seq:
 *    node.interface = string
 *
 * Set network interface for UDP beacons. If you do not set this, CZMQ will
 * choose an interface for you. On boxes with several interfaces you should
 * specify which one you want to use, or strange things can happen.
 *
 */
static VALUE
rzyre_node_interface_eq( VALUE self, VALUE interface )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *interface_str = StringValueCStr( interface );

	zyre_set_interface( ptr, interface_str );

	return Qtrue;
}


/*
 * call-seq:
 *    node.endpoint = string
 *
 * By default, Zyre binds to an ephemeral TCP port and broadcasts the local
 * host name using UDP beaconing. When you call this method, Zyre will use
 * gossip discovery instead of UDP beaconing. You MUST set up the gossip
 * service separately using #gossip_bind and #gossip_connect. Note that the
 * endpoint MUST be valid for both bind and connect operations. You can use
 * `inproc://`, `ipc://`, or `tcp://` transports (for `tcp://`, use an IP
 * address that is meaningful to remote as well as local nodes). Returns
 * +true+ if the bind was successful.
 *
 */
static VALUE
rzyre_node_endpoint_eq( VALUE self, VALUE endpoint )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *endpoint_str = StringValueCStr( endpoint );
	int res;

	res = zyre_set_endpoint( ptr, "%s", endpoint_str );

	if ( res == 0 ) return Qtrue;
	return Qfalse;
}


/*
 * call-seq:
 *    node.endpoint   -> str
 *
 * Return the endpoint being used by the Node if there is one.
 *
 */
static VALUE
rzyre_node_endpoint( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );
	zsock_t *sock = zyre_socket( ptr );
	const char *endpoint_str = zsock_endpoint( sock );

	return rb_str_new2( endpoint_str );
}


/*
 * call-seq:
 *    node.verbose!
 *
 * Set verbose mode; this tells the node to log all traffic as well as
 * all major events.
 *
 */
static VALUE
rzyre_node_verbose_bang( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );

	zyre_set_verbose( ptr );

	return Qtrue;
}


/*
 * call-seq:
 *    node.set_header( name, value )
 *
 * Set node header; these are provided to other nodes during discovery
 * and come in each `ENTER` message.
 *
 */
static VALUE
rzyre_node_set_header( VALUE self, VALUE name, VALUE value )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *name_str = StringValueCStr( name );
	const char *value_str = StringValueCStr( value );

	rzyre_log_obj( self, "debug", "Setting header `%s` to `%s`", name_str, value_str );
	zyre_set_header( ptr, name_str, "%s", value_str );

	return Qtrue;
}


/*
 * call-seq:
 *    node.gossip_bind( endpoint )
 *
 * Set-up gossip discovery of other nodes. At least one node in the cluster
 * must bind to a well-known gossip endpoint, so other nodes can connect to
 * it. Note that gossip endpoints are completely distinct from Zyre node
 * endpoints, and should not overlap (they can use the same transport).
 *
 */
static VALUE
rzyre_node_gossip_bind( VALUE self, VALUE endpoint )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *endpoint_str = StringValueCStr( endpoint );

	assert( endpoint_str );
	rzyre_log_obj( self, "debug", "Binding to gossip endpoint %s.", endpoint_str );
	zyre_gossip_bind( ptr, "%s", endpoint_str );

	return Qtrue;
}


/*
 * call-seq:
 *    node.gossip_connect( endpoint )
 *
 * Set-up gossip discovery of other nodes. A node may connect to multiple
 * other nodes, for redundancy paths. For details of the gossip network
 * design, see the CZMQ zgossip class.
 *
 */
static VALUE
rzyre_node_gossip_connect( VALUE self, VALUE endpoint )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *endpoint_str = StringValueCStr( endpoint );

	assert( endpoint_str );
	rzyre_log_obj( self, "debug", "Connecting to gossip endpoint %s.", endpoint_str );
	zyre_gossip_connect( ptr, "%s", endpoint_str );

	return Qtrue;
}


/*
 * call-seq:
 *    node.start  -> bool
 *
 * Start node, after setting header values. When you start a node it
 * begins discovery and connection. Returns +true+ if the node was started
 * successfully.
 *
 */
static VALUE
rzyre_node_start( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );
	int res;

	rzyre_log_obj( self, "debug", "Starting." );
	res = zyre_start( ptr );

	if ( res == 0 ) return Qtrue;
	return Qfalse;
}


/*
 * call-seq:
 *    node.stop
 *
 * Stop node; this signals to other peers that this node will go away.
 * This is polite; however you can also just destroy the node without
 * stopping it.
 *
 */
static VALUE
rzyre_node_stop( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );

	assert( ptr );
	rzyre_log_obj( self, "debug", "Stopping." );
	zyre_stop( ptr );

	return Qtrue;
}


/*
 * call-seq:
 *    node.join( group_name )    -> int
 *
 * Join a named group; after joining a group you can send messages to
 * the group and all Zyre nodes in that group will receive them.
 *
 */
static VALUE
rzyre_node_join( VALUE self, VALUE group )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *group_str = StringValueCStr( group );
	int res;

	rzyre_log_obj( self, "debug", "Joining group %s.", group_str );
	res = zyre_join( ptr, group_str );

	return INT2FIX( res );
}


/*
 * call-seq:
 *    node.leave( group_name )    -> int
 *
 * Leave a group.
 *
 */
static VALUE
rzyre_node_leave( VALUE self, VALUE group )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *group_str = StringValueCStr( group );
	int res;

	rzyre_log_obj( self, "debug", "Leaving group %s.", group_str );
	res = zyre_leave( ptr, group_str );

	return INT2FIX( res );
}


/*
 * call-seq:
 *    node.recv -> zyre_event
 *
 * Receive the next event from the network; the message may be a control
 * message (ENTER, EXIT, JOIN, LEAVE) or data (WHISPER, SHOUT).
 * Returns a Zyre::Event.
 *
 */
static VALUE
rzyre_node_recv( VALUE self )
{
	return rb_funcall( rzyre_cZyreEvent, rb_intern("from_node"), 1, self );
}


struct node_zmsg_call {
	zyre_t *node;
	zmsg_t *msg;
	VALUE msg_parts;
	char *peer_or_group;
};
typedef struct node_zmsg_call node_zmsg_call_t;


static VALUE
rzyre_do_node_whisper( VALUE call )
{
	node_zmsg_call_t *call_ptr = (node_zmsg_call_t *)call;
	VALUE msg_part;
	int rval;

	for ( long i = 0 ; i < RARRAY_LEN(call_ptr->msg_parts) ; i++ ) {
		msg_part = rb_ary_entry( call_ptr->msg_parts, i );
		zmsg_addstr( call_ptr->msg, StringValueCStr(msg_part) );
	}

	rzyre_log( "debug", "zyre_whisper" );
	rval = zyre_whisper( call_ptr->node, call_ptr->peer_or_group, &call_ptr->msg );

	return rval ? Qtrue : Qfalse;
}


static VALUE
rzyre_do_node_shout( VALUE call )
{
	node_zmsg_call_t *call_ptr = (node_zmsg_call_t *)call;
	VALUE msg_part;
	int rval;

	for ( long i = 0 ; i < RARRAY_LEN(call_ptr->msg_parts) ; i++ ) {
		msg_part = rb_ary_entry( call_ptr->msg_parts, i );
		zmsg_addstr( call_ptr->msg, StringValueCStr(msg_part) );
	}

	rzyre_log( "debug", "zyre_shout" );
	rval = zyre_shout( call_ptr->node, call_ptr->peer_or_group, &call_ptr->msg );

	return rval ? Qtrue : Qfalse;
}


/* Ensure method for Ruby methods that build zmsgs to ensure they don't leak. */
static VALUE
rzyre_free_zmsg( VALUE call )
{
	node_zmsg_call_t *call_ptr = (node_zmsg_call_t *)call;

	rzyre_log( "debug", "In the zmsg free ensure." );
	if ( call_ptr->msg ) {
		rzyre_log( "debug", "  not already freed; zmsg_destroy()ing it" );
		zmsg_destroy( &call_ptr->msg );
	} else {
		rzyre_log( "debug", "  already freed." );
	}

	return Qnil;
}


/*
 * call-seq:
 *    node.whisper( peer_uuid, *messages )  -> int
 *
 * Send a +message+ to a single +peer+ specified as a UUID string.
 *
 */
static VALUE
rzyre_node_whisper( int argc, VALUE *argv, VALUE self )
{
	node_zmsg_call_t call = {
		.node = rzyre_get_node( self ),
		.msg = NULL,
		.peer_or_group = NULL,
		.msg_parts = Qnil
	};
	VALUE peer_uuid, msg_parts;

	rb_scan_args( argc, argv, "1*", &peer_uuid, &msg_parts );

	call.peer_or_group = StringValueCStr( peer_uuid );
	call.msg_parts = msg_parts;
	call.msg = zmsg_new();

	return rb_ensure( rzyre_do_node_whisper, (VALUE)&call, rzyre_free_zmsg, (VALUE)&call );
}


/*
 * call-seq:
 *    node.shout( group, *messages )   -> int
 *
 * Send +message+ to a named +group+.
 *
 */
static VALUE
rzyre_node_shout( int argc, VALUE *argv, VALUE self )
{
	node_zmsg_call_t call = {
		.node = rzyre_get_node( self ),
		.msg = NULL,
		.peer_or_group = NULL,
		.msg_parts = Qnil
	};
	VALUE group_name, msg_parts;

	rb_scan_args( argc, argv, "1*", &group_name, &msg_parts );

	call.peer_or_group = StringValueCStr( group_name );
	call.msg_parts = msg_parts;
	call.msg = zmsg_new();

	return rb_ensure( rzyre_do_node_shout, (VALUE)&call, rzyre_free_zmsg, (VALUE)&call );
}


/*
 * call-seq:
 *    node.peers -> array
 *
 * Return an Array of current peer UUIDs.
 *
 */
static VALUE
rzyre_node_peers( VALUE self )
{
	zyre_t *ptr;
	zlist_t *peers;
	VALUE rary = rb_ary_new();
	char *item = NULL;

	ptr = rzyre_get_node( self );
	assert( ptr );

	peers = zyre_peers( ptr );
	assert( peers );

	item = zlist_first( peers );
	while ( item ) {
		rb_ary_push( rary, rb_str_new2(item) );
		item = zlist_next( peers );
	}

	zlist_destroy( &peers );
	return rary;
}


/*
 * call-seq:
 *    node.peers_by_group( group ) -> array
 *
 * Return an Array of the current peers in the specified +group+.
 *
 */
static VALUE
rzyre_node_peers_by_group( VALUE self, VALUE group )
{
	zyre_t *ptr;
	const char *group_str = StringValueCStr( group );
	zlist_t *peers;
	VALUE rary = rb_ary_new();
	char *item = NULL;

	ptr = rzyre_get_node( self );
	assert( ptr );

	peers = zyre_peers_by_group( ptr, group_str );
	assert( peers );

	item = zlist_first( peers );
	while ( item ) {
		rb_ary_push( rary, rb_str_new2(item) );
		item = zlist_next( peers );
	}

	zlist_destroy( &peers );
	return rary;
}


/*
 * call-seq:
 *    node.own_groups -> array
 *
 * Return an Array of the names of the receiving node's current groups.
 *
 */
static VALUE
rzyre_node_own_groups( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );
	zlist_t *groups = zyre_own_groups( ptr );
	VALUE rary = rb_ary_new();
	char *item = NULL;

	assert( groups );

	item = zlist_first( groups );
	while ( item ) {
		rb_ary_push( rary, rb_str_new2(item) );
		item = zlist_next( groups );
	}

	zlist_destroy( &groups );
	return rary;
}


/*
 * call-seq:
 *    node.peer_groups  -> array
 *
 * Return an Array of the names of groups known through connected peers.
 *
 */
static VALUE
rzyre_node_peer_groups( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );
	zlist_t *groups = zyre_peer_groups( ptr );
	VALUE rary = rb_ary_new();
	char *item = NULL;

	assert( groups );

	item = zlist_first( groups );
	while ( item ) {
		rb_ary_push( rary, rb_str_new2(item) );
		item = zlist_next( groups );
	}

	zlist_destroy( &groups );
	return rary;
}


/*
 * call-seq:
 *    node.peer_address( peer_uuid ) -> str
 *
 * Return the endpoint of a connected +peer+.
 * Returns nil if peer does not exist.
 *
 */
static VALUE
rzyre_node_peer_address( VALUE self, VALUE peer_uuid )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *peer = StringValueCStr( peer_uuid );
	char *address = zyre_peer_address( ptr, peer );
	VALUE rval = Qnil;

	if ( strnlen(address, BUFSIZ) ) {
		rval = rb_str_new2( address );
	}

	free( address );
	return rval;
}


/*
 * call-seq:
 *    node.peer_header_value( peer_id, header_name )    -> str
 *
 * Return the value of a header of a conected peer. Returns nil if
 * peer or key doesn't exist.
 *
 */
static VALUE
rzyre_node_peer_header_value( VALUE self, VALUE peer_id, VALUE header_name )
{
	zyre_t *ptr = rzyre_get_node( self );
	const char *peer_id_str = StringValueCStr( peer_id );
	const char *header_name_str = StringValueCStr( header_name );
	char *res;
	VALUE rval = Qnil;

	res = zyre_peer_header_value( ptr, peer_id_str, header_name_str );

	// TODO: Encoding + frozen
	if ( res ) {
		rval = rb_str_new2( res );
		xfree( res );
	}

	return rval;
}


/*
 * call-seq:
 *    node.print
 *
 * Print zyre node information to stdout.
 *
 */
static VALUE
rzyre_node_print( VALUE self )
{
	zyre_t *ptr = rzyre_get_node( self );

	zyre_print( ptr );

	return Qtrue;
}


/*
 * Node class init
 */
void
rzyre_init_node( void )
{

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rzyre_mZyre = rb_define_module( "Zyre" );
#endif

	/*
	 * Document-class: Zyre::Node
	 *
	 * A node in a Zyre cluster.
	 *
	 * Refs:
	 * - https://github.com/zeromq/zyre#readme
	 */
	rzyre_cZyreNode = rb_define_class_under( rzyre_mZyre, "Node", rb_cData );

	rb_define_alloc_func( rzyre_cZyreNode, rzyre_node_alloc );

	rb_define_protected_method( rzyre_cZyreNode, "initialize", rzyre_node_initialize, -1 );

	rb_define_method( rzyre_cZyreNode, "uuid", rzyre_node_uuid, 0 );
	rb_define_method( rzyre_cZyreNode, "name", rzyre_node_name, 0 );

	rb_define_method( rzyre_cZyreNode, "name=", rzyre_node_name_eq, 1 );
	rb_define_method( rzyre_cZyreNode, "port=", rzyre_node_port_eq, 1 );
	rb_define_method( rzyre_cZyreNode, "evasive_timeout=", rzyre_node_evasive_timeout_eq, 1 );
#ifdef HAVE_ZYRE_SET_SILENT_TIMEOUT
	rb_define_method( rzyre_cZyreNode, "silent_timeout=", rzyre_node_silent_timeout_eq, 1 );
#endif
	rb_define_method( rzyre_cZyreNode, "expired_timeout=", rzyre_node_expired_timeout_eq, 1 );
	rb_define_method( rzyre_cZyreNode, "interval=", rzyre_node_interval_eq, 1 );
	rb_define_method( rzyre_cZyreNode, "interface=", rzyre_node_interface_eq, 1 );
	rb_define_method( rzyre_cZyreNode, "endpoint=", rzyre_node_endpoint_eq, 1 );
	rb_define_method( rzyre_cZyreNode, "endpoint", rzyre_node_endpoint, 0 );

	rb_define_method( rzyre_cZyreNode, "set_header", rzyre_node_set_header, 2 );

	rb_define_method( rzyre_cZyreNode, "gossip_bind", rzyre_node_gossip_bind, 1 );
	rb_define_method( rzyre_cZyreNode, "gossip_connect", rzyre_node_gossip_connect, 1 );

	rb_define_method( rzyre_cZyreNode, "start", rzyre_node_start, 0 );
	rb_define_method( rzyre_cZyreNode, "stop", rzyre_node_stop, 0 );

	rb_define_method( rzyre_cZyreNode, "join", rzyre_node_join, 1 );
	rb_define_method( rzyre_cZyreNode, "leave", rzyre_node_leave, 1 );

	rb_define_method( rzyre_cZyreNode, "recv", rzyre_node_recv, 0 );

	rb_define_method( rzyre_cZyreNode, "whisper", rzyre_node_whisper, -1 );
	rb_define_method( rzyre_cZyreNode, "shout", rzyre_node_shout, -1 );

	rb_define_method( rzyre_cZyreNode, "peers", rzyre_node_peers, 0 );
	rb_define_method( rzyre_cZyreNode, "peers_by_group", rzyre_node_peers_by_group, 1 );
	rb_define_method( rzyre_cZyreNode, "own_groups", rzyre_node_own_groups, 0 );
	rb_define_method( rzyre_cZyreNode, "peer_groups", rzyre_node_peer_groups, 0 );
	rb_define_method( rzyre_cZyreNode, "peer_address", rzyre_node_peer_address, 1 );
	rb_define_method( rzyre_cZyreNode, "peer_header_value", rzyre_node_peer_header_value, 2 );

	rb_define_method( rzyre_cZyreNode, "verbose!", rzyre_node_verbose_bang, 0 );
	rb_define_method( rzyre_cZyreNode, "print", rzyre_node_print, 0 );

#ifdef ZYRE_BUILD_DRAFT_API

	rb_define_method( rzyre_cZyreNode, "set_beacon_peer_port", rzyre_node_set_beacon_peer_port, -1 );
	rb_define_method( rzyre_cZyreNode, "set_contest_in_group", rzyre_node_set_contest_in_group, -1 );
	rb_define_method( rzyre_cZyreNode, "set_advertised_endpoint", rzyre_node_set_advertised_endpoint, -1 );
	rb_define_method( rzyre_cZyreNode, "set_zcert", rzyre_node_set_zcert, -1 );
	rb_define_method( rzyre_cZyreNode, "set_zap_domain", rzyre_node_set_zap_domain, -1 );
	rb_define_method( rzyre_cZyreNode, "gossip_connect_curve", rzyre_node_gossip_connect_curve, -1 );
	rb_define_method( rzyre_cZyreNode, "gossip_unpublish", rzyre_node_gossip_unpublish, -1 );
	rb_define_method( rzyre_cZyreNode, "require_peer", rzyre_node_require_peer, -1 );

#endif // ZYRE_BUILD_DRAFT_API

	rb_require( "zyre/node" );
}

