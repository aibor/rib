RIB - Ruby IRC (and XMPP) Bot
=============================

Simple IRC and XMPP bot framework written in Ruby.


## Requirements

* Ruby (tested with 2.1, but might work with others too)
* xmpp4r gem for XMPP connections


## Usage

### Installation

#### Using [Bundler](http://bundler.io/):

Create a Gemfile like this:

    source "https://rubygems.org"
    gem 'rib', git: 'https://github.com/aibor/rib.git'

Then run:

    $ bundle install

#### Building Gem yourself

Clone the Repository, move into the repository's root directory and run:

    $ gem build rib.gemspec
    $ gem install rib-<VERSION>.gem


### Configuration

Take a look at the files starting with `rib-` in the directory
`examples`. These are examples for the configuration of
the bot and the definition of your desired triggers and responses.

The mandatory options are:

* protocol  (:irc or :xmpp)
* server    (hostname to connect to)
* channel   (space separated list of channels to join)
additionally for XMPP connections:
* jid       (JID for the bot to authticate as)
* auth      (password for the JID)

Add `bot.ssl.use = true` to your config in order to use SSL when connecting
to a server.

All other options are optional and have more or less sane defaults.
However, you might want to add some module names to the `modules`
configuration directive, as the bot won't do much without any modules
registered.


### Quick Start

Copy one of the exmaples in `examples/` into this directory, edit
server, channel and admin and start it:

    $ ruby rib-irc


### Interaction

RIB knows two kinds of actions.

#### Commands

Commands can be called by preceding them with the trigger character
(tc), which defaults to `!`.

    !list
    !help list


#### Triggers

The bot responds, if a message matches the `trigger` attribute,
which is a regular expression. They are very similar to Commands and
differ only in the way they are triggered.


### Writing Modules

Commands and Triggers are defined in RIB::Modules. These are Ruby
classes which inherit from RIB::Module. Any public instance method
defined in that class is a command, which can be called as mentioned
bove. Triggers are defined by their passing a regexp and a block to the
`trigger` method. The block will be evaluated in the instance scope, so
any public and private methods can be called from within the block.
The block will be passed the `MatchData` object that has been received
on evaluating the regular expression and so it can be used to access
capture groups.

A very basic Module would look like this:

  class MyTimeModule < RIB::Module

    desc 'get the current time'

    def time
      Time.new.to_s
    end

    trigger(/awesome (\w*)/) { |match| "#{match[1]} is truly awesome!" }

  end

See `lib/rib/modules/` for examples.


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

