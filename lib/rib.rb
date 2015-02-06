# coding: utf-8



module RIB

  module Adapters
    PATH = "rib/adapters"
  end

  autoload :Bot,              'rib/bot'
  autoload :Backlog,          'rib/backlog'
  autoload :Exceptions,       'rib/exceptions'
  autoload :NameConvertable,  'rib/name_convertable'
  autoload :Configuration,    'rib/configuration'
  autoload :Module,           'rib/module'
  autoload :ModuleSet,        'rib/module_set'
  autoload :MessageHandler,   'rib/message_handler'
  autoload :Message,          'rib/message'
  autoload :Connection,       'rib/connection'
  autoload :Adaptable,        'rib/adaptable'
  autoload :Command,          'rib/command'
  autoload :VERSION,          'rib/version'

  include Exceptions

end

