/*
 *  zyre_ext.c - Ruby binding for Zyre
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 *  Refs:
 *  - https://github.com/zeromq/zyre#api-summary
 *  - http://api.zeromq.org/master:zmq-z85-decode
 *  - http://api.zeromq.org/master:zmq-z85-encode
 *
 *
 */

#include "zyre_ext.h"

VALUE rzyre_mZyre;

static zactor_t *auth;


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
	VALUE msg_part, msg_str;
	zframe_t *frame;

	for ( long i = 0 ; i < RARRAY_LEN(call_ptr->msg_parts) ; i++ ) {
		msg_part = rb_ary_entry(call_ptr->msg_parts, i);
		msg_str = StringValue( msg_part );
		frame = zframe_new( RSTRING_PTR(msg_str), RSTRING_LEN(msg_str) );
		zmsg_append( call_ptr->msg, &frame );
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
rzyre_s_zyre_version( VALUE _mod )
{
	static uint64_t version;

	version = zyre_version();

	return LONG2NUM( version );
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
rzyre_s_interfaces( VALUE module )
{

	ziflist_t *iflist = ziflist_new();
	ziflist_reload( iflist );

	const VALUE rval = rb_hash_new();
	const char *iface = ziflist_first( iflist );

	while ( iface ) {
		const char *address_s = ziflist_address( iflist );
		const char *broadcast_s = ziflist_broadcast( iflist );
		const char *netmask_s = ziflist_netmask( iflist );
		const VALUE info_hash = rb_hash_new();

		rzyre_log( "debug", "Getting info for %s", address_s );
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
 * call-seq:
 *    Zyre.disable_zsys_handler
 *
 * Disable CZMQ's default signal handler, which allows for handling it in Ruby instead.
 *
 */
static VALUE
rzyre_s_disable_zsys_handler( VALUE module )
{
	rzyre_log( "info", "Disabling zsys INT/TERM handler." );
	zsys_handler_set( NULL );
	return Qtrue;
}


/*
 * call-seq:
 *    Zyre.z85_encode( data )   -> string
 *
 * Return the specified binary +data+ as a Z85-encoded binary string. The size of the data must
 * be divisible by 4. If there is a problem encoding the data, returns +nil+.
 *
 */
static VALUE
rzyre_s_z85_encode( VALUE module, VALUE data )
{
#if HAVE_ZMQ_Z85_ENCODE
	const char *data_str = StringValuePtr( data );
	const long len = RSTRING_LEN( data );
	const long res_len = (len * 1.25) + 1;
	char *encoded = NULL;
	VALUE result = Qnil;

	if ( len % 4 ) return Qnil;

	encoded = RB_ZALLOC_N( char, res_len );
	zmq_z85_encode( encoded, (unsigned char *)data_str, len );

	if ( encoded != NULL ) {
		result = rb_usascii_str_new( encoded, res_len - 1 );
	}

	ruby_xfree( encoded );

	return result;
#else
	rb_notimplement();
#endif
}


/*
 * call-seq:
 *    Zyre.z85_decode( string )   -> data
 *
 * Return the data decoded from the specified Z85-encoded binary +string+. If there is a
 * problem decoding the string, returns +nil+.
 *
 */
static VALUE
rzyre_s_z85_decode( VALUE module, VALUE string )
{
#if HAVE_ZMQ_Z85_DECODE
	const char *data_str = StringValueCStr( string );
	const long len = RSTRING_LEN( string );
	const long res_len = (len * 0.8) + 1;
	char *decoded = NULL;
	VALUE result = Qnil;

	if ( len % 5 ) return Qnil;

	decoded = RB_ZALLOC_N( char, res_len );
	zmq_z85_decode( (unsigned char *)decoded, data_str );

	if ( decoded != NULL ) {
		result = rb_str_new( decoded, res_len - 1 );
	}

	ruby_xfree( decoded );

	return result;
#else
	rb_notimplement();
#endif
}



/*
 * call-seq:
 *    Zyre.start_authenticator   -> true
 *
 * Start the ZAUTH authenticator actor. If it's already running, this
 * call is silently ignored.
 *
 */
static VALUE
rzyre_s_start_authenticator( VALUE module )
{
	if ( !auth ) {
		rzyre_log_obj( rzyre_mZyre, "info", "starting up the ZAUTH actor." );
		auth = zactor_new( zauth, NULL );
		assert( auth );
	}

	return Qtrue;
}


/*
 * call-seq:
 *    Zyre.authenticator_started?   -> true or false
 *
 * Returns `true` if the ZAUTH authenticator actor is running.
 *
 */
static VALUE
rzyre_s_authenticator_started_p( VALUE module )
{
	if ( auth ) {
		return Qtrue;
	} else {
		return Qfalse;
	}
}


/*
 * call-seq:
 *    Zyre.stop_authenticator   -> true
 *
 * Stop the ZAUTH authenticator actor if it is running. If it's not running, this
 * call is silently ignored.
 *
 */
static VALUE
rzyre_s_stop_authenticator( VALUE module )
{
	if ( auth ) {
		rzyre_log_obj( rzyre_mZyre, "info", "shutting down the ZAUTH actor." );
		zactor_destroy( &auth );
	}

	return Qtrue;
}


/*
 * Async wait function; called without the GVL.
 */
static void *
rzyre_wait_for_auth_without_gvl( void *_unused )
{
	zsock_wait( auth );
	return NULL;
}


/*
 * call-seq:
 *    Zyre.verbose_auth!
 *
 * Enable the ZAUTH actor's verbose logging.
 *
 */
static VALUE
rzyre_s_verbose_auth_bang( VALUE module )
{
	if ( auth ) {
		zstr_sendx( auth, "VERBOSE", NULL );
		rb_thread_call_without_gvl2( rzyre_wait_for_auth_without_gvl, 0, RUBY_UBF_IO, 0 );
	} else {
		rb_raise( rb_eRuntimeError, "can't enable verbose auth: authenticator is not started." );
	}

	return Qtrue;
}


/*
 * call-seq:
 *    Zyre.enable_curve_auth( cert_dir=nil )
 *
 * Enable CURVE authentication, using the specified +cert_dir+ for allowed
 * public certificates. If no +cert_dir+ is given, any connection presenting a valid CURVE
 * certificate will be allowed.
 *
 */
static VALUE
rzyre_s_enable_curve_auth( int argc, VALUE *argv, VALUE module )
{
	VALUE cert_dir = Qnil;
	char *cert_dir_s;

	rb_scan_args( argc, argv, "01", &cert_dir );

	if ( argc ) {
		cert_dir_s = StringValueCStr( cert_dir );
		zstr_sendx( auth, "CURVE", cert_dir_s, NULL );
	} else {
		zstr_sendx( auth, "CURVE", CURVE_ALLOW_ANY, NULL );
	}

	rb_thread_call_without_gvl2( rzyre_wait_for_auth_without_gvl, 0, RUBY_UBF_IO, 0 );

	return Qtrue;
}


/*
 * call-seq:
 *    Zyre.interface   -> string
 *
 * Return network interface to use for broadcasts, or nil if none was set.
 *
 */
static VALUE
rzyre_s_interface( VALUE module )
{
	const char *interface = zsys_interface();

	if ( strnlen(interface, 1) == 0 ) {
		return Qnil;
	}

	return rb_utf8_str_new_cstr( interface );
}


/*
 * call-seq:
 *    Zyre.interface = string
 *
 * Set network interface name to use for broadcasts.
 *
 * This lets the interface be configured for test environments where required.
 * For example, on Mac OS X, zbeacon cannot bind to 255.255.255.255 which is
 * the default when there is no specified interface. If the environment
 * variable ZSYS_INTERFACE is set, use that as the default interface name.
 * Setting the interface to "*" means "use all available interfaces".
 *
 */
static VALUE
rzyre_s_interface_eq( VALUE module, VALUE new_interface )
{
	if ( NIL_P(new_interface) ) {
		zsys_set_interface( "" );
	} else {
		const char *new_interface_s = StringValueCStr( new_interface );
		zsys_set_interface( new_interface_s );
	}

	return Qtrue;
}


/*
 * Zyre extension init function
 */
void
Init_zyre_ext()
{
	/*
	 * Document-module: Zyre
	 *
	 * The top level namespace for Zyre classes.
	 */
	rzyre_mZyre = rb_define_module( "Zyre" );

#ifdef CZMQ_BUILD_DRAFT_API
	rb_define_const( rzyre_mZyre, "BUILT_WITH_DRAFT_CZMQ_API", Qtrue );
#else
	rb_define_const( rzyre_mZyre, "BUILT_WITH_DRAFT_CZMQ_API", Qfalse );
#endif
#ifdef ZYRE_BUILD_DRAFT_API
	rb_define_const( rzyre_mZyre, "BUILT_WITH_DRAFT_API", Qtrue );
#else
	rb_define_const( rzyre_mZyre, "BUILT_WITH_DRAFT_API", Qfalse );
#endif

	rb_define_singleton_method( rzyre_mZyre, "zyre_version", rzyre_s_zyre_version, 0 );
	rb_define_singleton_method( rzyre_mZyre, "interfaces", rzyre_s_interfaces, 0 );
	rb_define_singleton_method( rzyre_mZyre, "disable_zsys_handler",
		rzyre_s_disable_zsys_handler, 0 );

	rb_define_singleton_method( rzyre_mZyre, "z85_encode", rzyre_s_z85_encode, 1 );
	rb_define_singleton_method( rzyre_mZyre, "z85_decode", rzyre_s_z85_decode, 1 );

	rb_define_singleton_method( rzyre_mZyre, "start_authenticator",
		rzyre_s_start_authenticator, 0 );
	rb_define_singleton_method( rzyre_mZyre, "authenticator_started?",
		rzyre_s_authenticator_started_p, 0 );
	rb_define_singleton_method( rzyre_mZyre, "stop_authenticator", rzyre_s_stop_authenticator, 0 );

	rb_define_singleton_method( rzyre_mZyre, "verbose_auth!", rzyre_s_verbose_auth_bang, 0 );
	rb_define_singleton_method( rzyre_mZyre, "enable_curve_auth", rzyre_s_enable_curve_auth, -1 );

	rb_define_singleton_method( rzyre_mZyre, "interface", rzyre_s_interface, 0 );
	rb_define_singleton_method( rzyre_mZyre, "interface=", rzyre_s_interface_eq, 1 );

	// :TODO: set up zsys_set_logsender()

	rzyre_init_node();
	rzyre_init_event();
	rzyre_init_poller();
	rzyre_init_cert();
	rzyre_init_certstore();
}

