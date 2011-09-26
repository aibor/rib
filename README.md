Ruby IRCbot
===========

Simple IRCbot written for ruby 1.9


## Requirements

* ruby 1.9 (may run with other versions too)


## Installation

Put the folder where ever you want.
Done.


## Usage

### Configuration

There are two ways to pass the needed parameters to the bot:

1. Edit the file `config` in the main directory. The possible options are well commented.
1. Pass it as arguments at the start of the bot. See **Start** for additional information.

The essential options are:

* irc
* channel
* nick


### Start

Start the bot with

    rib [options]

If you have a proper `config` file you need no furter options. Otherwise the following options can be used:

        -i, --irc [HOSTNAME]             IRC Server to connect to
        -n, --nick [NICKNAME]            nickname for the bot
        -c, --channel [CHANNEL]          which channel to join
        -f, --file [CONFFILE]            read configuration from this file
        -d, --[no-]daemon                run as daemon?
        -h, --help                       Show a helpful message


Copyright
---------

See COPYING for details.
