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
require 'zyre/testing'

require 'securerandom'
require 'loggability/spechelpers'


begin
	require 'observability'
	$have_observability = true

	Observability::Sender.configure( type: :testing )
rescue LoadError => err
	$have_observability = false
end


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

	config.before( :suite ) do
		Zyre::Testing.check_fdmax
	end

	config.include( Zyre::Testing )
	config.include( Loggability::SpecHelpers )
end


