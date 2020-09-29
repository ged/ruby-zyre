# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'zyre' unless defined?( Zyre )


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

end # class Zyre::Node
