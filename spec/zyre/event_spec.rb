#!/usr/bin/env rspec -cfd

require_relative '../spec_helper'

require 'securerandom'
require 'zyre'


RSpec.describe( Zyre::Event ) do

	describe "concrete event classes" do

		it "can look up subtypes by upcased String name" do
			expect( described_class.type_by_name('ENTER') ).to eq( described_class::Enter )
			expect( described_class.type_by_name('EVASIVE') ).to eq( described_class::Evasive )
			expect( described_class.type_by_name('SILENT') ).to eq( described_class::Silent )
			expect( described_class.type_by_name('EXIT') ).to eq( described_class::Exit )
			expect( described_class.type_by_name('JOIN') ).to eq( described_class::Join )
			expect( described_class.type_by_name('LEAVE') ).to eq( described_class::Leave )
			expect( described_class.type_by_name('WHISPER') ).to eq( described_class::Whisper )
			expect( described_class.type_by_name('SHOUT') ).to eq( described_class::Shout )
		end


		it "can look up subtypes by downcased String name" do
			expect( described_class.type_by_name('enter') ).to eq( described_class::Enter )
			expect( described_class.type_by_name('evasive') ).to eq( described_class::Evasive )
			expect( described_class.type_by_name('silent') ).to eq( described_class::Silent )
			expect( described_class.type_by_name('exit') ).to eq( described_class::Exit )
			expect( described_class.type_by_name('join') ).to eq( described_class::Join )
			expect( described_class.type_by_name('leave') ).to eq( described_class::Leave )
			expect( described_class.type_by_name('whisper') ).to eq( described_class::Whisper )
			expect( described_class.type_by_name('shout') ).to eq( described_class::Shout )
		end


		it "can look up subtypes by upcased Symbol name" do
			expect( described_class.type_by_name(:Enter) ).to eq( described_class::Enter )
			expect( described_class.type_by_name(:Evasive) ).to eq( described_class::Evasive )
			expect( described_class.type_by_name(:Silent) ).to eq( described_class::Silent )
			expect( described_class.type_by_name(:Exit) ).to eq( described_class::Exit )
			expect( described_class.type_by_name(:Join) ).to eq( described_class::Join )
			expect( described_class.type_by_name(:Leave) ).to eq( described_class::Leave )
			expect( described_class.type_by_name(:Whisper) ).to eq( described_class::Whisper )
			expect( described_class.type_by_name(:Shout) ).to eq( described_class::Shout )
		end


		it "can look up subtypes by downcased Symbol name" do
			expect( described_class.type_by_name(:enter) ).to eq( described_class::Enter )
			expect( described_class.type_by_name(:evasive) ).to eq( described_class::Evasive )
			expect( described_class.type_by_name(:silent) ).to eq( described_class::Silent )
			expect( described_class.type_by_name(:exit) ).to eq( described_class::Exit )
			expect( described_class.type_by_name(:join) ).to eq( described_class::Join )
			expect( described_class.type_by_name(:leave) ).to eq( described_class::Leave )
			expect( described_class.type_by_name(:whisper) ).to eq( described_class::Whisper )
			expect( described_class.type_by_name(:shout) ).to eq( described_class::Shout )
		end


		it "can return its type as a String" do
			expect( described_class.type_by_name(:enter).type_name ).to eq( 'ENTER' )
			expect( described_class.type_by_name(:evasive).type_name ).to eq( 'EVASIVE' )
			expect( described_class.type_by_name(:silent).type_name ).to eq( 'SILENT' )
			expect( described_class.type_by_name(:exit).type_name ).to eq( 'EXIT' )
			expect( described_class.type_by_name(:join).type_name ).to eq( 'JOIN' )
			expect( described_class.type_by_name(:leave).type_name ).to eq( 'LEAVE' )
			expect( described_class.type_by_name(:whisper).type_name ).to eq( 'WHISPER' )
			expect( described_class.type_by_name(:shout).type_name ).to eq( 'SHOUT' )
		end


		it "returns nil for non-existent subtypes" do
			expect( described_class.type_by_name(:boom) ).to be_nil
		end

	end


	describe "matching API" do

		it "matches on a single criterion" do
			node1 = started_node()
			node1.join( 'matching-test' )

			node2 = started_node()
			node2.join( 'matching-test' )

			event = node1.wait_for( :JOIN )

			expect( event ).to match( peer_uuid: node2.uuid )
			expect( event ).not_to match( peer_uuid: node1.uuid )
		end


		it "matches on multiple criterion" do
			node1 = started_node( 'badger-2' )
			node1.join( 'matching-test2' )

			node2 = started_node( 'badger-6' )
			node2.join( 'matching-test2' )

			event = node1.wait_for( :JOIN )

			expect( event ).to match( peer_uuid: node2.uuid, peer_name: 'badger-6' )
			expect( event ).not_to match( peer_uuid: node2.uuid, peer_name: 'badger-2' )
		end


		it "matches Regexp patterns as values"

	end


	describe "synthesis API" do

		let( :peer_uuid ) { '8D9B6F67-2B40-4E56-B352-39029045B568' }


		it "can generate events without a node" do
			result = described_class.synthesize( :ENTER,
				peer_uuid, peer_name: 'node1', peer_addr: 'in-proc:/synthesized' )

			expect( result ).to be_a( described_class::Enter )
			expect( result.peer_uuid ).to eq( peer_uuid )
			expect( result.peer_name ).to eq( 'node1' )
			expect( result.peer_addr ).to eq( 'in-proc:/synthesized' )
		end


		it "defaults its peer_name to S- + six characters of the peer_uuid" do
			result = described_class.synthesize( :ENTER,
				peer_uuid, peer_addr: 'in-proc:/synthesized' )

			expect( result.peer_name ).to eq( 'S-' + peer_uuid[0, 6] )
		end


		it "can generate a SHOUT event with binary data in its msg" do
			data = "\xBF\x8D\x00\x9D\xDDg\x03_\xF2Nr\x01\xF0I8Au\x95\xC6L\xD37".b +
				"\xFFt\xC7\xE1\xC0<l\x17\xA2N\xE3".b

			result = described_class.synthesize( :SHOUT, peer_uuid, group: 'stream', msg: data )

			expect( result ).to be_a( described_class::Shout )
			expect( result.peer_uuid ).to eq( peer_uuid )
			expect( result.group ).to eq( 'stream' )
			expect( result.msg ).to eq( data )
		end


		it "raises when creating a WHISPER with no msg" do
			expect {
				described_class.synthesize( :WHISPER, peer_uuid )
			}.to raise_error( ArgumentError, /missing required field :msg/i )
		end


		it "raises when creating a SHOUT with no msg" do
			expect {
				described_class.synthesize( :SHOUT, peer_uuid, group: 'agroup' )
			}.to raise_error( ArgumentError, /missing required field :msg/i )
		end


		it "raises when creating a SHOUT with no group" do
			expect {
				described_class.synthesize( :SHOUT, peer_uuid, msg: 'amsg' )
			}.to raise_error( ArgumentError, /missing required field :group/i )
		end


		it "raises when creating an ENTER with no peer_addr" do
			expect {
				described_class.synthesize( :ENTER, peer_uuid )
			}.to raise_error( ArgumentError, /missing required field :peer_addr/i )
		end


		it "raises when creating a JOIN with no group" do
			expect {
				described_class.synthesize( :JOIN, peer_uuid )
			}.to raise_error( ArgumentError, /missing required field :group/i )
		end


		it "raises when creating a LEAVE with no group" do
			expect {
				described_class.synthesize( :LEAVE, peer_uuid )
			}.to raise_error( ArgumentError, /missing required field :group/i )
		end


		it "raises when creating an unknown type of event" do
			expect {
				described_class.synthesize( :BACKUP, peer_uuid )
			}.to raise_error( ArgumentError, /don't know how to create :BACKUP events/i )
		end

	end



	describe "inspect output" do

		let( :peer_uuid ) { '8D9B6F67-2B40-4E56-B352-39029045B568' }
		let( :peer_name ) { 'node1' }
		let( :peer_addr ) { 'in-proc:/synthesized' }


		it "has useful inspect output for ENTER events" do
			event = described_class.synthesize( :ENTER,
				peer_uuid, peer_name: peer_name, peer_addr: peer_addr,
				headers: {'Content-type' => 'application/msgpack'} )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to include( peer_addr )
			expect( event.inspect ).to match( /has entered the network/i )
			expect( event.inspect ).to match( /Content-type/i )
			expect( event.inspect ).to match( %r{application/msgpack}i )
		end


		it "has useful inspect output for EVASIVE events" do
			event = described_class.synthesize( :EVASIVE, peer_uuid, peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to match( /is being evasive/i )
		end


		it "has useful inspect output for EXIT events" do
			event = described_class.synthesize( :EXIT, peer_uuid, peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to match( /has left the network/i )
		end


		it "has useful inspect output for JOIN events" do
			event = described_class.synthesize( :JOIN,
				peer_uuid, group: 'CHANNEL1', peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to include( 'CHANNEL1' )
			expect( event.inspect ).to match( /joined/i )
		end


		it "has useful inspect output for LEADER events" do
			event = described_class.synthesize( :LEADER,
				peer_uuid, group: 'CHANNEL1', peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to include( 'CHANNEL1' )
			expect( event.inspect ).to match( /has been elected leader of/i )
		end


		it "has useful inspect output for LEAVE events" do
			event = described_class.synthesize( :LEAVE,
				peer_uuid, group: 'CHANNEL1', peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to include( 'CHANNEL1' )
			expect( event.inspect ).to match( /left/i )
		end


		it "has useful inspect output for SHOUT events" do
			message = 'Hey guys, who wants to play Valheim?'
			event = described_class.synthesize( :SHOUT,
				peer_uuid, group: 'CHANNEL1', msg: message,
				peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to include( 'CHANNEL1' )
			expect( event.inspect ).to match( / on /i )
			expect( event.inspect ).to include( message )
		end


		it "has useful inspect output for SILENT events" do
			event = described_class.synthesize( :SILENT, peer_uuid, peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to match( /isn't responding to pings/i )
		end


		it "has useful inspect output for STOP events" do
			event = described_class.synthesize( :STOP, peer_uuid )

			expect( event.inspect ).to match( /node is stopping/i )
		end


		it "has useful inspect output for WHISPER events" do
			target = SecureRandom.uuid
			message = "Hey #{target}, want to play Valheim?"
			event = described_class.synthesize( :WHISPER,
				peer_uuid, msg: message,
				peer_name: peer_name )

			expect( event.inspect ).to include( peer_uuid )
			expect( event.inspect ).to include( peer_name )
			expect( event.inspect ).to match( /whisper from/i )
			expect( event.inspect ).to include( message )
		end

	end


end

