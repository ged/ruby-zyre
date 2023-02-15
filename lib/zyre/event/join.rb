# -*- ruby -*-

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Join < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "%s (%s) joined «%s»" % [
			self.peer_uuid,
			self.peer_name,
			self.group
		]
	end

end # class Zyre::Event::Join
