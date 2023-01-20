# -*- ruby -*-
# frozen_string_literal: true

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Silent < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "%s %s (%s) isn't responding to pings" % [
			self.peer_uuid,
			self.peer_name,
			self.headers,
		]
	end

end # class Zyre::Event::Silent
