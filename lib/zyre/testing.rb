# -*- ruby -*-
# frozen_string_literal: true

require 'securerandom'
require 'loggability'

require 'zyre' unless defined?( Zyre )


# A collection of testing facilities, mostly for RSpec.
module Zyre::Testing

	# The minimum number of file descriptors required for testing
	TESTING_FILE_DESCRIPTORS = 4096


	# A Factory for generating synthesized ZRE events for testing
	class EventFactory
		extend Loggability


		# Default config values
		DEFAULT_HEADERS = {}
		DEFAULT_GROUP = 'default'
		DEFAULT_MSG = 'A message.'

		# Default config values to use to construct events
		DEFAULT_CONFIG = {
			headers: DEFAULT_HEADERS,
			group: DEFAULT_GROUP,
			msg: DEFAULT_MSG,
		}

		# The network to pretend events are sent over
		DEFAULT_NETWORK = '10.18.4.0'


		# Use the Zyre logger
		log_to :zyre


		### Return the Hash of default config options.
		def self::default_config
			return const_get( :DEFAULT_CONFIG )
		end


		### Return the Hash of default headers to use to construct events which have
		### them.
		def self::default_headers
			return const_get( :DEFAULT_HEADERS ).dup
		end


		### Return a random network address that's in the DEFAULT_NETWORK
		def self::random_network_address
			last_quad = rand( 1..254 )
			return DEFAULT_NETWORK.sub( /(?<=\.)0$/, last_quad.to_s )
		end


		### Return a port number that's in the ephemeral range.
		def self::random_ephemeral_port
			return rand( 49152 ... 65535)
		end


		### Return a random ZeroMQ-style address that points to an ephemeral port on the
		### DEFAULT_NETWORK.
		def self::random_addr
			return "tcp://%s:%d" % [ self.random_network_address, self.random_ephemeral_port ]
		end


		### Create a new factory that will use the values from the specified +config+
		### as defaults when constructing events.
		def initialize( **config )
			config = self.class.default_config.merge( config )
			self.log.debug "Setting up a factory with the config: %p" % [ config ]

			@peer_uuid = config[:peer_uuid] || SecureRandom.uuid
			@peer_name = config[:peer_name] || "S-%s" % [ @peer_uuid[0, 6] ]
			@peer_addr = config[:peer_addr] || self.class.random_addr

			@headers = config[:headers]
			@group = config[:group]
			@msg = config[:msg]
			self.log.debug( self )
		end


		######
		public
		######

		##
		# The peer_uuid that's assigned to any events created by this factory
		attr_accessor :peer_uuid

		##
		# The peer_name that's assigned to any events created by this factory
		attr_accessor :peer_name

		##
		# The peer_addr that's assigned to any events created by this factory
		attr_accessor :peer_addr

		##
		# The Hash of headers to set on any events created by this factory which have
		# headers
		attr_accessor :headers

		##
		# The name of the group set on any events created by this factory which have a
		# group
		attr_accessor :group

		##
		# The message data to set on any events create by this factory that have a
		# `msg`.
		attr_accessor :msg


		### Returns a Hash of the configured #headers with stringified keys and values.
		def normalized_headers
			return Zyre.normalize_headers( self.headers )
		end


		### Generate an ENTER event.
		def enter( **overrides )
			headers = overrides.delete( :headers ) || self.headers
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid
			config = {
				peer_name: self.peer_name,
				peer_addr: self.peer_addr,
				headers: Zyre.normalize_headers( headers )
			}.merge( overrides )

			return Zyre::Event.synthesize( :enter, uuid, **config )
		end


		### Generate a JOIN event.
		def join( **overrides )
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid
			config = {
				peer_name: self.peer_name,
				group: self.group
			}.merge( overrides )

			return Zyre::Event.synthesize( :join, uuid, **config )
		end


		### Generate a SHOUT event.
		def shout( group=nil, *msg, **overrides )
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid

			overrides[:group] = group if group
			overrides[:msg] = msg if !msg.empty?

			config = {
				peer_name: self.peer_name,
				group: self.group,
				msg: self.msg
			}.merge( overrides )

			return Zyre::Event.synthesize( :shout, uuid, **config )
		end


		### Generate a WHISPER event. The first positional argument, which would
		### normally be the UUID of the peer to WHISPER to is ignored, since the
		### generated event's +peer_uuid+ is the sending node's not the receiving one's.
		def whisper( _ignored=nil, *msg, **overrides )
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid

			overrides[:msg] = msg if !msg.empty?

			config = {
				peer_name: self.peer_name,
				msg: self.msg
			}.merge( overrides )

			return Zyre::Event.synthesize( :whisper, uuid, **config )
		end


		### Generate an EVASIVE event.
		def evasive( **overrides )
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid
			config = {
				peer_name: self.peer_name
			}.merge( overrides )

			return Zyre::Event.synthesize( :evasive, uuid, **config )
		end


		### Generate a SILENT event.
		def silent( **overrides )
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid
			config = {
				peer_name: self.peer_name
			}.merge( overrides )

			return Zyre::Event.synthesize( :silent, uuid, **config )
		end


		### Generate a LEAVE event.
		def leave( **overrides )
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid
			config = {
				peer_name: self.peer_name,
				group: self.group
			}.merge( overrides )

			return Zyre::Event.synthesize( :leave, uuid, **config )
		end


		### Generate an EXIT event.
		def exit( **overrides )
			uuid = overrides.delete( :peer_uuid ) || self.peer_uuid
			config = {
				peer_name: self.peer_name
			}.merge( overrides )

			return Zyre::Event.synthesize( :exit, uuid, **config )
		end

	end # class EventFactory


	### Add hooks when the given +context+ has helpers added to it.
	def self::included( context )

		context.let( :gossip_hub ) { "inproc://gossip-hub-%s" % [ SecureRandom.hex(16) ] }

		context.before( :each ) do
			@gossip_endpoint = nil
			@started_zyre_nodes = []
		end

		context.after( :each ) do
			@started_zyre_nodes.each( &:stop )
		end

		super
	end


	###############
	module_function
	###############

	### Return a node that's been configured and started.
	def started_node( name=nil )
		node = Zyre::Node.new( name )
		node.endpoint = 'inproc://node-test-%s' % [ SecureRandom.hex(16) ]

		yield( node ) if block_given?

		if @gossip_endpoint
			# $stderr.puts "Connecting to %p" % [ @gossip_endpoint ]
			node.gossip_connect( @gossip_endpoint )
		else
			@gossip_endpoint = gossip_hub()
			# $stderr.puts "Binding to %p" % [ @gossip_endpoint ]
			node.gossip_bind( @gossip_endpoint )
			sleep 0.25
		end

		# $stderr.puts "Starting %p" % [ node ]
		node.start
		@started_zyre_nodes << node

		return node
	end


	### Reset file descriptor limit higher for OSes that have low limits, e.g., OSX.
	### Refs:
	### - http://wiki.zeromq.org/docs:tuning-zeromq#toc1
	def check_fdmax
		current_fdmax, max_fdmax = Process.getrlimit( :NOFILE )

		if max_fdmax < TESTING_FILE_DESCRIPTORS
			warn <<~END_WARNING
			>>>
			>>> Can't set file-descriptor ulimit to #{TESTING_FILE_DESCRIPTORS}. Later specs
			>>> might fail due to lack of file descriptors.
			>>>
			END_WARNING
		else
			Process.setrlimit( :NOFILE, TESTING_FILE_DESCRIPTORS ) if
				current_fdmax < TESTING_FILE_DESCRIPTORS
		end
	end



end # module Zyre::Testing

