#!/usr/bin/env rspec -cfd

require_relative '../spec_helper'

require 'tempfile'

require 'zyre/cert'


RSpec.describe( Zyre::Cert ) do

	let( :cert_file ) { Tempfile.new('zyre_cert_test') }


	it "can be created in-memory" do
		expect( described_class.new ).to be_a( described_class )
	end


	it "can be created from a keypair" do
		cert = described_class.new

		result = described_class.from( cert.public_key, cert.private_key )

		expect( result ).to be_a( described_class )
		expect( result ).to eq( cert )
	end


	it "can be created from public key" do
		cert = described_class.new

		result = described_class.from_public( cert.public_key )

		expect( result ).to be_a( described_class )
		expect( result.public_txt ).to eq( cert.public_txt )
		expect( result.secret_txt ).to eq( Zyre::Cert::Z85_EMPTY_KEY )
	end


	it "can be saved to and loaded from a file" do
		cert = described_class.new
		cert.save( cert_file.path )

		result = described_class.load( cert_file.path )

		expect( result ).to be_a( described_class )
		expect( result ).to eq( cert )
	end


	it "can be saved as a public cert to and loaded from a file" do
		cert = described_class.new
		cert.save_public( cert_file.path )

		result = described_class.load( cert_file.path )

		expect( result ).to be_a( described_class )
		expect( result.public_key ).to eq( cert.public_key )
		expect( result.secret_key ).to eq( described_class::EMPTY_KEY )
	end


	it "can be saved as a secret cert to and loaded from a file" do
		cert = described_class.new
		cert.save_secret( cert_file.path )

		result = described_class.load( cert_file.path )

		expect( result ).to be_a( described_class )
		expect( result ).to eq( cert )
	end


	it "knows what its public key is" do
		cert = described_class.new

		key = cert.public_key

		expect( key.encoding ).to eq( Encoding::ASCII_8BIT )
		expect( key.bytesize ).to eq( 32 )
	end


	it "knows what its secret key is" do
		cert = described_class.new

		key = cert.secret_key

		expect( key.encoding ).to eq( Encoding::ASCII_8BIT )
		expect( key.bytesize ).to eq( 32 )
	end


	it "knows what its Z85-armored public key is" do
		cert = described_class.new

		key = cert.public_txt

		expect( key.encoding ).to eq( Encoding::US_ASCII )
		expect( key.length ).to eq( 40 )
	end


	it "knows what its Z85-armored secret key is" do
		cert = described_class.new

		key = cert.secret_txt

		expect( key.encoding ).to eq( Encoding::US_ASCII )
		expect( key.length ).to eq( 40 )
	end


	it "can set metadata on the cert" do
		cert = described_class.new

		cert[ :username ] = 'timmy'

		expect( cert['username'] ).to eq( 'timmy' )
	end


	it "stringifies non-string metadata on the cert" do
		cert = described_class.new

		cert[ :euid ] = 12

		expect( cert[:euid] ).to eq( '12' )
	end


	it "fetches non-existant values as nil" do
		cert = described_class.new

		expect( cert[:nonexistant_key] ).to be_nil
	end


	it "silently ignores overwrites of a metadata value if not built with Drafts", :no_czmq_draft_api do
		cert = described_class.new

		cert.set_meta( 'foo', 'bar' )
		cert.set_meta( 'foo', 'baz' )

		expect( cert.meta('foo') ).to eq( 'bar' )
	end


	it "can overwrite a metadata value if built with Drafts", :czmq_draft_api do
		cert = described_class.new

		cert.set_meta( 'foo', 'bar' )
		cert.set_meta( 'foo', 'baz' )

		expect( cert.meta('foo') ).to eq( 'baz' )
	end


	it "knows what metadata has been set on the cert" do
		cert = described_class.new

		cert[ :euid ]      = 0
		cert[ :username ]  = 'jrandom'
		cert[ 'firstname' ] = 'James'
		cert[ :lastname ]  = 'Random'
		cert[ 'key 2' ] = 'cf67c750-c704-4ef7-ab83-ecb2cd2e326c'

		expect( cert.meta_keys ).
			to contain_exactly( 'euid', 'username', 'firstname', 'lastname', 'key 2' )
	end


	it "can delete one of its metadata key-value pairs", :czmq_draft_api do
		cert = described_class.new

		cert[ :euid ]      = 0
		cert[ :username ]  = 'jrandom'
		cert[ 'firstname' ] = 'James'
		cert[ :lastname ]  = 'Random'
		cert[ 'key 2' ] = 'cf67c750-c704-4ef7-ab83-ecb2cd2e326c'

		cert.delete( 'lastname' )

		expect( cert.meta_keys ).
			to contain_exactly( 'euid', 'username', 'firstname', 'key 2' )
	end


	it "can return all of its metadata as a Hash" do
		cert = described_class.new

		cert[ :euid ]      = 0
		cert[ :username ]  = 'jrandom'
		cert[ 'firstname' ] = 'James'
		cert[ :lastname ]  = 'Random'
		cert[ 'key 2' ] = 'cf67c750-c704-4ef7-ab83-ecb2cd2e326c'

		expect( cert.meta_hash ).to eq({
			'euid'      => '0',
			'username'  => 'jrandom',
			'firstname' => 'James',
			'lastname'  => 'Random',
			'key 2'     => 'cf67c750-c704-4ef7-ab83-ecb2cd2e326c',
		})
	end


	it "can be applied to a Zyre node", :draft_apis do
		node = instance_double( Zyre::Node )
		cert = described_class.new

		expect( node ).to receive( :zcert= ).with( cert )
		cert.apply( node )
	end


	it "can be duplicated" do
		cert = described_class.new
		cert[ :node_id ] = '05343500-f908-4903-9441-e648eb1754ec'
		cert[ :node_order ] = 1

		other = cert.dup

		expect( other.object_id ).not_to eq( cert.object_id )
		expect( other[:node_id] ).to eq( cert[:node_id] )
		expect( other[:node_order] ).to eq( cert[:node_order] )
	end


end
