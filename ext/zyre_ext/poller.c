/*
 *  poller.c - A poller for doing evented IO on one or more Zyre nodes
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "zyre_ext.h"

VALUE rzyre_cZyrePoller;


static void rzyre_poller_free( void *ptr );

static const rb_data_type_t rzyre_poller_t = {
	"Zyre::Poller",
	{
		NULL,
		rzyre_poller_free
	},
	0,
	0,
	RUBY_TYPED_FREE_IMMEDIATELY,
};


/*
 * Free function
 */
static void
rzyre_poller_free( void *ptr )
{
	zpoller_destroy( (zpoller_t **)&ptr );
}


/*
 * Alloc function
 */
static VALUE
rzyre_poller_alloc( VALUE klass )
{
	return TypedData_Wrap_Struct( klass, &rzyre_poller_t, NULL );
}


/*
 * Fetch the data pointer and check it for sanity.
 */
static inline zpoller_t *
rzyre_get_poller( VALUE self )
{
	zpoller_t *ptr;

	if ( !IsZyrePoller(self) ) {
		rb_raise( rb_eTypeError, "wrong argument type %s (expected Zyre::Poller)",
			rb_class2name(CLASS_OF( self )) );
	}

	ptr = DATA_PTR( self );
	assert( ptr );

	return ptr;
}


/*
 * call-seq:
 *    Zyre::Poller.new( *nodes )   -> poller
 *
 * Create a poller that will wait for input on any of the given +nodes+.
 *
 */
static VALUE
rzyre_poller_initialize( VALUE self, VALUE nodes )
{
	zpoller_t *ptr;

	TypedData_Get_Struct( self, zpoller_t, &rzyre_poller_t, ptr );
	if ( !ptr ) {
		RTYPEDDATA_DATA( self ) = ptr = zpoller_new( NULL );
		assert( ptr );

		rb_ivar_set( self, rb_intern("@nodes"), rb_hash_new() );
	}

	rb_funcall( self, rb_intern("add"), 1, nodes );

	return self;
}


/*
 * call-seq:
 *    poller.add( *nodes )
 *
 * Add the specified +nodes+ to the list which will be polled by a call to #wait.
 *
 */
static VALUE
rzyre_poller_add( VALUE self, VALUE nodes )
{
	zpoller_t *ptr = rzyre_get_poller( self );
	VALUE nodemap = rb_ivar_get( self, rb_intern("@nodes") );
	long i;

	// For each node given, record its endpoint in @nodes so we can map it back to
	// the node later and add it to the poller.
	nodes = rb_funcall( nodes, rb_intern("flatten"), 0 );
	for ( i=0; i < RARRAY_LEN(nodes); i++ ) {
		VALUE node = RARRAY_AREF( nodes, i );
		zyre_t *zyre_node = rzyre_get_node( node );
		zsock_t *sock = zyre_socket( zyre_node );
		const char *endpoint_str = zsock_endpoint( sock );

		assert( endpoint_str );

		rb_hash_aset( nodemap, rb_str_new2(endpoint_str), node );
		zpoller_add( ptr, sock );
	}

	return Qtrue;
}


/*
 * call-seq:
 *    poller.nodes   -> hash
 *
 * Return a (frozen copy) of the Hash of the nodes the Poller will wait on.
 *
 */
static VALUE
rzyre_poller_nodes( VALUE self )
{
	VALUE rval = rb_obj_dup( rb_ivar_get(self, rb_intern( "@nodes" )) );

	return rb_hash_freeze( rval );
}


/*
 * call-seq:
 *    poller.remove( *nodes )
 *
 * Add the specified +nodes+ to the list which will be polled by a call to #wait.
 *
 */
static VALUE
rzyre_poller_remove( VALUE self, VALUE nodes )
{
	zpoller_t *ptr = rzyre_get_poller( self );
	VALUE nodemap = rb_ivar_get( self, rb_intern("@nodes") );
	long i;

	// For each node given, record its endpoint in @nodes so we can map it back to
	// the node later and remove it to the poller.
	nodes = rb_funcall( nodes, rb_intern("flatten"), 0 );
	for ( i=0; i < RARRAY_LEN(nodes); i++ ) {
		VALUE node = RARRAY_AREF( nodes, i );
		zyre_t *zyre_node = rzyre_get_node( node );
		zsock_t *sock = zyre_socket( zyre_node );
		const char *endpoint_str = zsock_endpoint( sock );

		assert( endpoint_str );

		rb_hash_aset( nodemap, rb_str_new2(endpoint_str), node );
		zpoller_remove( ptr, sock );
	}

	return Qtrue;
}


typedef struct {
	zpoller_t *poller;
	int timeout;
} wait_call_t;

/*
 * Async wait function; called without the GVL.
 */
static void *
rzyre_poller_wait_without_gvl( void *wait_call )
{
	wait_call_t *call = (wait_call_t *)wait_call;
	return zpoller_wait( call->poller, call->timeout );
}


/*
 * call-seq:
 *    poller.wait( timeout=-1 )   -> node or nil
 *
 * Poll the registered nodes for I/O, return first one that has input. The
 * timeout should be zero or greater, or -1 to wait indefinitely. Socket
 * priority is defined by their order in the poll list. If the timeout expired,
 * returns nil. If poll call is interrupted (SIGINT) or the ZMQ context was
 * destroyed, an Interrupt is raised.
 *    
 */
static VALUE
rzyre_poller_wait( int argc, VALUE *argv, VALUE self )
{
	zpoller_t *ptr = rzyre_get_poller( self );
	VALUE rval = Qnil;
	zsock_t *sock;
	VALUE timeout_arg;
	int timeout = -1;
	wait_call_t call;

	if ( rb_scan_args(argc, argv, "01", &timeout_arg) ) {
		timeout = floor( NUM2DBL(timeout_arg) * 1000 );
	}

	call.poller = ptr;
	call.timeout = timeout;
	sock = (zsock_t *)rb_thread_call_without_gvl2( rzyre_poller_wait_without_gvl, (void *)&call,
		RUBY_UBF_IO, 0 );

	if ( sock ) {
		VALUE nodemap = rb_ivar_get( self, rb_intern("@nodes") );
		const char *endpoint = zsock_endpoint( sock );
		rval = rb_hash_aref( nodemap, rb_str_new2(endpoint) );
	}

	return rval;
}



/*
 * Initialize the Poller class.
 */
void
rzyre_init_poller( void ) {

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rzyre_mZyre = rb_define_module( "Zyre" );
#endif

	rzyre_cZyrePoller = rb_define_class_under( rzyre_mZyre, "Poller", rb_cObject );

	rb_define_alloc_func( rzyre_cZyrePoller, rzyre_poller_alloc );

	rb_define_protected_method( rzyre_cZyrePoller, "initialize", rzyre_poller_initialize, -2 );

	rb_define_method( rzyre_cZyrePoller, "add", rzyre_poller_add, -2 );
	rb_define_method( rzyre_cZyrePoller, "nodes", rzyre_poller_nodes, 0 );
	rb_define_method( rzyre_cZyrePoller, "remove", rzyre_poller_remove, 1 );
	rb_define_method( rzyre_cZyrePoller, "wait", rzyre_poller_wait, -1 );

	rb_require( "zyre/poller" );
}

