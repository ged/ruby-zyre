# -*- ruby -*-
# frozen_string_literal: true

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Evasive < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "%s (%s) is being evasive and will be pinged manually" % [
			self.peer_uuid,
			self.peer_name,
		]
	end

end # class Zyre::Event::Evasive
