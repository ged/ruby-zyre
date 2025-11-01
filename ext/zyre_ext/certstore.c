/*
 *  certstore.c - A curve certificate store for use with Zyre.
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "zyre_ext.h"

VALUE rzyre_cZyreCertstore;

// Forward declarations
static void rzyre_certstore_free( void *ptr );


static const rb_data_type_t rzyre_certstore_t = {
	.wrap_struct_name = "Zyre::Certstore",
	.function = {
		.dmark = NULL,
		.dfree = rzyre_certstore_free,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY,
};


/*
 * Free function
 */
static void
rzyre_certstore_free( void *ptr )
{
	if ( ptr ) {
		zcertstore_destroy( (zcertstore_t **)&ptr );
	}
}


/*
 * Alloc function
 */
static VALUE
rzyre_certstore_alloc( VALUE klass )
{
	return TypedData_Wrap_Struct( klass, &rzyre_certstore_t, NULL );
}


/*
 * Fetch the data pointer and check it for sanity.
 */
inline zcertstore_t *
rzyre_get_certstore( VALUE self )
{
	zcertstore_t *ptr;

	if ( !IsZyreCertstore(self) ) {
		rb_raise( rb_eTypeError, "wrong argument type %s (expected Zyre::Certstore)",
			rb_class2name(CLASS_OF( self )) );
	}

	ptr = DATA_PTR( self );
	assert( ptr );

	return ptr;
}



/*
 * call-seq:
 *    Zyre::Certstore.new                -> certstore
 *    Zyre::Certstore.new( directory )   -> certstore
 *
 * Create a new certificate store. If not +directory+ is given, creates an 
 * in-memory store.
 *
 */
static VALUE
rzyre_certstore_initialize( int argc, VALUE *argv, VALUE self )
{
	VALUE directory = Qnil;
	zcertstore_t *ptr;

	TypedData_Get_Struct( self, zcertstore_t, &rzyre_certstore_t, ptr );
	if ( !ptr ) {
		rb_scan_args( argc, argv, "01", &directory );

		if ( RTEST(directory) ) {
			VALUE dir_string = rb_funcall( directory, rb_intern("to_s"), 0 );
			const char *location = StringValueCStr( dir_string );
			ptr = zcertstore_new( location );
		} else {
			ptr = zcertstore_new( NULL );
		}

		assert( ptr );
		RTYPEDDATA_DATA( self ) = ptr;
	}

	return self;
}



/*
 * call-seq:
 *    certstore.lookup( public_key )
 *
 * Look up certificate by public key, returns Zyre::Cert object if found,
 * else returns `nil`. The +public_key+ should be a String in Z85 text format.
 *
 */
static VALUE
rzyre_certstore_lookup( VALUE self, VALUE public_key )
{
	zcertstore_t *ptr = rzyre_get_certstore( self );
	const char *key_txt = StringValueCStr( public_key );
	zcert_t *cert = zcertstore_lookup( ptr, key_txt );

	if ( cert ) {
		VALUE zyre_cert = rzyre_wrap_cert( cert );
		return zyre_cert;
	}

	return Qnil;
}



/*
 * call-seq:
 *    certstore.insert( certificate )
 *
 * Insert +certificate+ (a Zyre::Cert) into certificate store in memory. Note 
 * that this does not save the certificate to disk. To do that, use Zyre::Cert#save
 * directly on the certificate.
 *
 */
static VALUE
rzyre_certstore_insert( VALUE self, VALUE cert )
{
	zcertstore_t *ptr = rzyre_get_certstore( self );
	zcert_t *zcert = rzyre_get_cert( cert );
	zcert_t *zcert_owned = zcert_dup( zcert );

	assert( zcert_owned );
	zcertstore_insert( ptr, &zcert_owned );

	return Qtrue;
}


/*
 * call-seq:
 *    certstore.print
 *
 * Print list of certificates in store to logging facility.
 *
 */
static VALUE
rzyre_certstore_print( VALUE self )
{
	zcertstore_t *ptr = rzyre_get_certstore( self );

	zcertstore_print( ptr );

	return Qtrue;
}



/*
 * Initialize the Cert class.
 */
void
rzyre_init_certstore( void ) {

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rzyre_mZyre = rb_define_module( "Zyre" );
#endif

	/*
	 * Document-class: Zyre::Certstore
	 *
	 * A certificate store for Zyre curve authentication.
	 *
	 * Refs:
	 * - http://api.zeromq.org/czmq4-0:zcertstore
	 *
	 */
	rzyre_cZyreCertstore = rb_define_class_under( rzyre_mZyre, "Certstore", rb_cObject );

	rb_define_alloc_func( rzyre_cZyreCertstore, rzyre_certstore_alloc );

	rb_define_protected_method( rzyre_cZyreCertstore, "initialize", rzyre_certstore_initialize, -1 );

	rb_define_method( rzyre_cZyreCertstore, "lookup", rzyre_certstore_lookup, 1 );
	rb_define_method( rzyre_cZyreCertstore, "insert", rzyre_certstore_insert, 1 );

	rb_define_method( rzyre_cZyreCertstore, "print", rzyre_certstore_print, 0 );

	rb_require( "zyre/certstore" );
}

