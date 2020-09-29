#!/usr/bin/env rspec -cfd

require_relative '../spec_helper'

require 'zyre/poller'


RSpec.describe Zyre::Poller do

	it "can be constructed with no nodes" do
		instance = described_class.new

		expect( instance ).to be_a( described_class )
		expect( instance.nodes ).to be_empty
	end


	it "can be constructed with the nodes to wait on" do
		n1 = Zyre::Node.new
		n2 = Zyre::Node.new

		instance = described_class.new( n1, n2 )

		expect( instance ).to be_a( described_class )
		expect( instance.nodes ).to eq({
			n1.endpoint => n1,
			n2.endpoint => n2
		})
	end


	it "returns nil if no input arrives before the timeout" do
		n1 = Zyre::Node.new
		n2 = Zyre::Node.new

		instance = described_class.new( n1, n2 )

		rval = instance.wait( 0.25 )

		expect( rval ).to be_nil
	end

end

