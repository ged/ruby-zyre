#!/usr/bin/env rspec -cfd

require_relative 'spec_helper'

require 'zyre'


RSpec.describe( Zyre ) do


	# Pattern for matching IPv4 addresses
	IPV4_ADDRESS = /^((?:(?:^|\.)(?:\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])){4})$/


	it "knows what version of the underlying library it's using" do
		expect( described_class.zyre_version ).to be_a( Integer )
		expect( described_class.zyre_version ).to be >= 2_00_00
	end


	it "knows what broadcast-capable network interfaces are available" do
		result = described_class.interfaces
		expect( result ).to be_a( Hash )
		expect( result.size ).to be >= 1

		iface = result.keys.first
		expect( iface ).to match( /\A\p{Alpha}\S+\z/ )

		# :FIXME: This might be flaky for several reasons: no network interfaces,
		# first interface is IPv6, etc.
		expect( result[iface] ).to be_a( Hash ).
			and include( :address, :broadcast, :netmask )
		expect( result[iface][:address] ).to match( IPV4_ADDRESS )
		expect( result[iface][:broadcast] ).to match( IPV4_ADDRESS )
		expect( result[iface][:netmask] ).to match( IPV4_ADDRESS )
	end


	it "can normalize symbol-keyed headers into an RFC822-style string Hash" do
		headers = {
			protocol_version: 2,
			content_type: 'application/json',
			'disposition' => 'attachment'.b
		}
		result = described_class.normalize_headers( headers )

		expect( result ).to include( 'Protocol-version', 'Content-type', 'disposition' )
		expect( result['Protocol-version'] ).to eq( '2' )
		expect( result['Content-type'] ).to eq( 'application/json' )
		expect( result['disposition'] ).to eq( 'attachment' )
		expect( result['disposition'].encoding ).to eq( Encoding::US_ASCII )
	end


	it "can disable the CZMQ TERM/INT signal handler" do
		expect {
			described_class.disable_zsys_handler
		}.to_not raise_error()
	end


	it "knows whether or not it's been built with draft APIs" do
		expect( described_class.has_draft_apis? ).to eq( true ).or( eq false )
	end


	describe "Z85 encoding/decoding" do

		# From the 32/Z85 reference code:
		# https://github.com/zeromq/rfc/blob/master/src/spec_32.c
		let( :test_data_1 ) do
			[0x86, 0x4F, 0xD2, 0x6F, 0xB5, 0x59, 0xF7, 0x5B].pack('C*')
		end
		let( :test_data_2 ) do
			[
				0x8E, 0x0B, 0xDD, 0x69, 0x76, 0x28, 0xB9, 0x1D,
				0x8F, 0x24, 0x55, 0x87, 0xEE, 0x95, 0xC5, 0xB0,
				0x4D, 0x48, 0x96, 0x3F, 0x79, 0x25, 0x98, 0x77,
				0xB4, 0x9C, 0xD9, 0x06, 0x3A, 0xEA, 0xD3, 0xB7
			].pack('C*')
		end


		it "can round-trip an empty string" do
			result = described_class.z85_decode( described_class.z85_encode(''.b) )
			expect( result ).to eq( ''.b )
		end


		it "fails if the data to be encoded is not bounded at 4 bytes" do
			expect( described_class.z85_encode(test_data_1[0, 3]) ).to be_nil
		end


		it "can round-trip 4-byte-bounded data" do
			encoded = described_class.z85_encode( test_data_1 )

			expect( encoded ).to eq( 'HelloWorld' )
			expect( encoded.encoding ).to eq( Encoding::US_ASCII )

			decoded = described_class.z85_decode( encoded )

			expect( decoded ).to eq( test_data_1 )
			expect( decoded.encoding ).to eq( Encoding::ASCII_8BIT )
		end


		it "can round-trip a ZMQ Curve test key" do
			encoded = described_class.z85_encode( test_data_2 )

			expect( encoded ).to eq( 'JTKVSB%%)wK0E.X)V>+}o?pNmC{O&4W4b!Ni{Lh6' )
			expect( encoded.encoding ).to eq( Encoding::US_ASCII )

			decoded = described_class.z85_decode( encoded )

			expect( decoded ).to eq( test_data_2 )
			expect( decoded.encoding ).to eq( Encoding::ASCII_8BIT )
		end


		it "fails if the data to be decoded is not bounded at 5 bytes" do
			encoded = 'JTKVSB%%)wK0E.X)V>+}o?pNmC{O&4W4b!Ni{Lh6'

			expect( described_class.z85_decode(encoded[0..-2]) ).to be_nil
		end

	end

end

