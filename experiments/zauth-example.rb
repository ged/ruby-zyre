#!/usr/bin/env ruby

# Play with how Zauth should be implmented from the Ruby perspective.

require 'zyre'


Zyre.start_authenticator
Zyre.verbose_auth!

# Allow (whitelist) a list of IP addresses. For NULL, all clients from
# these addresses will be accepted. For PLAIN and CURVE, they will be
# allowed to continue with authentication. You can call this method
# multiple times to whitelist more IP addresses. If you whitelist one
# or nmore addresses, any non-whitelisted addresses are treated as
# blacklisted:
#
#     zstr_sendx (auth, "ALLOW", "127.0.0.1", "127.0.0.2", NULL);
#     zsock_wait (auth);
Zyre.auth_allow( '127.0.0.1', '127.0.0.2' )

# Deny (blacklist) a list of IP addresses. For all security mechanisms,
# this rejects the connection without any further authentication. Use
# either a whitelist, or a blacklist, not not both. If you define both
# a whitelist and a blacklist, only the whitelist takes effect:
#
#     zstr_sendx (auth, "DENY", "192.168.0.1", "192.168.0.2", NULL);
#     zsock_wait (auth);
Zyre.auth_deny( '192.168.0.1', '192.168.0.2' )

# Configure PLAIN authentication using a plain-text password file. You can
# modify the password file at any time; zauth will reload it automatically
# if modified externally:
#
#     zstr_sendx (auth, "PLAIN", filename, NULL);
#     zsock_wait (auth);
Zyre.enable_plain_auth( 'passwords.txt' )

# Configure CURVE authentication, using a directory that holds all public
# client certificates, i.e. their public keys. The certificates must be in
# zcert_save format. You can add and remove certificates in that directory
# at any time. To allow all client keys without checking, specify
# CURVE_ALLOW_ANY for the directory name:
#
#     zstr_sendx (auth, "CURVE", directory, NULL);
#     zsock_wait (auth);
Zyre.enable_curve_auth( 'certs/' )

# Configure GSSAPI authentication, using an underlying mechanism (usually
# Kerberos) to establish a secure context and perform mutual authentication:
#
#     zstr_sendx (auth, "GSSAPI", NULL);
#     zsock_wait (auth);
Zyre.enable_gssapi_auth


