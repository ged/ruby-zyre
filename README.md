# Ruby Zyre

home
: https://gitlab.com/ravngroup/open-source/ruby-zyre

code
: https://gitlab.com/ravngroup/open-source/ruby-zyre/-/tree/master

docs
: https://deveiate.org/code/rbzyre


## Description

This is a Ruby (MRI) binding for the Zyre library for reliable group messaging
over local area networks.


### Examples

    # Join the Zyre network on the network associated with the given interface
    # and dump events from the 'global' group to stderr.
    node = Zyre::Node.new
    node.interface = 'igb0'
    node.start
    
    while event = node.recv
      event.print
    end


### To-Do

* Implement Zyre::Node#peer_groups and Zyre::Node#peer_address
* Implement the draft API methods on Zyre::Node
* Hook up logging via `zsys_set_logsender`
* Add richer matching to Zyre::Event#match.

## Prerequisites

* Ruby 2.7+
* Zyre (https://github.com/zeromq/zyre)


## Installation

    $ gem install zyre


## Contributing

You can check out the current development source with Mercurial via its
[project page](http://bitbucket.org/ged/rbzyre). Or if you prefer Git, via
[its Github mirror](https://github.com/ged/rbzyre).

After checking out the source, run:

    $ gem install -Ng
    $ rake setup

This will install dependencies, and do any other necessary setup for
development.


## Authors

- Michael Granger <ged@faeriemud.org>


## License

Copyright (c) 2020, Ravn Group
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


