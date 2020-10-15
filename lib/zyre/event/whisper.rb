# -*- ruby -*-
# frozen_string_literal: true

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Whisper < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return "whisper from %s (%s): %p" % [
			self.peer_uuid,
			self.peer_name,
			self.msg,
		]
	end

end # class Zyre::Event::Whisper
