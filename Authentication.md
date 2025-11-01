# Authenticated \Zyre

Note that authentication requires a Draft API, so it requires that your libzyre
be built with `--enable-drafts`. Also, since draft APIs are subject to change,
this documentation may be out of date. A good place to check for the latest
info is the built-in test suites in the Zyre source itself.

Authentication in Zyre is done using the mechanism built into ZeroMQ. To enable it, you start the authenticator actor ([zauth][]) and then configure the authentication you wish to use.

## Curve Authentication

To enable secure connections, you tell Zyre to enable Curve. You can either call this method with no argument, in which case any node that presents a valid cert will be allowed to connect, or you pass in the path to a [zcertstore][] that contains all the certificates of nodes which will be allowed to connect.

To document:

- Creating a certstore
- Enabling the authenticator
- Enabling curve authentication


## References

- ZAP (ZeroMQ Authentication Protocol) - https://rfc.zeromq.org/spec/27/
- Using ZeroMQ Security (Part 2) - https://jaxenter.com/using-zeromq-security-part-2-119353.html


[zauth]: http://api.zeromq.org/czmq3-0:zauth
[zcertstore]: http://api.zeromq.org/czmq3-0:zcertstore


