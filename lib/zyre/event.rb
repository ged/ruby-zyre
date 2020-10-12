# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'zyre' unless defined?( Zyre )


class Zyre::Event
	extend Loggability


	# Send logging to the 'zyre' logger
	log_to :zyre

	# Don't allow direct instantiation
	private_class_method :new


	# Autoload concrete event types
	autoload :Enter, 'zyre/event/enter'
	autoload :Evasive, 'zyre/event/evasive'
	autoload :Exit, 'zyre/event/exit'
	autoload :Join, 'zyre/event/join'
	autoload :Leave, 'zyre/event/leave'
	autoload :Shout, 'zyre/event/shout'
	autoload :Silent, 'zyre/event/silent'
	autoload :Stop, 'zyre/event/stop'
	autoload :Whisper, 'zyre/event/whisper'


	### Given the +name+ of an event type, return the Zyre::Event subclass that
	### corresponds to it.
	def self::type_by_name( name )
		capname = name.to_s.capitalize
		classobj = self.const_get( capname )
	rescue NameError => err
		self.log.debug( err )
		return nil
	end


	### Return a string describing this event, suitable for debugging.
	def inspect
		return "#<%p:%#016x %s from %s(%s) on «%s»: %p %p>" % [
			self.class,
			self.object_id,
			self.type,
			self.peer_name,
			self.peer_addr,
			self.group,
			self.headers,
			self.msg,
		]
	end


end # class Zyre::Event

