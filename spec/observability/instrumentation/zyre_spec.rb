#!/usr/bin/env rspec -cfd

require_relative '../../spec_helper'


RSpec.describe 'Observability::Instrumentation::Zyre', :observability do

	before( :all ) do
		Observability.install_instrumentation( :zyre )
	end

	before( :each ) do
		Observability.observer.sender.enqueued_events.clear
	end


	let( :described_class ) { Observability::Instrumentation::Zyre }


	it "is available" do
		expect( described_class ).to be_available
	end


	it "records the peer ID and message when a whisper is sent" do
		node1 = started_node()
		node2 = started_node()

		node1.whisper( node2.uuid, "a peer-to-peer message" )

		events = Observability.observer.sender.find_events( 'zyre.node.whisper' )
		expect( events.length ).to eq( 1 )
		expect( events.first[:peer_uuid] ).to eq( node2.uuid )
		expect( events.first[:messages] ).to eq( ['a peer-to-peer message'] )

	end


	it "records the group and message when a shout is sent" do
		node1 = started_node()
		node1.join( 'observer-testing' )
		node2 = started_node()
		node2.join( 'observer-testing' )

		node1.wait_for( :JOIN, timeout: 2.0, peer_uuid: node2.uuid )

		node1.shout( 'observer-testing', "a peer-to-peer message" )

		events = Observability.observer.sender.find_events( 'zyre.node.shout' )
		expect( events.length ).to eq( 1 )
		expect( events.first[:group] ).to eq( 'observer-testing' )
		expect( events.first[:messages] ).to eq( ['a peer-to-peer message'] )
	end

end

