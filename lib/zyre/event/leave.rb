# -*- ruby -*-

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Leave < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "%s (%s) left «%s»" % [
			self.peer_uuid,
			self.peer_name,
			self.group
		]
	end

end # class Zyre::Event::Leave
