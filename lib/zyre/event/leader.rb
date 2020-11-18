# -*- ruby -*-
# frozen_string_literal: true

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Leader < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "%s (%s) has been elected leader of «%s»" % [
			self.peer_uuid,
			self.peer_name,
			self.group
		]
	end

end # class Zyre::Event::Leader
