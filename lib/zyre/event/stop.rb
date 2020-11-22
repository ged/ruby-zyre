# -*- ruby -*-
# frozen_string_literal: true

require 'zyre/event' unless defined?( Zyre::Event )


class Zyre::Event::Stop < Zyre::Event

	### Provide the details of the inspect message.
	def inspect_details
		return " node is stopping"
	end

end # class Zyre::Event::Stop
