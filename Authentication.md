# Authenticated \Zyre

Note that authentication requires API that is still in Draft, so it requires
that your libzyre be built with --enable-drafts. Also, since draft APIs are
subject to change, this documentation may be out of date. A good place to check
for the latest info is the built-in test suites in the Zyre source itself.

Authentication isn't done yet, but when it is it'll look something like:

    cert = Zyre::Cert.new
    cert.save( "/usr/local/var/certs/server" )

    Zyre.allow( "127.0.0.1", "10.0.12.2" )
    Zyre.start_authenticator( :CURVE, "/usr/local/var/certs" )

    node = Zyre::Node.new
    node.zap_domain = 'application_name'
    node.zcert = cert
    node.start

    # later...

    node.stop
    Zyre.stop_authenticator


## References

- ZAP (ZeroMQ Authentication Protocol) - https://rfc.zeromq.org/spec/27/
- Using ZeroMQ Security (Part 2) - https://jaxenter.com/using-zeromq-security-part-2-119353.html
