/*
 *  zyre_ext.c - Ruby binding for Zyre
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "zyre_ext.h"

VALUE rzyre_mZyre;


/* --------------------------------------------------------------
 * Logging Functions
 * -------------------------------------------------------------- */

/*
 * Log a message to the given +context+ object's logger.
 */
void
#ifdef HAVE_STDARG_PROTOTYPES
rzyre_log_obj( VALUE context, const char *level, const char *fmt, ... )
#else
rzyre_log_obj( VALUE context, const char *level, const char *fmt, va_dcl )
#endif
{
	char buf[BUFSIZ];
	va_list	args;
	VALUE logger = Qnil;
	VALUE message = Qnil;

	va_init_list( args, fmt );
	vsnprintf( buf, BUFSIZ, fmt, args );
	message = rb_str_new2( buf );

	logger = rb_funcall( context, rb_intern("log"), 0 );
	rb_funcall( logger, rb_intern(level), 1, message );

	va_end( args );
}


/*
 * Log a message to the global logger.
 */
void
#ifdef HAVE_STDARG_PROTOTYPES
rzyre_log( const char *level, const char *fmt, ... )
#else
rzyre_log( const char *level, const char *fmt, va_dcl )
#endif
{
	char buf[BUFSIZ];
	va_list	args;
	VALUE logger = Qnil;
	VALUE message = Qnil;

	va_init_list( args, fmt );
	vsnprintf( buf, BUFSIZ, fmt, args );
	message = rb_str_new2( buf );

	logger = rb_funcall( rzyre_mZyre, rb_intern("logger"), 0 );
	rb_funcall( logger, rb_intern(level), 1, message );

	va_end( args );
}


/* --------------------------------------------------------------
 * Utility functions
 * -------------------------------------------------------------- */

// Struct for passing arguments through rb_protect to rzyre_add_frames_to_zmsg()
struct add_frames_to_zmsg_call {
	zmsg_t *msg;
	VALUE msg_parts;
};
typedef struct add_frames_to_zmsg_call add_frames_to_zmsg_call_t;


/*
 * Add a frame for each object in an Array.
 */
static VALUE
rzyre_add_frames_to_zmsg( VALUE call )
{
	add_frames_to_zmsg_call_t *call_ptr = (add_frames_to_zmsg_call_t *)call;
	VALUE msg_part;

	for ( long i = 0 ; i < RARRAY_LEN(call_ptr->msg_parts) ; i++ ) {
		msg_part = rb_ary_entry( call_ptr->msg_parts, i );
		zmsg_addstr( call_ptr->msg, StringValueCStr(msg_part) );
	}

	return Qtrue;
}


/*
 * Make and return a zmsg, with one frame per object in +messages+. Caller owns the returned
 * zmsg. Can raise a TypeError if one of the +messages+ can't be stringified.
 */
zmsg_t *
rzyre_make_zmsg_from( VALUE messages )
{
	VALUE msgarray = rb_Array( messages );
	zmsg_t *msg = zmsg_new();
	static add_frames_to_zmsg_call_t call;
	int state;

	call.msg = msg;
	call.msg_parts = msgarray;

	rb_protect( rzyre_add_frames_to_zmsg, (VALUE)&call, &state );

	if ( state ) {
		zmsg_destroy( &msg );
		rb_jump_tag( state );
	}

	return msg;
}





/* --------------------------------------------------------------
 * Module methods
 * -------------------------------------------------------------- */

/*
 * call-seq:
 *    Zyre.zyre_version   -> int
 *
 * Return the version of the underlying libzyre.
 *
 */
static VALUE
rzyre_s_zyre_version()
{
	static uint64_t version;

	version = zyre_version();

	return INT2NUM( version );
}


/*
 * call-seq:
 *    Zyre.interfaces   -> hash
 *
 * Return a Hash of broadcast-capable interfaces on the local host keyed by name. The
 * values contain other information about the interface:
 *
 *    {
 *      "<interface name>" => {
 *        address: "<interface address>",
 *        broadcast: "<interface broadcast address>",
 *        netmask: "<interface network mask>",
 *      }
 *    }
 */
static VALUE
rzyre_s_interfaces()
{
	ziflist_t *iflist = ziflist_new();
	const VALUE rval = rb_hash_new();
	const char *iface = ziflist_first( iflist );

	while ( iface ) {
		const char *address_s = ziflist_address( iflist );
		const char *broadcast_s = ziflist_broadcast( iflist );
		const char *netmask_s = ziflist_netmask( iflist );
		const VALUE info_hash = rb_hash_new();

		rb_hash_aset( info_hash, ID2SYM(rb_intern("address")), rb_usascii_str_new_cstr(address_s) );
		rb_hash_aset( info_hash, ID2SYM(rb_intern("broadcast")), rb_usascii_str_new_cstr(broadcast_s) );
		rb_hash_aset( info_hash, ID2SYM(rb_intern("netmask")), rb_usascii_str_new_cstr(netmask_s) );

		rb_hash_aset( rval, rb_usascii_str_new_cstr(iface), info_hash );

		iface = ziflist_next( iflist );
	}

	ziflist_destroy( &iflist );

	return rval;
}


/*
 * Zyre extension init function
 */
void
Init_zyre_ext()
{
	rzyre_mZyre = rb_define_module( "Zyre" );

	rb_define_singleton_method( rzyre_mZyre, "zyre_version", rzyre_s_zyre_version, 0 );
	rb_define_singleton_method( rzyre_mZyre, "interfaces", rzyre_s_interfaces, 0 );

	// :TODO: set up zsys_set_logsender()

	rzyre_init_node();
	rzyre_init_event();
	rzyre_init_poller();
}

