#!/usr/bin/env rspec -cfd

require_relative '../spec_helper'

require 'securerandom'
require 'zyre/node'


RSpec.describe( Zyre::Node ) do

	TEST_WHISPER = <<~END_WHISPER
	I hear you whispering there, O stars of heaven;
	O suns! O grass of graves! O perpetual transfers and promotions!
	END_WHISPER

	TEST_SHOUT = <<~END_SHOUT
	I too am not a bit tamed—I too am untranslatable;
	I sound my barbaric yawp over the roofs of the world.
	END_SHOUT

	TEST_BINARY_STRING_PARTS = [
		SecureRandom.bytes( 128 ),
		"\x00".b,
		SecureRandom.bytes( 128 )
	]
	TEST_BINARY_STRING = TEST_BINARY_STRING_PARTS.join( '' )


	it "can be created anonymously" do
		node = described_class.new

		expect( node ).to be_a( described_class )
		expect( node.name ).to eq( node.uuid[0,6] )
	end


	it "can be create with a name" do
		node = described_class.new( 'raptor1' )

		expect( node ).to be_a( described_class )
		expect( node.name ).to eq( 'raptor1' )
		expect( node.name ).to be_frozen
	end


	it "can set headers" do
		node1 = started_node do |n|
			n.set_header( 'Protocol-version', '2' )
		end
		node2 = started_node

		event = node2.wait_for( :ENTER )

		expect( event.headers ).to eq({ 'Protocol-version' => '2' })
	end


	it "can set headers from a hash" do
		node1 = started_node do |n|
			n.headers = {
				protocol_version: 2,
				content_type: 'application/messagepack'
			}
		end
		node2 = started_node

		event = node2.wait_for( :ENTER )

		expect( event.headers ).to eq({
			'Protocol-version' => '2',
			'Content-type' => 'application/messagepack'
		})
	end


	it "can have a custom evasive timeout" do
		node = described_class.new
		expect {
			node.evasive_timeout = 225
		}.to_not raise_error
	end


	it "can have a custom silent timeout" do
		skip "Not implemented on this platform" unless
			described_class.instance_methods.include?( :silent_timeout= )

		node = described_class.new
		expect {
			node.silent_timeout = 10000
		}.to_not raise_error
	end


	it "can have a custom expired timeout" do
		node = described_class.new
		expect {
			node.expired_timeout = 7500
		}.to_not raise_error
	end


	it "can have a custom beacon discovery interval" do
		node = described_class.new
		expect {
			node.interval = 250
		}.to_not raise_error
	end


	it "can be set to communicate on a particular network interface" do
		node = described_class.new
		expect {
			node.interface = 'lo0'
		}.to_not raise_error
	end


	it "knows what its own groups are" do
		node = started_node()
		node.join( 'GLOBAL' )
		node.join( 'SPECIAL' )

		expect( node.own_groups ).to contain_exactly( 'GLOBAL', 'SPECIAL' )
	end


	it "knows what groups are known via its connected peers" do
		node1 = started_node()
		node1.join( 'GLOBAL' )
		node1.join( 'SPECIAL' )

		node2 = started_node()

		node1.wait_for( :ENTER, peer_uuid: node2.uuid )

		expect( node2.peer_groups ).to contain_exactly( 'GLOBAL', 'SPECIAL' )
	end


	it "returns an empty array for known groups with no peers" do
		node1 = started_node()

		expect( node1.peer_groups ).to be_empty
	end


	it "knows what one of its peers' address is" do
		node1 = started_node()
		node2 = started_node()

		enter_event = node1.wait_for( :ENTER, peer_uuid: node2.uuid )

		expect( node1.peer_address(node2.uuid) ).to eq( enter_event.peer_addr )
	end


	it "returns nil for the address of non-existent peers" do
		node1 = started_node()
		node2 = Zyre::Node.new

		expect( node1.peer_address(node2.uuid) ).to be_nil
	end


	it "can whisper to another node" do
		node1 = started_node()
		node2 = started_node()

		node1.wait_for( :ENTER, peer_uuid: node2.uuid )
		node1.whisper( node2.uuid, TEST_WHISPER )

		ev = node2.wait_for( :WHISPER )
		expect( ev ).to be_a( Zyre::Event::Whisper )
		expect( ev ).to_not be_multipart
		msg = ev.msg
		expect( msg.encoding ).to eq( Encoding::ASCII_8BIT )
		msg = msg.dup.force_encoding( 'utf-8' )
		expect( msg ).to eq( TEST_WHISPER )
		expect( ev.multipart_msg ).to eq( [TEST_WHISPER.b] )
	end


	it "can whisper a multipart message to another node" do
		node1 = started_node()
		node2 = started_node()

		node1.wait_for( :ENTER, peer_uuid: node2.uuid )
		node1.whisper( node2.uuid, 'poetry.snippet', TEST_WHISPER )

		ev = node2.wait_for( :WHISPER, peer_uuid: node1.uuid )
		expect( ev ).to be_a( Zyre::Event::Whisper )
		expect( ev ).to be_multipart
		expect( ev.msg.encoding ).to eq( Encoding::ASCII_8BIT )
		expect( ev.msg ).to eq( 'poetry.snippet' )
		expect( ev.multipart_msg ).to eq( ['poetry.snippet', TEST_WHISPER] )
	end


	it "can shout to a group of nodes" do
		node1 = started_node()
		node2 = started_node()

		node1.join( 'ROOFTOP' )
		node2.join( 'ROOFTOP' )

		node1.wait_for( :JOIN, group: 'ROOFTOP', peer_uuid: node2.uuid )
		node1.shout( 'ROOFTOP', TEST_SHOUT )

		ev = node2.recv
		expect( ev ).to be_a( Zyre::Event::Enter )

		ev = node2.recv
		expect( ev ).to be_a( Zyre::Event::Join )

		ev = node2.recv
		expect( ev ).to be_a( Zyre::Event::Shout )
		expect( ev ).to_not be_multipart
		expect( ev.msg.encoding ).to eq( Encoding::ASCII_8BIT )
		expect( ev.msg ).to eq( TEST_SHOUT.b )
		expect( ev.multipart_msg ).to eq( [TEST_SHOUT.b] )
	end


	it "can shout a multipart message to a group of nodes" do
		node1 = started_node()
		node2 = started_node()
		node3 = started_node()

		node1.join( 'ROOFTOP' )
		node2.join( 'ROOFTOP' )
		node3.join( 'ROOFTOP' )

		2.times do
			node1.wait_for( :JOIN, group: 'ROOFTOP' )
		end
		node1.shout( 'ROOFTOP', "random.poetry", TEST_SHOUT )

		ev = node2.wait_for( :SHOUT, group: 'ROOFTOP' )
		expect( ev ).to be_a( Zyre::Event::Shout )
		expect( ev ).to be_multipart
		expect( ev.msg ).to eq( 'random.poetry'.b )
		expect( ev.multipart_msg ).to eq( ['random.poetry'.b, TEST_SHOUT.b] )
	end


	it "can shout a binary message to a group of nodes" do
		node1 = started_node()
		node2 = started_node()
		node3 = started_node()

		node1.join( 'stream' )
		node2.join( 'stream' )
		node3.join( 'stream' )

		2.times do
			node1.wait_for( :JOIN, group: 'stream' )
		end
		node1.shout( 'stream', TEST_BINARY_STRING )

		ev = node2.wait_for( :SHOUT, group: 'stream' )
		expect( ev ).to be_a( Zyre::Event::Shout )
		expect( ev ).to_not be_multipart
		expect( ev.msg ).to eq( TEST_BINARY_STRING )

		ev = node3.wait_for( :SHOUT, group: 'stream' )
		expect( ev ).to be_a( Zyre::Event::Shout )
		expect( ev ).to_not be_multipart
		expect( ev.msg ).to eq( TEST_BINARY_STRING )
	end


	it "can shout a multipart binary message to a group of nodes" do
		node1 = started_node()
		node2 = started_node()
		node3 = started_node()

		node1.join( 'stream' )
		node2.join( 'stream' )
		node3.join( 'stream' )

		2.times do
			node1.wait_for( :JOIN, group: 'stream' )
		end
		node1.shout( 'stream', *TEST_BINARY_STRING_PARTS )

		ev = node2.wait_for( :SHOUT, group: 'stream' )
		expect( ev ).to be_a( Zyre::Event::Shout )
		expect( ev ).to be_multipart
		expect( ev.msg ).to eq( TEST_BINARY_STRING_PARTS[0] )
		expect( ev.multipart_msg ).to eq( TEST_BINARY_STRING_PARTS )

		ev = node3.wait_for( :SHOUT, group: 'stream' )
		expect( ev ).to be_a( Zyre::Event::Shout )
		expect( ev ).to be_multipart
		expect( ev.msg ).to eq( TEST_BINARY_STRING_PARTS[0] )
		expect( ev.multipart_msg ).to eq( TEST_BINARY_STRING_PARTS )
	end


	it "handles unstringifiable messages gracefully" do
		node1 = started_node()
		node1.join( 'ROOFTOP' )

		expect {
			node1.shout( 'ROOFTOP', nil )
		}.to raise_error( TypeError, /nil/i )
	end


	it "knows who all of its peers are" do
		node1 = started_node()
		node2 = started_node()
		node3 = started_node()
		node4 = started_node()

		3.times do
			node1.wait_for( :ENTER )
		end

		expect( node1.peers ).to contain_exactly( node2.uuid, node3.uuid, node4.uuid )
	end


	it "returns an empty array for its peers if it has none" do
		node1 = started_node()

		expect( node1.peers ).to be_empty
	end


	it "knows who its peers for a certain group are" do
		node1 = started_node()
		node1.join( 'CHANNEL1' )
		node1.join( 'CHANNEL2' )
		node2 = started_node()
		node2.join( 'CHANNEL1' )
		node3 = started_node()
		node3.join( 'CHANNEL1' )
		node4 = started_node()
		node4.join( 'CHANNEL2' )

		2.times do
			node1.wait_for( :JOIN, group: 'CHANNEL1' )
		end

		expect( node1.peers_by_group('CHANNEL1') ).
			to contain_exactly( node2.uuid, node3.uuid )
	end


	it "knows what the headers of its peers are" do
		node1 = started_node()
		node2 = started_node() do |node|
			node.headers = {
				protocol_version: 2,
				content_type: 'application/javascript',
				start_time: Time.now.to_f
			}
		end

		node1.wait_for( :enter, peer_uuid: node2.uuid )

		expect( node1.peer_header_value(node2.uuid, 'Protocol-version') ).to eq( '2' )
	end


	it "has a blocking iterator" do
		node = described_class.new

		expect( node.each_event ).to be_an( Enumerator )
	end


	it "yields events from its iterator" do
		node1 = started_node()
		node1.join( 'CHANNEL1' )

		node2 = started_node()
		node2.join( 'CHANNEL1' )
		node2.shout( 'CHANNEL1', "A broadcast message" )

		node2.wait_for( :ENTER )

		events = node1.each_event.take( 2 )
		expect( events ).to all( be_a Zyre::Event )
	end


	it "can wait for a specified event type" do
		node1 = started_node()
		node1.join( 'wait-test' )

		node2 = started_node()
		node2.join( 'wait-test' )

		node1.wait_for( :JOIN )

		node2.shout( 'wait-test', "A broadcast message" )

		result = node1.wait_for( :SHOUT )

		expect( result ).to be_a( Zyre::Event::Shout ).
			and( have_attributes(message: 'A broadcast message') )
	end


	it "can wait for a specified event to arrive within a time limit" do
		node1 = started_node()
		node1.join( 'wait-timeout-test' )

		wait( 3 ).for {
			node1.wait_for( :JOIN, timeout: 2 )
		}.to be_nil

		node2 = started_node()
		node2.join( 'wait-timeout-test' )

		wait( 3 ).for {
			node1.wait_for( :JOIN, timeout: 2 )
		}.to be_a( Zyre::Event::Join ).and( have_attributes(peer_uuid: node2.uuid) )
	end


	it "can wait for a specified event with specific attributes" do
		node1 = started_node()
		node1.join( 'wait-test' )

		node2 = started_node()
		node2.join( 'wait-test' )

		node1.wait_for( :JOIN, peer_uuid: node2.uuid )

		node2.shout( 'wait-test', "A broadcast message" )
		node2.shout( 'wait-test', "Another broadcast message" )

		skipped_events = []
		result = node1.wait_for( :SHOUT, message: "Another broadcast message" ) do |event|
			skipped_events << event
		end

		expect( result ).to be_a( Zyre::Event::Shout ).
			and( have_attributes(message: 'Another broadcast message') )
		expect( skipped_events.size ).to eq( 1 )
		expect( skipped_events.first ).to be_a( Zyre::Event::Shout ).
			and( have_attributes(message: "A broadcast message") )
	end


	it "can wait for a specified event with specific attributes to arrive within a time limit" do
		node1 = started_node()
		node1.join( 'wait-test' )

		node2 = started_node()
		node2.join( 'wait-test' )

		node1.wait_for( :JOIN, timeout: 0.5, peer_uuid: node2.uuid )

		node2.shout( 'wait-test', "A broadcast message" )

		skipped_events = []
		result = node1.wait_for( :SHOUT, timeout: 0.5, message: "Another broadcast message" ) do |event|
			skipped_events << event
		end

		expect( result ).to be_nil
		expect( skipped_events.size ).to eq( 1 )
		expect( skipped_events.first ).to be_a( Zyre::Event::Shout ).
			and( have_attributes(message: "A broadcast message") )

		node2.shout( 'wait-test', "Another broadcast message" )

		skipped_events.clear
		result = node1.wait_for( :SHOUT, timeout: 0.5, message: "Another broadcast message" ) do |event|
			skipped_events << event
		end

		expect( result ).to be_a( Zyre::Event::Shout ).
			and( have_attributes(message: 'Another broadcast message') )
		expect( skipped_events ).to be_empty
	end


end

