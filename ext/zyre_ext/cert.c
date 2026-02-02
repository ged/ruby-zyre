/*
 *  cert.c - A curve certificate for use with Zyre.
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#include "zyre_ext.h"

VALUE rzyre_cZyreCert;

// Forward declarations
static void rzyre_cert_free( void *ptr );


static const byte EMPTY_KEY[32] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
static const char *Z85_EMPTY_KEY = "0000000000000000000000000000000000000000";


static const rb_data_type_t rzyre_cert_t = {
	.wrap_struct_name = "Zyre::Cert",
	.function = {
		.dmark = NULL,
		.dfree = rzyre_cert_free,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY,
};


/*
 * Free function
 */
static void
rzyre_cert_free( void *ptr )
{
	if ( ptr ) {
		zcert_destroy( (zcert_t **)&ptr );
	}
}


/*
 * Alloc function
 */
static VALUE
rzyre_cert_alloc( VALUE klass )
{
	return TypedData_Wrap_Struct( klass, &rzyre_cert_t, NULL );
}


/*
 * Fetch the data pointer and check it for sanity.
 */
inline zcert_t *
rzyre_get_cert( VALUE self )
{
	zcert_t *ptr;

	if ( !IsZyreCert(self) ) {
		rb_raise( rb_eTypeError, "wrong argument type %s (expected Zyre::Cert)",
			rb_class2name(CLASS_OF( self )) );
	}

	ptr = DATA_PTR( self );
	assert( ptr );

	return ptr;
}



/*
 * Wrap a zcert_t in a Zyre::Cert object.
 */
VALUE
rzyre_wrap_cert( zcert_t *ptr )
{
	VALUE wrapper = rzyre_cert_alloc( rzyre_cZyreCert );
	zcert_t *copy = zcert_dup( ptr );

	RTYPEDDATA_DATA( wrapper ) = copy;

	return wrapper;
}




/*
 * call-seq:
 *   Zyre::Cert.from( public_key, secret_key )    -> cert
 *
 * Create a certificate from the +public_key+ and +secret_key+.
 *
 */
static VALUE
rzyre_cert_s_from( VALUE class, VALUE public_key, VALUE secret_key )
{
	VALUE self = rzyre_cert_alloc( class );
	zcert_t *ptr = NULL;
	const char *pub_str = StringValuePtr( public_key ),
		*sec_str = StringValuePtr( secret_key );

	if ( RSTRING_LEN(public_key) == 32 && RSTRING_LEN(secret_key) == 32 ) {
		ptr = zcert_new_from( (const byte *)pub_str, (const byte *)sec_str );
	} else if ( RSTRING_LEN(public_key) == 40 && RSTRING_LEN(secret_key) == 40 ) {
#ifdef CZMQ_BUILD_DRAFT_API
		ptr = zcert_new_from_txt( pub_str, sec_str );
#else
		rb_raise( rb_eNotImpError,
			"can't create a key from encoded keys: Czmq was not built with Draft APIs!" );
#endif
	}

	if ( !ptr ) {
		rb_raise( rb_eArgError, "invalid key pair" );
	}

	RTYPEDDATA_DATA( self ) = ptr;

	return self;
}



/*
 * call-seq:
 *   Zyre::Cert.from_public( public_key )    -> cert
 *
 * Create a public certificate from a +public_key+ string.
 *
 */
static VALUE
rzyre_cert_s_from_public( VALUE class, VALUE public_key )
{
	VALUE self = rzyre_cert_alloc( class );
	zcert_t *ptr = NULL;
	const char *pub_str = StringValuePtr( public_key );

	if ( RSTRING_LEN(public_key) == 32 ) {
		ptr = zcert_new_from( (const byte *)pub_str, EMPTY_KEY );
	} else if ( RSTRING_LEN(public_key) == 40 ) {
#ifdef HAVE_ZCERT_NEW_FROM_TXT
		ptr = zcert_new_from_txt( pub_str, Z85_EMPTY_KEY );
#else
		rb_raise( rb_eNotImpError,
			"can't create a key from encoded keys: Czmq is too old!" );
#endif
	}

	if ( !ptr ) {
		rb_raise( rb_eArgError, "invalid key" );
	}

	RTYPEDDATA_DATA( self ) = ptr;

	return self;
}


/*
 * call-seq:
 *   Zyre::Cert.load( filename )    -> cert
 *
 * Create a certificate from a saved certificate in the specified
 * +filename+.
 *
 */
static VALUE
rzyre_cert_s_load( VALUE class, VALUE filename )
{
	VALUE self = rzyre_cert_alloc( class );
	zcert_t *ptr = zcert_load( StringValueCStr(filename) );

	if ( !ptr ) {
		rb_raise( rb_eArgError, "failed to load cert from %s", RSTRING_PTR(filename) );
	}

	RTYPEDDATA_DATA( self ) = ptr;

	return self;
}


/*
 * call-seq:
 *    Zyre::Cert.new   -> cert
 *
 * Create a new certificate.
 *
 */
static VALUE
rzyre_cert_initialize( VALUE self )
{
	zcert_t *ptr;

	TypedData_Get_Struct( self, zcert_t, &rzyre_cert_t, ptr );
	if ( !ptr ) {
		RTYPEDDATA_DATA( self ) = ptr = zcert_new();
		assert( ptr );
	}

	return self;
}


/*
 * call-seq:
 *    cert.public_key   -> key_data
 *
 * Return public part of key pair as 32-byte binary string
 *
 */
static VALUE
rzyre_cert_public_key( VALUE self )
{
	zcert_t *ptr = rzyre_get_cert( self );
	const byte *key = zcert_public_key( ptr );
	VALUE rval = rb_enc_str_new( (const char *)key, 32, rb_ascii8bit_encoding() );

	return rval;
}


/*
 * call-seq:
 *    cert.secret_key   -> key_data
 *
 * Return secret part of key pair as 32-byte binary string
 *
 */
static VALUE
rzyre_cert_secret_key( VALUE self )
{
	zcert_t *ptr = rzyre_get_cert( self );
	const byte *key = zcert_secret_key( ptr );
	VALUE rval = rb_enc_str_new( (const char *)key, 32, rb_ascii8bit_encoding() );

	return rval;
}


/*
 * call-seq:
 *    cert.public_txt   -> key_text
 *
 * Return public part of key pair as Z85 armored string
 *
 */
static VALUE
rzyre_cert_public_txt( VALUE self )
{
	zcert_t *ptr = rzyre_get_cert( self );
	const char *key = zcert_public_txt( ptr );
	VALUE rval = rb_usascii_str_new( key, 40 );

	return rval;
}


/*
 * call-seq:
 *    cert.secret_txt   -> key_text
 *
 * Return secret part of key pair as Z85 armored string
 *
 */
static VALUE
rzyre_cert_secret_txt( VALUE self )
{
	zcert_t *ptr = rzyre_get_cert( self );
	const char *key = zcert_secret_txt( ptr );
	VALUE rval = rb_usascii_str_new( key, 40 );

	return rval;
}


/*
 * call-seq:
 *    cert.set_meta( name, value )
 *
 * Set certificate metadata +name+ to +value+.
 *
 */
static VALUE
rzyre_cert_set_meta( VALUE self, VALUE name, VALUE val )
{
	zcert_t *ptr = rzyre_get_cert( self );
	const char *key_str = StringValueCStr( name ),
		*val_str = StringValueCStr( val );

#ifdef CZMQ_BUILD_DRAFT_API
	zcert_unset_meta( ptr, key_str );
#endif

	zcert_set_meta( ptr, key_str, "%s", val_str );

	return val;
}


/*
 * call-seq:
 *    cert.meta( name )   -> string
 *
 * Return the metadata value for +name+ from certificate; if the metadata
 * value doesn't exist, returns +nil+.
 *
 */
static VALUE
rzyre_cert_meta( VALUE self, VALUE name )
{
	zcert_t *ptr = rzyre_get_cert( self );
	VALUE rval = Qnil;
	const char *name_str = StringValuePtr( name );
	const char *value = zcert_meta( ptr, name_str );

	if ( value ) rval = rb_utf8_str_new_cstr( value );

	return rval;
}


/*
 * call-seq:
 *    cert.keys   -> array
 *
 * Return an Array of metadata field names that belong to the receiver.
 *
 */
static VALUE
rzyre_cert_meta_keys( VALUE self )
{
	zcert_t *ptr = rzyre_get_cert( self );
	zlist_t *keys = zcert_meta_keys( ptr );
	VALUE rary = rb_ary_new();
	char *item;

	assert( keys );

	item = zlist_first( keys );
	while ( item ) {
		rb_ary_push( rary, rb_str_new_cstr(item) );
		item = zlist_next( keys );
	}

	zlist_destroy( &keys );

	return rary;
}


/*
 * call-seq:
 *    cert.unset_meta( name )
 *
 * Unset certificate metadata value for the given +name.
 *
 * Note: this is a draft method for development use, may change without warning.
 *
 */
static VALUE
rzyre_cert_unset_meta( VALUE self, VALUE name )
{
#ifdef CZMQ_BUILD_DRAFT_API
	zcert_t *ptr = rzyre_get_cert( self );
	const char *name_str = StringValueCStr( name );

	zcert_unset_meta( ptr, name_str );

	return Qtrue;
#else
	rb_raise( rb_eNotImpError, "Czmq was not built with Draft APIs!" );
#endif // CZMQ_BUILD_DRAFT_API
}


/*
 * call-seq:
 *    cert.save( filename )
 *
 * Save the full certificate (public + secret) to the specified +filename+.
 * This creates one public file and one secret file (filename + "_secret").
 *
 */
static VALUE
rzyre_cert_save( VALUE self, VALUE filename )
{
	zcert_t *ptr = rzyre_get_cert( self );
	const char *filename_str = StringValueCStr( filename );
	int result;

	result = zcert_save( ptr, filename_str );

	if ( result != 0 )
		rb_raise( rb_eRuntimeError, "failed to save cert to %s", filename_str );

	return Qtrue;
}


/*
 * call-seq:
 *    cert.save_public( filename )
 *
 * Save the public certificate only to the specified +filename+.
 *
 */
static VALUE
rzyre_cert_save_public( VALUE self, VALUE filename )
{
	zcert_t *ptr = rzyre_get_cert( self );
	VALUE filename_s = rb_funcall( filename, rb_intern("to_s"), 0 );
	const char *filename_str = StringValueCStr( filename_s );
	int result;

	result = zcert_save_public( ptr, filename_str );

	if ( result != 0 )
		rb_raise( rb_eRuntimeError, "failed to save public cert to %s", filename_str );

	return Qtrue;
}


/*
 * call-seq:
 *    cert.save_secret( filename )
 *
 * Save the secret certificate only to the specified +filename+.
 *
 */
static VALUE
rzyre_cert_save_secret( VALUE self, VALUE filename )
{
	zcert_t *ptr = rzyre_get_cert( self );
	const char *filename_str = StringValueCStr( filename );
	int result;

	result = zcert_save_secret( ptr, filename_str );

	if ( result != 0 )
		rb_raise( rb_eRuntimeError, "failed to save secret cert to %s", filename_str );

	return Qtrue;
}


/*
 * call-seq:
 *    cert.dup   -> cert
 *
 * Return a copy of the certificate.
 *
 */
static VALUE
rzyre_cert_dup( VALUE self )
{
	zcert_t *ptr = rzyre_get_cert( self );
	zcert_t *other_ptr;
	VALUE other = rb_call_super( 0, NULL );

	RTYPEDDATA_DATA( other ) = other_ptr = zcert_dup( ptr );

	if ( !other_ptr )
		rb_raise( rb_eRuntimeError, "couldn't duplicate the cert" );

	return other;
}


/*
 * call-seq:
 *    cert.eql?( other_cert )   -> true or false
 *
 * Return true if the +other_cert+ has the same keys.
 *
 */
static VALUE
rzyre_cert_eql_p( VALUE self, VALUE other )
{
	zcert_t *ptr = rzyre_get_cert( self ),
		*other_ptr = rzyre_get_cert( other );
	bool equal = zcert_eq( ptr, other_ptr );

	return equal ? Qtrue : Qfalse;
}


/*
 * call-seq:
 *    cert.print
 *
 * Print certificate contents to stdout.
 *
 */
static VALUE
rzyre_cert_print( VALUE self )
{
	zcert_t *ptr = rzyre_get_cert( self );

	zcert_print( ptr );

	return Qtrue;
}



/*
 * Initialize the Cert class.
 */
void
rzyre_init_cert( void ) {

#ifdef FOR_RDOC
	rb_cData = rb_define_class( "Data" );
	rzyre_mZyre = rb_define_module( "Zyre" );
#endif

	/*
	 * Document-class: Zyre::Cert
	 *
	 * A certificate for Zyre curve authentication.
	 *
	 * Refs:
	 * - http://api.zeromq.org/czmq4-0:zcert
	 *
	 */
	rzyre_cZyreCert = rb_define_class_under( rzyre_mZyre, "Cert", rb_cObject );

	rb_define_alloc_func( rzyre_cZyreCert, rzyre_cert_alloc );

	rb_define_singleton_method( rzyre_cZyreCert, "from", rzyre_cert_s_from, 2 );
	rb_define_singleton_method( rzyre_cZyreCert, "from_public", rzyre_cert_s_from_public, 1 );
	rb_define_singleton_method( rzyre_cZyreCert, "load", rzyre_cert_s_load, 1 );

	rb_define_protected_method( rzyre_cZyreCert, "initialize", rzyre_cert_initialize, 0 );

	rb_define_method( rzyre_cZyreCert, "public_key", rzyre_cert_public_key, 0 );
	rb_define_method( rzyre_cZyreCert, "secret_key", rzyre_cert_secret_key, 0 );
	rb_define_method( rzyre_cZyreCert, "public_txt", rzyre_cert_public_txt, 0 );
	rb_define_method( rzyre_cZyreCert, "secret_txt", rzyre_cert_secret_txt, 0 );

	rb_define_method( rzyre_cZyreCert, "set_meta", rzyre_cert_set_meta, 2 );
	rb_define_method( rzyre_cZyreCert, "meta", rzyre_cert_meta, 1 );
	rb_define_method( rzyre_cZyreCert, "meta_keys", rzyre_cert_meta_keys, 0 );
	rb_define_method( rzyre_cZyreCert, "unset_meta", rzyre_cert_unset_meta, 1 ); // DRAFT

	rb_define_method( rzyre_cZyreCert, "save", rzyre_cert_save, 1 );
	rb_define_method( rzyre_cZyreCert, "save_public", rzyre_cert_save_public, 1 );
	rb_define_method( rzyre_cZyreCert, "save_secret", rzyre_cert_save_secret, 1 );

	rb_define_method( rzyre_cZyreCert, "dup", rzyre_cert_dup, 0 );
	rb_define_method( rzyre_cZyreCert, "eql?", rzyre_cert_eql_p, 1 );
	rb_define_method( rzyre_cZyreCert, "print", rzyre_cert_print, 0 );

	rb_require( "zyre/cert" );
}

