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

	end

end

