#!/usr/bin/env rspec -cfd

require_relative '../spec_helper'

require 'securerandom'
require 'zyre/testing'


RSpec.describe( Zyre::Testing ) do


	UUID_PATTERN = /^(\h{32}|\h{8}-\h{4}-\h{4}-\h{4}-\h{12})$/

	ZEROMQ_EPHEMERAL_ADDR = %r|^tcp://\d+(\.\d+){3}:\d+|


	describe "EventFactory" do

		let( :described_class ) { Zyre::Testing::EventFactory }

		let( :factory ) do
			instance = described_class.new( peer_name: 'lancer-6' )
			instance.headers = { protocol_version: 2, content_type: 'application/messagepack' }
			instance.peer_addr = 'tcp://10.4.11.18:18559'

			return instance
		end


		it "can be created with reasonable defaults" do
			factory = described_class.new

			expect( factory ).to be_a( described_class )
			expect( factory.peer_addr ).to match( ZEROMQ_EPHEMERAL_ADDR )
			expect( factory.msg ).to eq( described_class.default_config[:msg] )

			expect( factory.peer_uuid ).to match( UUID_PATTERN )
			expect( factory.peer_name ).to match( 'S-' + factory.peer_uuid[0, 6] )

			expect( factory.headers ).to eq( described_class.default_headers )
		end


		it "can be created with overridden config values" do
			factory = described_class.new( peer_name: 'lancer-6' )

			expect( factory.peer_name ).to eq( 'lancer-6' )
			expect( factory.peer_addr ).to match( // )
			expect( factory.msg ).to eq( described_class.default_config[:msg] )

			expect( factory.headers ).to eq( described_class.default_headers )
		end


		it "can create a valid ENTER event" do
			event = factory.enter

			expect( event ).to be_a( Zyre::Event::Enter )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to eq({
				'Protocol-version' => '2',
				'Content-type' => 'application/messagepack'
			})
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid ENTER event with overridden config" do
			overridden_headers = factory.headers.merge( protocol_version: 3 )
			event = factory.enter( peer_name: 'lancer-6a', headers: overridden_headers )

			expect( event ).to be_a( Zyre::Event::Enter )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6a' )
			expect( event.headers ).to eq({
				'Protocol-version' => '3',
				'Content-type' => 'application/messagepack'
			})
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid JOIN event" do
			event = factory.join

			expect( event ).to be_a( Zyre::Event::Join )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to eq( 'default' )
		end


		it "can create a valid JOIN event with overridden config" do
			event = factory.join( group: 'control' )

			expect( event ).to be_a( Zyre::Event::Join )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to eq( 'control' )
		end


		it "can create a valid EVASIVE event" do
			event = factory.evasive

			expect( event ).to be_a( Zyre::Event::Evasive )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid EVASIVE event with overridden config" do
			uuid = SecureRandom.uuid.tr( '-', '' )
			event = factory.evasive( peer_uuid: uuid )

			expect( event ).to be_a( Zyre::Event::Evasive )
			expect( event.peer_uuid ).to eq( uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid SILENT event" do
			event = factory.silent

			expect( event ).to be_a( Zyre::Event::Silent )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid SILENT event with overridden config" do
			uuid = SecureRandom.uuid.tr( '-', '' )
			event = factory.silent( peer_uuid: uuid )

			expect( event ).to be_a( Zyre::Event::Silent )
			expect( event.peer_uuid ).to eq( uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid SHOUT event" do
			event = factory.shout

			expect( event ).to be_a( Zyre::Event::Shout )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to eq( 'A message.' )
			expect( event.group ).to eq( 'default' )
		end


		it "can create a valid SHOUT event with overridden config" do
			event = factory.shout( group: 'control', msg: 'stop' )

			expect( event ).to be_a( Zyre::Event::Shout )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to eq( 'stop' )
			expect( event.group ).to eq( 'control' )
		end


		it "can override SHOUT event message and group using positional parameters" do
			event = factory.shout( 'control', 'data1', 'data2' )

			expect( event ).to be_a( Zyre::Event::Shout )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to eq( 'data1' )
			expect( event ).to be_multipart
			expect( event.multipart_msg ).to eq( ['data1'.b, 'data2'.b] )
			expect( event.group ).to eq( 'control' )
		end


		it "can create a valid WHISPER event" do
			event = factory.whisper

			expect( event ).to be_a( Zyre::Event::Whisper )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to eq( 'A message.' )
			expect( event.group ).to be_nil
		end


		it "can create a valid WHISPER event with a multipart msg" do
			event = factory.whisper( msg: %w[three times fool] )

			expect( event ).to be_multipart
			expect( event.multipart_msg ).to eq( %w[three times fool] )
		end


		it "can create a valid WHISPER event with overridden config" do
			uuid = SecureRandom.uuid.tr( '-', '' )
			event = factory.whisper( peer_uuid: uuid, msg: 'stop' )

			expect( event ).to be_a( Zyre::Event::Whisper )
			expect( event.peer_uuid ).to eq( uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to eq( 'stop' )
			expect( event.group ).to be_nil
		end


		it "can override WHISPER event message using positional parameters" do
			event = factory.whisper( 'ignored', 'data1', 'data2' )

			expect( event ).to be_a( Zyre::Event::Whisper )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to eq( 'data1' )
			expect( event ).to be_multipart
			expect( event.multipart_msg ).to eq( ['data1', 'data2'] )
			expect( event.group ).to be_nil
		end


		it "can create a valid LEAVE event" do
			event = factory.leave

			expect( event ).to be_a( Zyre::Event::Leave )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to eq( 'default' )
		end


		it "can create a valid LEAVE event with overridden config" do
			event = factory.leave( group: 'control' )

			expect( event ).to be_a( Zyre::Event::Leave )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to eq( 'control' )
		end


		it "can create a valid LEADER event" do
			event = factory.leader

			expect( event ).to be_a( Zyre::Event::Leader )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to eq( 'default' )
		end


		it "can create a valid LEAVE event with overridden config" do
			event = factory.leader( group: 'control' )

			expect( event ).to be_a( Zyre::Event::Leader )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to eq( 'control' )
		end


		it "can create a valid STOP event" do
			event = factory.stop

			expect( event ).to be_a( Zyre::Event::Stop )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid EXIT event" do
			event = factory.exit

			expect( event ).to be_a( Zyre::Event::Exit )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-6' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end


		it "can create a valid EXIT event with overridden config" do
			event = factory.exit( peer_name: 'lancer-2' )

			expect( event ).to be_a( Zyre::Event::Exit )
			expect( event.peer_uuid ).to eq( factory.peer_uuid )
			expect( event.peer_name ).to eq( 'lancer-2' )
			expect( event.headers ).to be_empty
			expect( event.msg ).to be_nil
			expect( event.group ).to be_nil
		end

	end


end

