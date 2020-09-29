# -*- ruby -*-
# frozen_string_literal: true

require 'zyre' unless defined?( Zyre )


class Zyre::Event


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

