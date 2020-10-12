#!/usr/bin/env rspec -cfd

require_relative '../spec_helper'

require 'securerandom'
require 'zyre'


RSpec.describe( Zyre::Node ) do

	TEST_WHISPER = <<~END_WHISPER
	I hear you whispering there, O stars of heaven;
	O suns! O grass of graves! O perpetual transfers and promotions!
	END_WHISPER

	TEST_SHOUT = <<~END_SHOUT
	I too am not a bit tamed—I too am untranslatable;
	I sound my barbaric yawp over the roofs of the world.
	END_SHOUT


	let( :gossip_hub ) { "inproc://gossip-hub-%s" % [ SecureRandom.hex(16) ] }


	before( :each ) do
		@gossip_endpoint = nil
		@nodes = []
	end

	after( :each ) do
		@nodes.each( &:stop )
	end


	### Return a node that's been configured and started.
	def started_node
		node = described_class.new
		# node.verbose!

		node.endpoint = 'inproc://node-test-%s' % [ SecureRandom.hex(16) ]

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


	it "can have one or more headers" do
		node = described_class.new
		expect {
			node.evasive_timeout = 225
		}.to_not raise_error
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


	it "can whisper to another node" do
		node1 = started_node()
		node2 = started_node()

		sleep 0.25

		node1.whisper( node2.uuid, TEST_WHISPER )

		ev = node2.recv
		expect( ev.type ).to eq( :ENTER )

		ev = node2.recv
		expect( ev.type ).to eq( :WHISPER )
		expect( ev.msg.encoding ).to eq( Encoding::UTF_8 )
		expect( ev.msg ).to eq( TEST_WHISPER )
	end


	it "can shout to a group of nodes" do
		node1 = started_node()
		node2 = started_node()

		node1.join( 'ROOFTOP' )
		node2.join( 'ROOFTOP' )

		sleep 0.25

		node1.shout( 'ROOFTOP', TEST_SHOUT )

		ev = node2.recv
		expect( ev ).to be_a( Zyre::Event::Enter )

		ev = node2.recv
		expect( ev ).to be_a( Zyre::Event::Join )

		ev = node2.recv
		expect( ev ).to be_a( Zyre::Event::Shout )
		expect( ev.msg.encoding ).to eq( Encoding::UTF_8 )
		expect( ev.msg ).to eq( TEST_SHOUT )
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

		sleep 0.25

		expect( node1.peers_by_group('CHANNEL1') ).
			to contain_exactly( node2.uuid, node3.uuid )
	end

end

