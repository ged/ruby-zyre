# -*- encoding: utf-8 -*-
# stub: zyre 0.8.0.pre.20250805115944 ruby lib
# stub: ext/zyre_ext/extconf.rb

Gem::Specification.new do |s|
  s.name = "zyre".freeze
  s.version = "0.8.0.pre.20250805115944".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://deveiate.org/code/zyre/History_md.html", "documentation_uri" => "https://deveiate.org/code/zyre", "homepage_uri" => "https://gitlab.com/ravngroup/open-source/ruby-zyre", "source_uri" => "https://gitlab.com/ravngroup/open-source/ruby-zyre/-/tree/master" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2025-08-05"
  s.description = "A ZRE library for Ruby. This is a Ruby (MRI) binding for the Zyre library for reliable group messaging over local area networks, an implementation of the ZeroMQ Realtime Exchange protocol.".freeze
  s.email = ["ged@faeriemud.org".freeze]
  s.extensions = ["ext/zyre_ext/extconf.rb".freeze]
  s.files = ["Authentication.md".freeze, "History.md".freeze, "LICENSE.txt".freeze, "README.md".freeze, "ext/zyre_ext/cert.c".freeze, "ext/zyre_ext/event.c".freeze, "ext/zyre_ext/extconf.rb".freeze, "ext/zyre_ext/node.c".freeze, "ext/zyre_ext/poller.c".freeze, "ext/zyre_ext/zyre_ext.c".freeze, "ext/zyre_ext/zyre_ext.h".freeze, "lib/observability/instrumentation/zyre.rb".freeze, "lib/zyre.rb".freeze, "lib/zyre/cert.rb".freeze, "lib/zyre/event.rb".freeze, "lib/zyre/event/enter.rb".freeze, "lib/zyre/event/evasive.rb".freeze, "lib/zyre/event/exit.rb".freeze, "lib/zyre/event/join.rb".freeze, "lib/zyre/event/leader.rb".freeze, "lib/zyre/event/leave.rb".freeze, "lib/zyre/event/shout.rb".freeze, "lib/zyre/event/silent.rb".freeze, "lib/zyre/event/stop.rb".freeze, "lib/zyre/event/whisper.rb".freeze, "lib/zyre/node.rb".freeze, "lib/zyre/poller.rb".freeze, "lib/zyre/testing.rb".freeze, "spec/observability/instrumentation/zyre_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/zyre/cert_spec.rb".freeze, "spec/zyre/event_spec.rb".freeze, "spec/zyre/node_spec.rb".freeze, "spec/zyre/poller_spec.rb".freeze, "spec/zyre/testing_spec.rb".freeze, "spec/zyre_spec.rb".freeze]
  s.homepage = "https://gitlab.com/ravngroup/open-source/ruby-zyre".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.6.9".freeze
  s.summary = "A ZRE library for Ruby.".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.18".freeze, ">= 0.18.2".freeze])
  s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.22".freeze])
  s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.91".freeze])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.4".freeze])
  s.add_development_dependency(%q<simplecov-cobertura>.freeze, ["~> 1.4".freeze])
  s.add_development_dependency(%q<observability>.freeze, ["~> 0.3".freeze])
  s.add_development_dependency(%q<rspec-wait>.freeze, ["~> 0.0".freeze])
end
