# -*- ruby -*-

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Enter < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "%s (%s at %s) has entered the network: %p" % [
			self.peer_uuid,
			self.peer_name,
			self.peer_addr,
			self.headers,
		]
	end

end # class Zyre::Event::Enter
