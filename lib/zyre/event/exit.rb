# -*- ruby -*-
# frozen_string_literal: true

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Exit < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "%s (%s) has left the network" % [
			self.peer_uuid,
			self.peer_name,
			self.headers,
		]
	end

end # class Zyre::Event::Exit
