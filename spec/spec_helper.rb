# -*- ruby -*-
# frozen_string_literal: true

if ENV['COVERAGE'] || ENV['CI']
	require 'simplecov'
	if ENV['CI']
		require 'simplecov-cobertura'
		SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
	end
end

require 'rspec'
require 'rspec/wait'
require 'zyre'

require 'securerandom'
require 'loggability/spechelpers'


# Reset file descriptor limit higher for OSes that have low limits, e.g., OSX.
# Refs:
# - http://wiki.zeromq.org/docs:tuning-zeromq#toc1
begin
	current_fdmax, max_fdmax = Process.getrlimit( :NOFILE )
	if max_fdmax < 4096
		warn <<~END_WARNING
		>>>
		>>> Couldn't set file-descriptor ulimit to 4096. Later specs might fail due
		>>> to lack of file descriptors.
		>>>
		END_WARNING
	else
		Process.setrlimit( :NOFILE, 4096 ) if current_fdmax < 4096
	end
end

begin
	require 'observability'
	$have_observability = true

	Observability::Sender.configure( type: :testing )
rescue LoadError => err
	$have_observability = false
end


module Zyre::SpecHelpers

	### Add hooks when the given +context+ has helpers added to it.
	def self::included( context )

		context.let( :gossip_hub ) { "inproc://gossip-hub-%s" % [ SecureRandom.hex(16) ] }

		context.before( :each ) do
			@gossip_endpoint = nil
			@nodes = []
		end

		context.after( :each ) do
			@nodes.each( &:stop )
		end

		super
	end


	###############
	module_function
	###############

	### Return a node that's been configured and started.
	def started_node( name=nil )
		node = Zyre::Node.new( name )
		node.endpoint = 'inproc://node-test-%s' % [ SecureRandom.hex(16) ]
		yield( node ) if block_given?

		if @gossip_endpoint
			# $stderr.puts "Connecting to %p" % [ @gossip_endpoint ]
			node.gossip_connect( @gossip_endpoint )
		else
			@gossip_endpoint = gossip_hub()
			# $stderr.puts "Binding to %p" % [ @gossip_endpoint ]
			node.gossip_bind( @gossip_endpoint )
			sleep 0.25
		end

		# $stderr.puts "Starting %p" % [ node ]
		node.start
		@nodes << node

		return node
	end

end # module Zyre::SpecHelpers


### Mock with RSpec
RSpec.configure do |config|
	config.expect_with :rspec do |expectations|
		expectations.include_chain_clauses_in_custom_matcher_descriptions = true
		expectations.syntax = :expect
	end

	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
		mock.verify_partial_doubles = true
	end

	config.disable_monkey_patching!
	config.example_status_persistence_file_path = "spec/.status"
	config.filter_run :focus
	config.filter_run_excluding :observability unless $have_observability
	config.filter_run_when_matching :focus
	config.order = :random
	config.profile_examples = 5
	config.run_all_when_everything_filtered = true
	config.shared_context_metadata_behavior = :apply_to_host_groups
	# config.warnings = true

	config.include( Zyre::SpecHelpers )
	config.include( Loggability::SpecHelpers )
end


