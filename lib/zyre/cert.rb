# -*- ruby -*-

require 'loggability'

require 'zyre' unless defined?( Zyre )


#--
# See also: ext/zyre_ext/cert.c
class Zyre::Cert
	extend Loggability


	# The placeholder key that is set as the secret key for a public certificate.
	EMPTY_KEY = "\x00" * 32


	# Use the Zyre module's logger
	log_to :zyre


	# Set up some more Rubyish aliases
	alias_method :private_key, :secret_key
	alias_method :==, :eql?


	### Fetch the value for the cert metadata with the given +name+.
	def []( name )
		return self.meta( name.to_s )
	end


	### Set the value for the cert metadata with the given +name+ to +value+.
	def []=( name, value )
		return self.set_meta( name.to_s, value.to_s )
	end


	### Return the metadata from the cert as a Hash.
	def meta_hash
		hash = self.meta_keys.each_with_object( {} ) do |key, h|
			h[ key ] = self[ key ]
		end
		hash.freeze
		return hash
	end


	### Delete the value for the cert metadata with the given +name+. Requires
	### CZMQ to have been built with Draft APIs.
	def delete( name )
		name = name.to_s

		deleted_val = self[ name ]
		self.unset_meta( name )

		return deleted_val
	end


	### Returns +true+ if the certificate has a secret key.
	def have_secret_key?
		return self.secret_key != EMPTY_KEY
	end


	### Apply the certificate to the specified +zyre_node+, i.e. use the
	### cert for CURVE security. If the receiving certificate doesn't have a
	### private key, an exception will be raised.
	def apply( zyre_node )
		return zyre_node.zcert = self
	end

end # class Zyre::Cert
