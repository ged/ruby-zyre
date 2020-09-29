#!/usr/bin/env rspec -cfd

require_relative 'spec_helper'

require 'zyre'


RSpec.describe Zyre do

	it "knows what version of the underlying library it's using" do
		expect( described_class.zyre_version ).to be_a( Integer )
		expect( described_class.zyre_version ).to be >= 2_00_00
	end

end

