# -*- ruby -*-
# frozen_string_literal: true

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Shout < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "shout from %s (%s) on «%s»: %p" % [
			self.peer_uuid,
			self.peer_name,
			self.group,
			self.msg,
		]
	end

end # class Zyre::Event::Shout
