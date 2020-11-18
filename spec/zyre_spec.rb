#!/usr/bin/env rspec -cfd

require_relative 'spec_helper'

require 'zyre'


RSpec.describe Zyre do


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


	it "knows whether or not it's been built with draft APIs" do
		expect( described_class.has_draft_apis? ).to eq( true ).or( eq false )
	end

end

