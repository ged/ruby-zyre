# -*- ruby -*-
# frozen_string_literal: true

require 'set'
require 'loggability'

require_relative 'zyre_ext'


#--
# See also: ext/zyre_ext/zyre_ext.c
module Zyre
	extend Loggability


	# Gem version (semver)
	VERSION = '0.3.1'


	# Set up a logger for Zyre classes
	log_as :zyre


	@whitelisted_ips = Set.new
	@blacklisted_ips = Set.new


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


	### Allow (whitelist) a list of IP +addresses+. For NULL, all clients from
	### these addresses will be accepted. For PLAIN and CURVE, they will be
	### allowed to continue with authentication. You can call this method
	### multiple times to whitelist more IP addresses. If you whitelist one
	### or more addresses, any non-whitelisted addresses are treated as
	### blacklisted:
	def self::allow( *addresses )
		@whitelisted_ips.merge( addresses )
	end


	### Deny (blacklist) a list of IP +addresses+. For all security mechanisms,
	### this rejects the connection without any further authentication. Use
	### either a whitelist, or a blacklist, not not both. If you define both
	### a whitelist and a blacklist, only the whitelist takes effect:
	def self::deny( *addresses )
		@blacklisted_ips.merge( addresses )
	end


	### Returns +true+ if the underlying Czmq library was built with draft APIs.
	def self::has_draft_czmq_apis?
		return Zyre::BUILT_WITH_DRAFT_CZMQ_API ? true : false
	end


	### Returns +true+ if the underlying Zyre library was built with draft APIs.
	def self::has_draft_apis?
		return Zyre::BUILT_WITH_DRAFT_API ? true : false
	end

end # module Zyre
