/*
 *  event.c - An event for or from a Zyre cluster
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "zyre_ext.h"

VALUE rzyre_cZyreEvent;


static void rzyre_event_free( void *ptr );

static const rb_data_type_t rzyre_event_t = {
	"Zyre::Event",
	{
		NULL,
		rzyre_event_free
	},
	0,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY,
};


/*
 * Free function
 */
static void
rzyre_event_free( void *ptr )
{
	zyre_event_destroy( (zyre_event_t **)&ptr );
}


/*
 * Alloc function
 */
static VALUE
rzyre_event_alloc( VALUE klass )
{
	return TypedData_Wrap_Struct( klass, &rzyre_event_t, NULL );
}


/*
 * Fetch the data pointer and check it for sanity.
 */
static inline zyre_event_t *
rzyre_get_event( VALUE self )
{
	zyre_event_t *ptr;

	if ( !IsZyreEvent(self) ) {
		rb_raise( rb_eTypeError, "wrong argument type %s (expected Zyre::Event)",
			rb_class2name(CLASS_OF( self )) );
	}

	ptr = DATA_PTR( self );
	assert( ptr );

	return ptr;
}


/*
 * Async read function; called without the GVL.
 */
static void *
rzyre_read_event( void *node_ptr )
{
	zyre_event_t *event_ptr;
	assert( node_ptr );

	event_ptr = zyre_event_new( (zyre_t *)node_ptr );
	assert( event_ptr );
	return (void *)event_ptr;
}


/*
 * call-seq:
 *    Zyre::Event.new( node )   -> event
 *
 * Read the next event from the given Zyre::Node and wrap it in a Zyre::Event.
 *
 */
static VALUE
rzyre_event_initialize( VALUE self, VALUE node )
{
	zyre_t *node_ptr = rzyre_get_node( node );
	zyre_event_t *ptr;

	assert( node_ptr );

	TypedData_Get_Struct( self, zyre_event_t, &rzyre_event_t, ptr );
	if ( !ptr ) {
		RTYPEDDATA_DATA( self ) = ptr =
			rb_thread_call_without_gvl2( rzyre_read_event, (void *)node_ptr, RUBY_UBF_IO, 0 );

		// Interrupt has arrived instead of an event; raise an Interrupt.
		if ( !ptr ) rb_interrupt();
	}

	return self;
}


/*
 * call-seq:
 *    event.type   -> str
 *
 * Returns event type as a Symbol. Possible values are:
 * :ENTER, :EXIT, :JOIN, :LEAVE, :EVASIVE, :WHISPER, and :SHOUT
 * and for the local node: :STOP
 *
 */
static VALUE
rzyre_event_type( VALUE self )
{
	zyre_event_t *ptr = rzyre_get_event( self );
	const char *type_str = zyre_event_type( ptr );
	const VALUE type = rb_str_new2( type_str );

	return rb_to_symbol( type );
}


/*
 * call-seq:
 *    event.peer_uuid   -> str
 *
 * Return the sending peer's uuid as a string
 */
static VALUE
rzyre_event_peer_uuid( VALUE self ) {
	zyre_event_t *ptr = rzyre_get_event( self );
	const char *uuid_str = zyre_event_peer_uuid( ptr );

	return rb_str_new2( uuid_str );
}


/*
 * call-seq:
 *    event.peer_name
 * 
 * Return the sending peer's public name as a string
 */
static VALUE
rzyre_event_peer_name( VALUE self ) {
	zyre_event_t *ptr = rzyre_get_event( self );
	const char *name_str = zyre_event_peer_name( ptr );

	return rb_str_new2( name_str );
}


/*
 * call-seq:
 *    event.peer_addr
 * 
 * Return the sending peer's ipaddress as a string
 */
static VALUE
rzyre_event_peer_addr( VALUE self ) {
	zyre_event_t *ptr = rzyre_get_event( self );
	const char *addr_str = zyre_event_peer_addr( ptr );

	if ( addr_str ) {
		return rb_str_new2( addr_str );
	} else {
		return Qnil;
	}

}


/*
 * call-seq:
 *    event.event_headers
 * 
 * Returns the event headers, or NULL if there are none
 */
static VALUE
rzyre_event_headers( VALUE self ) {
	zyre_event_t *ptr = rzyre_get_event( self );
	zhash_t *headers = zyre_event_headers( ptr );
	VALUE rhash = rb_hash_new();
	const char *key, *val;

	if ( headers ) {
		key = (const char *)zhash_first( headers );
		while( key ) {
			val = zhash_cursor( headers );
			rb_hash_aset( rhash, rb_str_new2(key), rb_str_new2(val) );
			key = (const char *)zhash_next( headers );
		}
	}

	return rhash;
}


/*
 * call-seq:
 *    event.event_header( name )
 * 
 * Returns value of the header +name+ from the message headers
 * obtained by ENTER. Return nil if no value was found.
 */
static VALUE
rzyre_event_header( VALUE self, VALUE name ) {
	zyre_event_t *ptr = rzyre_get_event( self );
	const char *name_str = StringValueCStr( name );
	const char *value_str = zyre_event_header( ptr, name_str );

	if ( value_str ) {
		return rb_str_new2( value_str );
	} else {
		return Qnil;
	}
}


/*
 * call-seq:
 *    event.event_group
 * 
 * Returns the group name that a SHOUT event was sent to
 */
static VALUE
rzyre_event_group( VALUE self ) {
	zyre_event_t *ptr = rzyre_get_event( self );
	const char *group_str = zyre_event_group( ptr );

	if ( group_str ) {
		return rb_str_new2( group_str );
	} else {
		return Qnil;
	}
}


/*
 * call-seq:
 *    event.event_msg
 * 
 * Returns the incoming message payload.
 */
static VALUE
rzyre_event_msg( VALUE self ) {
	zyre_event_t *ptr = rzyre_get_event( self );
	zmsg_t *msg = zyre_event_msg( ptr );
	VALUE rval = Qnil;

	// :TODO: Support multipart messages when Zyre does.
	if ( msg ) {
		zframe_t *frame = zmsg_first( msg );
		char *str = zframe_strdup( frame );

		rval = rb_utf8_str_new( str, zframe_size(frame) );
		rb_obj_freeze( rval );

		free( str );
	}

	return rval;
}


/*
 * call-seq:
 *    event.print
 * 
 * Print event to zsys log
 */
static VALUE
rzyre_event_print( VALUE self ) {
	zyre_event_t *ptr = rzyre_get_event( self );

	zyre_event_print( ptr );

	return Qtrue;
}


/*
 * Initialize the Event class.
 */
void
rzyre_init_event( void ) {

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rzyre_mZyre = rb_define_module( "Zyre" );
#endif

	/*
	 * Document-class: Zyre::Event
	 *
	 * An event read from a Zyre network.
	 *
	 * Refs:
	 * - https://github.com/zeromq/zyre#readme
	 */
	rzyre_cZyreEvent = rb_define_class_under( rzyre_mZyre, "Event", rb_cObject );

	rb_define_alloc_func( rzyre_cZyreEvent, rzyre_event_alloc );

	rb_define_protected_method( rzyre_cZyreEvent, "initialize", rzyre_event_initialize, 1 );

	rb_define_method( rzyre_cZyreEvent, "type", rzyre_event_type, 0 );
	rb_define_method( rzyre_cZyreEvent, "peer_uuid", rzyre_event_peer_uuid, 0 );
	rb_define_method( rzyre_cZyreEvent, "peer_name", rzyre_event_peer_name, 0 );
	rb_define_method( rzyre_cZyreEvent, "peer_addr", rzyre_event_peer_addr, 0 );
	rb_define_method( rzyre_cZyreEvent, "headers", rzyre_event_headers, 0 );
	rb_define_method( rzyre_cZyreEvent, "header", rzyre_event_header, 1 );
	rb_define_method( rzyre_cZyreEvent, "group", rzyre_event_group, 0 );
	rb_define_method( rzyre_cZyreEvent, "msg", rzyre_event_msg, 0 );
	rb_define_method( rzyre_cZyreEvent, "print", rzyre_event_print, 0 );

	rb_require( "zyre/event" );
}

