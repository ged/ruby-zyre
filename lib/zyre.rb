# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require_relative 'zyre_ext'


# A binding to libzyre
module Zyre
	extend Loggability


	# Gem version (semver)
	VERSION = '0.2.0'


	# Set up a logger for Zyre classes
	log_as :zyre


	### Wait on one or more +nodes+ to become readable, returning the first one that does
	### or +nil+ if the +timeout+ is zero or greater and at least that many seconds elapse.
	### Specify a +timeout+ of -1 to wait indefinitely. The timeout is in floating-point
	### seconds.
	###
	### Raises an Interrupt if the call is interrupted or the ZMQ context is destroyed.
	def self::wait( *nodes, timeout: -1 )
		nodes = nodes.flatten
		return nil if nodes.empty?
		return self.wait2( nodes, timeout )
	end


	### If the given +key+ is a Symbol, transform it into an RFC822-style header key. If
	### it's not a Symbol, returns it unchanged.
	def self::transform_header_key( key )
		if key.is_a?( Symbol )
			key = key.to_s.gsub( /_/, '-' ).capitalize
		end

		return key
	end


	### Transform the given +headers+ hash into a form that can be passed to Zyre.
	def self::normalize_headers( headers )
		return headers.
			transform_keys {|k| Zyre.transform_header_key(k) }.
			transform_values {|v| v.to_s.encode('us-ascii') }
	end

end # module Zyre
