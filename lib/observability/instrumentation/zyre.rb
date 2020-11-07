# -*- ruby -*-
# frozen_string_literal: true

require 'observability'
require 'observability/instrumentation' unless defined?( Observability::Instrumentation )


# Instrumentation for the Zyre library
# Refs:
# - https://github.com/zeromq/zyre
# - https://gitlab.com/ravngroup/open-source/ruby-zyre
module Observability::Instrumentation::Zyre
	extend Observability::Instrumentation

	depends_on 'Zyre'


	when_installed( 'Zyre::Node' ) do
		Zyre::Node.extend( Observability )
		Zyre::Node.observe_class_method( :new )
		Zyre::Node.observe_method( :port= )
		Zyre::Node.observe_method( :evasive_timeout= )
		Zyre::Node.observe_method( :interface= )
		Zyre::Node.observe_method( :endpoint= )
		Zyre::Node.observe_method( :set_header )
		Zyre::Node.observe_method( :start )
		Zyre::Node.observe_method( :stop )
		Zyre::Node.observe_method( :join )
		Zyre::Node.observe_method( :leave )
		Zyre::Node.observe_method( :recv )
		Zyre::Node.observe_method( :whisper, &self.method(:observe_whisper) )
		Zyre::Node.observe_method( :shout, &self.method(:observe_shout) )
	end


	###############
	module_function
	###############

	### Observer callback for the #whisper method.
	def observe_whisper( peer_uuid, *msgs )
		Observability.observer.add( peer_uuid: peer_uuid, messages: msgs )
	end


	### Observer callback for the #shout method.
	def observe_shout( group, *msgs )
		Observability.observer.add( group: group, messages: msgs )
	end

end # module Observability::Instrumentation::Zyre

