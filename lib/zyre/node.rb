# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'zyre' unless defined?( Zyre )


#--
# See also: ext/zyre_ext/node.c
class Zyre::Node
	extend Loggability


	# Use the Zyre logger
	log_to :zyre



	### Yield each incoming event to the block. If no block is given, returns an
	### enumerator instead.
	def each_event( &block )
		iter = self.make_event_enum
		return iter.each( &block ) if block
		return iter
	end
	alias_method :each, :each_event


	### Wait for an event of a given +event_type+ (e.g., :JOIN) and matching any
	### optional +criteria+, returning the event if a matching one was seen. If a
	### +timeout+ is given and the event hasn't been seen after the +timeout+
	### seconds have elapsed, return +nil+. If a block is given, call the block
	### for each (non-matching) event that arrives in the interim. Note that the
	### execution time of the block is counted in the timeout.
	def wait_for( event_type, timeout: nil, **criteria, &block )
		expected_type = Zyre::Event.type_by_name( event_type ) or
			raise ArgumentError, "no such event type %p" % [ event_type ]

		if timeout
			return self.wait_for_with_timeout( expected_type, timeout, **criteria, &block )
		else
			return self.wait_for_indefinitely( expected_type, **criteria, &block )
		end
	end


	### Set headers from the given +hash+. Convenience wrapper for #set_header. Symbol
	### keys will have `_` characters converted to `-` and will be capitalized when
	### converted into Strings. E.g.,
	###
	###   headers = { content_type: 'application/json' }
	###
	### will call:
	###
	###   .set_header( 'Content-type', 'application/json' )
	###
	def headers=( hash )
		hash.each do |key, val|
			key = transform_header_key( key )
			self.set_header( key.to_s, val.to_s )
		end
	end


	#########
	protected
	#########

	### Create an Enumerator that yields each event as it comes in. If there is
	### no event to read, block until there is one.
	def make_event_enum
		return Enumerator.new do |yielder|
			while event = self.recv
				yielder.yield( event )
			end
		end
	end


	### Wait for an event of the given +event_class+ and +criteria+, returning it when it
	### arrives. Blocks indefinitely until it arrives or interrupted.
	def wait_for_indefinitely( event_class, **criteria, &block )
		poller = Zyre::Poller.new( self )
		while poller.wait
			event = self.recv
			if event.kind_of?( event_class ) && event.match( criteria )
				return event
			else
				block.call( event ) if block
			end
		end
	end


	### Wait for an event of the given +event_class+ and +criteria+, returning it if
	### it arrives before +timeout+ seconds elapses. If the timeout elapses first,
	### return +nil+.
	def wait_for_with_timeout( event_class, timeout, **criteria, &block )
		start_time = get_monotime()
		timeout_at = start_time + timeout

		poller = Zyre::Poller.new( self )

		timeout = timeout_at - get_monotime()
		while timeout > 0
			if poller.wait( timeout )
				event = self.recv
				if event.kind_of?( event_class ) && event.match( criteria )
					return event
				else
					block.call( event ) if block
				end
			else
				break
			end

			timeout = timeout_at - get_monotime()
		end

		return nil

	end


	#######
	private
	#######

	### Return the monotonic time.
	def get_monotime
		return Process.clock_gettime( Process::CLOCK_MONOTONIC )
	end


	### If the given +key+ is a Symbol, transform it into an RFC822-style header key. If
	### it's not a Symbol, returns it unchanged.
	def transform_header_key( key )
		if key.is_a?( Symbol )
			key = key.to_s.gsub( /_/, '-' ).capitalize
		end

		return key
	end

end # class Zyre::Node
