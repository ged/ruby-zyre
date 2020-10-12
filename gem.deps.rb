# -*- ruby -*-
# frozen_string_literal: true

source 'https://rubygems.org/'

gem 'loggability', '~> 0.17'

group :development do
	gem 'rake-deveiate', '~> 0.14', '>= 0.14.1'
	gem 'rake-compiler', '~> 1.1'
	gem 'rubocop', '~> 0.91'
end

