#!/usr/bin/env ruby -S rake

require 'rake/deveiate'
require 'rake/extensiontask'

DLEXT    = RbConfig::CONFIG['DLEXT']

EXTCONFS = Rake::FileList[ (Rake::DevEiate::EXT_DIR + '*/extconf.rb').to_s ]
EXTS     = EXTCONFS.pathmap( '%d/%-1d_ext.so' )

ENV['RUBY_CC_VERSION'] = '2.7'


Rake::DevEiate.setup( 'zyre' ) do |project|
	project.publish_to = 'deveiate:/usr/local/www/public/code'
end


#
# Extensions
#
task spec: :compile

desc "Turn on warnings and debugging in the build."
task :maint do
	ENV['MAINTAINER_MODE'] = 'yes'
end

task compile: :gemspec
EXTCONFS.each do |extconf|
	Rake::ExtensionTask.new( extconf.pathmap('%-1d') )
end

