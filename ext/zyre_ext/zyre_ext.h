/*
 *  zyre_ext.h - Ruby binding for Zyre
 *  $Id$
 *
 *  Authors:
 *    * Michael Granger <ged@FaerieMUD.org>
 *
 */

#ifndef ZYRE_EXT_H_90322ABD
#define ZYRE_EXT_H_90322ABD

#include <ruby.h>
#include <ruby/intern.h>
#include <ruby/thread.h>
#include <ruby/encoding.h>

#include "zyre.h"
#include "czmq.h"
#include "extconf.h"

#ifndef TRUE
# define TRUE    1
#endif

#ifndef FALSE
# define FALSE   0
#endif


// For synthesized events
struct _zyre_event_t {
    char *type;             //  Event type as string
    char *peer_uuid;        //  Sender UUID as string
    char *peer_name;        //  Sender public name as string
    char *peer_addr;        //  Sender ipaddress as string, for an ENTER event
    zhash_t *headers;       //  Headers, for an ENTER event
    char *group;            //  Group name for a SHOUT event
    zmsg_t *msg;            //  Message payload for SHOUT or WHISPER
};


/* --------------------------------------------------------------
 * Declarations
 * -------------------------------------------------------------- */

#ifdef HAVE_STDARG_PROTOTYPES
#include <stdarg.h>
#define va_init_list(a,b) va_start(a,b)
void rzyre_log_obj( VALUE, const char *, const char *, ... );
void rzyre_log( const char *, const char *, ... );
#else
#include <varargs.h>
#define va_init_list(a,b) va_start(a)
void rzyre_log_obj( VALUE, const char *, const char *, va_dcl );
void rzyre_log( const char *, const char *, va_dcl );
#endif


/* --------------------------------------------------------------
 * Structs
 * -------------------------------------------------------------- */



/* -------------------------------------------------------
 * Globals
 * ------------------------------------------------------- */

/*
 * Modules
 */
extern VALUE rzyre_mZyre;
extern VALUE rzyre_cZyreNode;
extern VALUE rzyre_cZyreEvent;
extern VALUE rzyre_cZyrePoller;


/* --------------------------------------------------------------
 * Type-check macros
 * -------------------------------------------------------------- */

#define IsZyreNode( obj ) rb_obj_is_kind_of( (obj), rzyre_cZyreNode )
#define IsZyreEvent( obj ) rb_obj_is_kind_of( (obj), rzyre_cZyreEvent )
#define IsZyrePoller( obj ) rb_obj_is_kind_of( (obj), rzyre_cZyrePoller )


/* -------------------------------------------------------
 * Initializer functions
 * ------------------------------------------------------- */
extern void Init_zyre_ext _(( void ));

extern void rzyre_init_node _(( void ));
extern void rzyre_init_event _(( void ));
extern void rzyre_init_poller _(( void ));

extern zyre_t * rzyre_get_node _(( VALUE ));

#endif /* end of include guard: ZYRE_EXT_H_90322ABD */

