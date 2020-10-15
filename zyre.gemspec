# -*- encoding: utf-8 -*-
# stub: zyre 0.1.0.pre.20201014130418 ruby lib

Gem::Specification.new do |s|
  s.name = "zyre".freeze
  s.version = "0.1.0.pre.20201014130418"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://deveiate.org/code/rbzyre/History_md.html", "documentation_uri" => "https://deveiate.org/code/rbzyre", "homepage_uri" => "https://gitlab.com/ravngroup/open-source/ruby-zyre", "source_uri" => "https://gitlab.com/ravngroup/open-source/ruby-zyre/-/tree/master" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2020-10-14"
  s.description = "This is a Ruby (MRI) binding for the Zyre library for reliable group messaging over local area networks.".freeze
  s.email = ["ged@faeriemud.org".freeze]
  s.files = ["History.md".freeze, "LICENSE.txt".freeze, "README.md".freeze, "ext/zyre_ext/event.c".freeze, "ext/zyre_ext/node.c".freeze, "ext/zyre_ext/poller.c".freeze, "ext/zyre_ext/zyre_ext.c".freeze, "ext/zyre_ext/zyre_ext.h".freeze, "lib/zyre.rb".freeze, "lib/zyre/event.rb".freeze, "lib/zyre/node.rb".freeze, "lib/zyre/poller.rb".freeze, "spec/spec_helper.rb".freeze, "spec/zyre/event_spec.rb".freeze, "spec/zyre/node_spec.rb".freeze, "spec/zyre/poller_spec.rb".freeze, "spec/zyre_spec.rb".freeze]
  s.homepage = "https://gitlab.com/ravngroup/open-source/ruby-zyre".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "This is a Ruby (MRI) binding for the Zyre library for reliable group messaging over local area networks.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.17"])
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.14", ">= 0.14.1"])
    s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.91"])
    s.add_development_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.4"])
    s.add_development_dependency(%q<simplecov-cobertura>.freeze, ["~> 1.4"])
    s.add_development_dependency(%q<observability>.freeze, ["~> 0.3"])
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.17"])
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.14", ">= 0.14.1"])
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.91"])
    s.add_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.4"])
    s.add_dependency(%q<simplecov-cobertura>.freeze, ["~> 1.4"])
    s.add_dependency(%q<observability>.freeze, ["~> 0.3"])
  end
end
