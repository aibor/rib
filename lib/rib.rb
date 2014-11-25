# coding: utf-8



module RIB

  autoload :Bot,            'rib/bot'
  autoload :Exceptions,     'rib/exceptions'
  autoload :Helpers,        'rib/helpers'
  autoload :Configuration,  'rib/configuration'
  autoload :Module,         'rib/module'
  autoload :ModuleSet,      'rib/module_set'
  autoload :MessageHandler, 'rib/message_handler'
  autoload :Message,        'rib/message'
  autoload :Connection,     'rib/connection'
  autoload :Command,        'rib/command'
  autoload :Trigger,        'rib/trigger'
  autoload :VERSION,        'rib/version'

  include Exceptions

end

