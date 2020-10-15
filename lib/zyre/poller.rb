# -*- ruby -*-
# frozen_string_literal: true

require 'loggability'

require 'zyre' unless defined?( Zyre )


#--
# See also: ext/zyre_ext/poller.c
class Zyre::Poller
	extend Loggability

	log_to :zyre

end # class Zyre::Poller
