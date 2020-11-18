# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'zyre' unless defined?( Zyre )


#--
# See also: ext/zyre_ext/event.c
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
	autoload :Leader, 'zyre/event/leader'
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


	### Return the event type as Zyre refers to it.
	def self::type_name
		return self.name[ /.*::(\w+)/, 1 ].upcase
	end


	# Some convenience aliases
	alias_method :message, :msg


	### Returns +true+ if the specified +criteria+ match attribute of the event.
	def match( criteria )
		return criteria.all? do |key, val|
			self.respond_to?( key ) && self.public_send( key ) == val
		end
	end


	### Returns +true+ if the receiving event has a multipart message.
	def multipart?
		size = self.msg_size
		return size && size > 1
	end
	alias_method :is_multipart?, :multipart?


	### Return a string describing this event, suitable for debugging.
	def inspect
		details = self.inspect_details
		details = ' ' + details unless details.start_with?( ' ' )

		return "#<%p:%#016x%s>" % [
			self.class,
			self.object_id,
			details,
		]
	end


	### Provide the details of the inspect message. Defaults to an empty string.
	def inspect_details
		return ''
	end

end # class Zyre::Event

