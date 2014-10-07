RIB - Ruby IRC (and XMPP) Bot
=============================

Simple IRC and XMPP bot framework written in Ruby.


## Requirements

* Ruby (tested with 1.9.3, 2.0.0, 2.1.2)
* xmpp4r gem for XMPP connections


## Usage

### Configuration

Take a look at the file `rib`. It is an example for the configuration of
the bot and the definition of your desired triggers and responses.

The mandatory options are:

* protocol  (:irc or :xmpp)
* server    (hostname to connect to)
* channel   (space separated list of channels to join)
additionally for XMPP connections:
* jid       (JID for the bot to authticate as)
* auth      (password for the JID)

All other options are optional and have more or less sane defaults.
However, you might want to add some module names to the `modules`
configuration directive, as the bot won't do much without any modules
registered.


### Quick Start

Copy one of the exmaples in `examples/` into this directory, edit
server, channel and admin and start it:

    $ ruby rib-irc


### Interaction

RIB knows three kinds of actions.

#### Commands

Commands can be called with preceding them with the trigger character
(tc), which defaults to `!`.

    !list
    !help list


#### Responses

Responses trigger, if a message matches their `trigger` attribute,
which is a regular expression. They are very similar to Commands and
differ only in the way they are triggered.


#### Replies

Replies are just simple strings that are responded if their name is
called. Several strings can belong to a single name. If just the name
is given, then a random one will be picked. If a number is passed the
reply with this number will be returned.

Replies are stored in a YAML file, which can be configured with the
`replies` configuration directive. They can be managed directly via
this file or via the Bot's `reply` command.


### Writing Modules

Commands and Responses are defined in Modules. RIB provides a simple
DSL for writing these Modules. A very basic Module
would look like this:

  RIB::Module.new :time do
    desc 'Time related commands'

    command :time do
      desc 'get the current time'
      on_call do
        Time.new.to_s
      end
    end

  end

See `lib/rib/module.rb` for available commands and the modules directory
for more examples.


## Contribution

Bug reports, feature requests, rants and code mocking are highly
welcome. Just open a Issue/Ticket or contact me directly.


## Copyright

GPLv2 license can be found in `LICENSE`


Copyright (C) 2011-2014    Tobias Böhm <code@aibor.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
