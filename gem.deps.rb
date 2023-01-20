# -*- ruby -*-
# frozen_string_literal: true

source 'https://rubygems.org/'

gem 'loggability', '~> 0.18', '>= 0.18.2'

group :development do
	gem 'rake-deveiate', '~> 0.15', '>= 0.15.1'
	gem 'rake-compiler', '~> 1.1'
	gem 'rubocop', '~> 0.91'
	gem 'rspec_junit_formatter', '~> 0.4'
	gem 'simplecov-cobertura', '~> 1.4'
	gem 'observability', '~> 0.3'
	gem 'rspec-wait', '~> 0.0'
end

