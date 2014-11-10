# coding: utf-8

require 'rib/exceptions'
require 'rib/version'


module RIB

  autoload :Bot,            'rib/bot'
  autoload :Helpers,        'rib/helpers'
  autoload :Configuration,  'rib/configuration'
  autoload :Module,         'rib/module'
  autoload :Protocol,       'rib/protocol'
  autoload :MessageHandler, 'rib/message_handler'
  autoload :Message,        'rib/message'
  autoload :Connection,     'rib/connection'

end

