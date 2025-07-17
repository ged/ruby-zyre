#!/usr/bin/env ruby

# Set up an authenticated Zyre node

require 'pathname'
require 'loggability'
require 'zyre'
require 'zyre/event/enter'
require 'zyre/event/join'
require 'zyre/event/shout'

Loggability.level = :debug

ZAP_DOMAIN = 'TEST'
NODE1_ID = 'cb4e'
NODE2_ID = '17be'

CERT_DIR = Pathname( './certs/' )
CERT_DIR.mkpath
CERT1_FILE = CERT_DIR / NODE1_ID
CERT2_FILE = CERT_DIR / NODE2_ID

puts "Starting the authenticator."
Zyre.start_authenticator
Zyre.verbose_auth!

puts "Enabling CURVE auth."
Zyre.enable_curve_auth( CERT_DIR.to_s )

puts "Creating node1."
node1 = Zyre::Node.new( NODE1_ID )
node1.verbose!
node1.zap_domain = ZAP_DOMAIN

puts "Creating node2."
node2 = Zyre::Node.new( NODE2_ID )
node2.verbose!
node2.zap_domain = ZAP_DOMAIN

puts "Setting up cert for node1."
node1_cert = Zyre::Cert.new
node1_cert.save_public( CERT1_FILE.to_s ) if CERT_DIR.directory?
node1.zcert = node1_cert
node1.set_header( 'X-PUBLICKEY', node1_cert.public_txt )

puts "Setting up cert for node2."
node2_cert = Zyre::Cert.new
node2_cert.save_public( CERT2_FILE.to_s ) if CERT_DIR.directory?
node2.zcert = node2_cert
node2.set_header( 'X-PUBLICKEY', node2_cert.public_txt )

puts "Starting node1."
node1.start
node1.join( 'GLOBAL' )

puts "Starting node2."
node2.start
node2.join( 'GLOBAL' )

sleep 1.5

puts "Waiting for node2 to see node1."
node2.wait_for( 'ENTER' )
puts "Node2 saw node1 enter."
node2.wait_for( 'JOIN' )
puts "Node2 saw node1 join."

node1.shout( 'GLOBAL', 'Hello world' )

shout = node2.wait_for( 'SHOUT' )
puts "Node2 got: %p" % [ shout ]


node2.leave( 'GLOBAL' )
node1.leave( 'GLOBAL' )

Zyre.stop_authenticator

