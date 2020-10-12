# -*- ruby -*-
# frozen_string_literal: true

require 'simplecov' if ENV['COVERAGE']

require 'rspec'

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
	config.filter_run_when_matching :focus
	config.order = :random
	config.profile_examples = 5
	config.run_all_when_everything_filtered = true
	config.shared_context_metadata_behavior = :apply_to_host_groups
	# config.warnings = true
end


