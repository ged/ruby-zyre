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
	if ( ptr ) {
		zyre_event_destroy( (zyre_event_t **)&ptr );
	}
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
 *    Zyre::Event.from_node( node )   -> event
 *
 * Read the next event from the given Zyre::Node and wrap it in a Zyre::Event.
 *
 */
static VALUE
rzyre_event_s_from_node( VALUE klass, VALUE node )
{
	zyre_t *node_ptr = rzyre_get_node( node );
	zyre_event_t *event;

	assert( node_ptr );

	event = rb_thread_call_without_gvl2( rzyre_read_event, (void *)node_ptr, RUBY_UBF_IO, 0 );

	if ( event ) {
		const char *event_type = zyre_event_type( event );
		VALUE event_type_s = rb_utf8_str_new_cstr( event_type );
		VALUE event_class = rb_funcall( klass, rb_intern("type_by_name"), 1, event_type_s );
		VALUE event_instance = rb_class_new_instance( 0, NULL, event_class );

		RTYPEDDATA_DATA( event_instance ) = event;

		return event_instance;
	} else {
		return Qnil;
	}
}


char *
rzyre_copy_string( VALUE string )
{
	const char *c_string = StringValueCStr( string );
	char *copy = (char *) zmalloc( strnlen(c_string, BUFSIZ) + 1 );

	assert( copy );
	stpncpy( copy, c_string, strnlen(c_string, BUFSIZ) + 1 );

	return copy;
}


char *
rzyre_copy_required_string( VALUE string, const char *field_name )
{
	if ( RB_TYPE_P(string, T_UNDEF) ) {
		rb_raise( rb_eArgError, "missing required field :%s", field_name );
	} else {
		return rzyre_copy_string( string );
	}
}


static int
rzyre_zhash_from_rhash_i( VALUE key, VALUE value, VALUE zhash_ptr )
{
	zhash_t *zhash = (zhash_t *)zhash_ptr;

	zhash_insert( zhash, StringValueCStr(key), StringValueCStr(value) );

	return ST_CONTINUE;
}


static zhash_t *
rzyre_zhash_from_rhash( VALUE ruby_hash )
{
	zhash_t *zhash = zhash_new();

	// If it was passed, it should be a Hash
	// :FIXME: Allow anything that ducktypes with :each_pair?
	if ( !RB_TYPE_P(ruby_hash, T_UNDEF) ) {
		Check_Type( ruby_hash, T_HASH );
		rb_hash_foreach( ruby_hash, rzyre_zhash_from_rhash_i, (VALUE)zhash );
	}

	return zhash;
}


/*
 * call-seq:
 *    Zyre::Event.synthesized( type, peer_uuid, **fields )   -> event
 *
 * Create an event in memory without going through a Zyre::Node. This is useful for
 * testing.
 *
 *    uuid = UUID.generate
 *    event = Zyre::Event.synthesized( :ENTER, uuid, peer_name: 'node1' )
 *    expect( some_system.handle_event(event) ).to have_handled_an_enter_event
 *
 */
static VALUE
rzyre_event_s_synthesize( int argc, VALUE *argv, VALUE klass )
{
	VALUE rval, event_type, peer_uuid, kwargs, event_class;
	static VALUE kwvals[5];
	static ID keyword_ids[5];
	zyre_event_t *ptr = NULL;

	// Parse the arguments + keyword arguments
	if ( !keyword_ids[0] ) {
		CONST_ID( keyword_ids[0], "peer_name");
		CONST_ID( keyword_ids[1], "headers");
		CONST_ID( keyword_ids[2], "peer_addr");
		CONST_ID( keyword_ids[3], "group");
		CONST_ID( keyword_ids[4], "msg");
	}

	rb_scan_args( argc, argv, "2:", &event_type, &peer_uuid, &kwargs );
	if ( RTEST(kwargs) ) {
		rb_get_kwargs( kwargs, keyword_ids, 0, 5, kwvals );
	}

	// Translate the event type argument into the appropriate class and instantiate it
	event_class = rb_funcall( klass, rb_intern("type_by_name"), 1, event_type );
	event_type = rb_funcall( event_class, rb_intern("type_name"), 0 );
	rval = rb_class_new_instance( 0, NULL, event_class );

	// Set up the zyre_event memory for the object
	RTYPEDDATA_DATA( rval ) = ptr = (zyre_event_t *) zmalloc( sizeof *ptr );

	// Set the values that are required for every event type
	ptr->type = rzyre_copy_string( event_type );
	ptr->peer_uuid = rzyre_copy_string( peer_uuid );

	// Set the peer_name or default it if it wasn't specified
	if ( !RB_TYPE_P(kwvals[0], T_UNDEF) ) {
		ptr->peer_name = rzyre_copy_string( kwvals[0] );
	} else {
		ptr->peer_name = (char *) zmalloc( 2 + 6 + 1 );
		assert( ptr->peer_name );
		bzero( ptr->peer_name, 2 + 6 + 1 );
		strncpy( ptr->peer_name, "S-", 2 );
		memcpy( ptr->peer_name + 2, ptr->peer_uuid, 6 );
	}

	if ( streq(ptr->type, "ENTER") ) {
		ptr->peer_addr = rzyre_copy_required_string( kwvals[2], "peer_addr" );
		ptr->headers = rzyre_zhash_from_rhash( kwvals[1] );
	}
	else if ( streq(ptr->type, "JOIN") ) {
		ptr->group = rzyre_copy_required_string( kwvals[3], "group" );
	}
	else if ( streq(ptr->type, "LEAVE") ) {
		ptr->group = rzyre_copy_required_string( kwvals[3], "group" );
	}
	else if ( streq(ptr->type, "WHISPER") ) {
		const char *msg_str = rzyre_copy_required_string( kwvals[4], "msg" );
		zmsg_t *msg = zmsg_new();

		zmsg_addstr( msg, msg_str );
		ptr->msg = msg;
		msg = NULL;
	}
	else if ( streq(ptr->type, "SHOUT") ) {
		const char *msg_str = rzyre_copy_required_string( kwvals[4], "msg" );
		zmsg_t *msg = zmsg_new();

		zmsg_addstr( msg, msg_str );

		ptr->group = rzyre_copy_required_string( kwvals[3], "group" );
		ptr->msg = msg;
		msg = NULL;
	}
	else if ( streq(ptr->type, "LEADER") ) {
		ptr->group = rzyre_copy_required_string( kwvals[3], "group" );
	}

	return rval;
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
		val = (const char *)zhash_first( headers );
		while( val ) {
			key = zhash_cursor( headers );
			rb_hash_aset( rhash, rb_str_new2(key), rb_str_new2(val) );
			val = (const char *)zhash_next( headers );
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

	rb_define_singleton_method( rzyre_cZyreEvent, "from_node", rzyre_event_s_from_node, 1 );
	rb_define_singleton_method( rzyre_cZyreEvent, "synthesize", rzyre_event_s_synthesize, -1 );

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

