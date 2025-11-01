# -*- ruby -*-

require_relative '../spec_helper'

require 'pathname'
require 'tmpdir'
require 'zyre/certstore'


RSpec.describe( Zyre::Certstore ) do

	let( :certstore_location ) { Pathname(Dir::Tmpname.create(['zyre-cerstore-', '-spec']) {}) }


	it "can be created as an in-memory store" do
		instance = described_class.new

		expect( instance ).to be_a( described_class )
	end


	it "can be created with a directory name" do
		instance = described_class.new( certstore_location )

		expect( instance ).to be_a( described_class )
	end


	it "can have certs added to it" do
		instance = described_class.new

		cert = Zyre::Cert.new
		cert[:name] = 'test1'

		instance.insert( cert )

		res = instance.lookup( cert.public_txt )
		expect( res ).to be_a( Zyre::Cert )
		expect( res.public_txt ).to eq( cert.public_txt )
		expect( res[:name] ).to eq( 'test1' )
	end


	it "can lookup certs added to a directory certstore" do
		certstore_location.mkpath
		instance = described_class.new( certstore_location )

		cert = Zyre::Cert.new
		cert[:name] = 'test23'
		cert.save_public( certstore_location / 'mykey.txt' )

		res = instance.lookup( cert.public_txt )

		expect( res ).to be_a( Zyre::Cert )
		expect( res.public_txt ).to eq( cert.public_txt )
		expect( res[:name] ).to eq( 'test23' )
	end

end

