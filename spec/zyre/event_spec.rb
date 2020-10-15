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

end

