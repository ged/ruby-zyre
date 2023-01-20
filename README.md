# Ruby Zyre

home
: https://gitlab.com/ravngroup/open-source/ruby-zyre

code
: https://gitlab.com/ravngroup/open-source/ruby-zyre/-/tree/master

github
: https://github.com/ged/ruby-zyre

docs
: https://deveiate.org/code/zyre


## Description

A ZRE library for Ruby. This is a Ruby (MRI) binding for the Zyre library for
reliable group messaging over local area networks, an implementation of [the ZeroMQ Realtime Exchange protocol][ZRE].


### Examples

Zyre is a P2P library which has two modes: pub/sub and direct messaging. To use it, you create a node, optionally join some groups (subscribing), and start it. Then you can send broadcast messages to all other nodes in a group, or direct messages to a particular node.

This example joins the Zyre network and dumps messages it sees in the 'global' group to stderr:

    node = Zyre::Node.new
    node.join( 'global' )
    node.start

    node.each_event do |event|
      event.print
    end

To send a direct message to a different node you need to know its `UUID`. There are number of ways to discover this:

    # The UUIDs of all connected peers
    node.peers
    # The UUIDs of all the peers which have joined the `general` group
    node.peers_by_group( 'general' )
    # The UUID of the peer that sent the event
    received_event.peer_uuid

You read events from the network with the Zyre::Node#recv method, but it blocks until an event arrives:

    event = node.recv

You can also iterate over arriving events:

    node.each do |event|
        ...
    end

or use Zyre::Node#each as an Enumerator:

    five_events = node.each_event.take( 5 )

You can also wait for a certain type of event:

    event = node.wait_for( :SHOUT )

and time out if it doesn't arrive within a certain length of time:

    event = node.wait_for( :ENTER, timeout: 2.0 ) or
        raise "No one else on the network!"

You can join a group with Zyre::Node#join:

    node.join( 'alerts' )

and you can detect other nodes joining one of your groups by looking for JOIN events (Zyre::Event::Join objects):

    node.wait_for( :JOIN )

You can publish a message to all nodes in a group with Zyre::Node#shout:

    node.shout( "group1", "This is a message." )

and read it:

    event = other_node.recv
    event.is_multipart?  # => false
    event.msg            # => "This is a message."
    event.multipart_msg  # => ["This is a message."]


Or publish a message with multiple parts:

    node.shout( "group1", 'message.type', "This is a message." )

and read it:

    event = other_node.recv
    event.is_multipart?  # => true
    event.msg            # => "message.type"
    event.multipart_msg  # => ["message.type", "This is a message."]


### To-Do

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
[project page](https://gitlab.com/ravngroup/open-source/ruby-zyre).

After checking out the source, run:

    $ gem install -Ng
    $ rake setup

This will install dependencies, and do any other necessary setup for
development.


## Authors

- Michael Granger <ged@faeriemud.org>


## License

This project includes code adapted from the ZeroMQ RFC project, used under
the following license:

> Copyright (c) 2010-2013 iMatix Corporation and Contributors
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of
> this software and associated documentation files (the "Software"), to deal in
> the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
> the Software, and to permit persons to whom the Software is furnished to do so,
> subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
> FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
> COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
> IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
> CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Everything else is:

Copyright (c) 2020-2023, Ravn Inc
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


[ZRE]: https://rfc.zeromq.org/spec/36/

