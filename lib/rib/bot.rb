# coding: utf-8

require 'logger'
require 'yaml'
require 'rib/configuration.rb'
require 'rib/exceptions.rb'
require 'rib/module'


module RIB

  ##
  # Main class for initializing and handling the connection after
  # reading the configuration and loading {#load_protocol_module
  # protocol handler}, the {#load_replies replies} and the
  # {#load_modules Command and Response Modules}.
  # Based on the configuration, the Ruby modules for the appropriate
  # protocol are loaded. This means the Bot behaves slightly differently
  # for each protocol. Available protocols are defined in `protocols`
  # direcotry.
  # Since {Module Modules}, {Command Commands} and {Response Responses}
  # can be limited to specific protocols, on invocation are only those
  # loaded which match the Bot instance's protocol.
  #
  # @example Basic Bot configuration
  #   require 'rib'
  #
  #   rib = RIB::Bot.new do |bot|
  #     bot.protocol  = :irc
  #     bot.server    = 'irc.quakenet.org'
  #     bot.port      = 6667
  #     bot.channel   = '#rib'
  #     bot.admin     = 'ribmaster'
  #     bot.modules   = [:core, :fun]
  #   end
  #
  #   rib.run
  #
  # @see Configuration Available configuration options

  class Bot

    ##
    # The Bot instance's {Configuration} object.
    #
    # @return [Configuration]

    attr_accessor :config


    ##
    # All loaded Modules for this Bot instance matching the bot's
    # protocol.
    #
    # @return [Array<Module>]

    attr_reader :modules


    ##
    # Replies currently available. These will be loaded on boot from
    # the YAML file set in {Configuration#replies_file}, if readable, and
    # can then be modified by {#add_reply} and {#delete_reply}.
    #
    # @return [Hash{String => Array<String>}]

    attr_reader :replies


    ##
    # Boot time of the Bot instance. useful for calculating running
    # time.
    #
    # @return [Time]

    attr_reader :starttime


    ##
    # Connection Class object of the Bot instance depending on the Bot
    # instance's protocol. For example
    # {RIB::Protocol::IRC::Connection}.
    #
    # @return [Connection]

    attr_reader :connection


    ##
    # Create a new Bot instance. Configuration can be done via a passed
    # block directly or later on.
    #
    # @example with block
    #   rib = RIB::Bot.new do |bot|
    #     bot.protocol  = :irc
    #     bot.server    = 'irc.freenode.net'
    #     # ...
    #   end
    #
    # @example without block
    #   rib = RIB::Bot.new
    #
    #   rib.config.protocol  = :irc
    #   rib.config.server    = 'irc.freenode.net'
    #   # ...
    #
    # @see #configure
    #
    # @yield [config]

    def initialize(&block)
      @config = Configuration.new

      configure &block if block_given?
    end


    ##
    # Configure the Bot instance via a block, if it isn't running yet.
    #
    # @example
    #   rib = RIB::Bot.new
    #
    #   rib.configure do |bot|
    #     bot.protocol  = :irc
    #     bot.server    = 'irc.freenode.net'
    #     # ...
    #   end
    #
    # @yield [config]

    def configure(&block)
      yield @config
    end


    ##
    # Get all {Command Commands} which are available for the Bot
    # instance's protocol.
    #
    # @return [Array<Command>]

    def commands
      @modules.map(&:commands).flatten.select do |command|
        command.speaks? @config.protocol
      end
    end


    ##
    # Get all {Response Responses} which are available for the Bot
    # instance's protocol.
    #
    # @return [Array<Response>]

    def responses
      @modules.map(&:responses).flatten.select do |response|
        response.speaks? @config.protocol
      end
    end


    ##
    # After the bot irs configured and request handlers have been
    # loaded, the bot can initialize the connection and go into
    # its infinite loop.
    #
    # @return [void]

    def run
      init_log # Logfile for the instance. NOT IRC log!
      begin

        @starttime = Time.new

        set_signals

        load_protocol_module
        load_modules
        load_replies
        init_server

        run_loop
      rescue => e
        @log.fatal($!)
      ensure
        @log.info("EXITING")
        @log.close
      end
    end


    ##
    # Output a message to a target (a user or channel). This calls the
    # #server_say method of the loaded {Protocol} module.
    #
    # @param [String] text    message to send, if multiline, then each
    #   line will be sent separately.
    # @param [String] target  receiver of the message, a user or channel
    #
    # @return [nil]

    def say(text, target)
      return if text.nil?
      text.split('\n').each do |line|
        next if line.empty?
        server_say line, target
      end
    end


    ##
    # Reload all modules. This is basically an alias to {#load_modules},
    # but catches and logs Exceptions. That's why it can be used for a
    # running instance, for example from {Command Commands} without
    # the possibility to kill the application, if {Module Modules} have
    # syntax errors or other issues.
    #
    # @return [Array<Modul>] if successful
    # @return [FalseClass] if an exception was raised

    def reload_modules
      load_modules
    rescue => e
      @log.error 'Exception catched while reloading modules:'
      @log.error e
      false
    end


    ##
    # Reload replies from file. This is basically an alias to
    # {#load_replies}, but catches and logs Exceptions. That's why it
    # can be used for a running instance, for example from {Command
    # Commands} without the possibility to kill the application, if
    # the {Configuration#replies_file} isn't valid YAML or other
    # issues arise.
    #
    # @return [Hash{String => Array<String>}] if successful
    # @return [FalseClass] if an exception was raised

    def reload_replies
      load_replies
    rescue => e
      @log.error 'Exception catched while reloading replies:'
      @log.error e
      false
    end


    ##
    # Add a reply to the replies Hash. Intended to be used from
    # {Command Commands} while running. On success the current replies
    # Hash will be saved to the {Configuration#replies_file}.
    #
    # @param [String] trigger name of the trigger to add a value for
    # @param [String] value   String to add to the trigger's value array
    #
    # @return [Fixnum] length of written bytes on success
    # @return [FalseClass] if something went wrong

    def add_reply(trigger, value)
      return false unless reply_validation.call(trigger, value.to_s)

      @replies[trigger] = [@replies[trigger], value].flatten.compact
      save_replies
    end


    ##
    # Delete a reply from the replies Hash. Intended to be used from
    # {Command Commands} while running. On success the current replies
    # Hash will be saved to the {Configuration#replies_file}.
    #
    # @param [String] trigger name of the trigger to delete a value
    #                         from
    # @param [Fixnum] index   index to delete from the trigger's value
    #                         array
    #
    # @return [Fixnum] length of written bytes on success
    # @return [FalseClass] if something went wrong

    def delete_reply(trigger, index)
      return false unless @replies[trigger] and @replies[trigger][index]

      @replies[trigger].delete_at(index)
      save_replies
    end


    private

    ##
    # Catch some signals and close the connection gracefully, if it is
    # established already
    #
    # @raise [RuntimeError]
    #
    # @return [void]

    def set_signals
      %w(INT TERM).each do |signal|
        Signal.trap(signal) do
          @log.warn"SIG#{signal} catched. Terminating."
          self.connection.quit(self.config.qmsg) if self.connection
        end
      end
    end


    ##
    # Depending on the protocol the Bot instance has configured, the
    # appropriate {Protocol} module has to be loaded for connection
    # handling. The Module name has to be te protocol name upcase and
    # has to be stored in a file with its name downcase with '.rb'
    # extension. Otherwise an exception is raised.
    #
    # @raise [LoadError] if file cannot be loaded
    # @raise [UnknownProtocolError] if no matching module is found
    #
    # @return[Bot]

    def load_protocol_module
      protocol_path = "rib/protocol/#{@config.protocol}"

      require protocol_path

      extend RIB::Protocol.const_get(@config.protocol.to_s.upcase)
    rescue NameError
      raise UnknownProtocolError.new(@config.protocol)
    end


    ##
    # Build the path to the log directory depending on the value of
    # {Configuration#logdir}.
    #
    # @return [String] path to log directory

    def log_path
      file_path =  File.expand_path('..', $0)
      file_path << @config.logdir.sub(/\A\/?(.*?)\/?\z/, '/\1/')
    end


    ##
    # Build the path to the log file based on several {Configuration}
    # values for sane log file naming.
    #
    # @return [String] path of the log file

    def log_file_path
      log_path +
        "#{File.basename($0)}_#{@config.protocol}_#{@config.server}.log"
    end


    ##
    # Initialize the instance's logging instance. If
    # {Configuration#debug} is true, logging will be more verbose and
    # logs will go to STDOUT instead of a log file.
    #
    # @return [Fixnum] log level

    def init_log
      destination, level =
        if @config.debug
          [STDOUT, Logger::DEBUG]
        else
          [log_file_path, Logger::INFO]
        end

      @log = Logger.new(destination)
      @log.level = level
    end


    ##
    # Load {Module Modules} in `path` and return all {Module Modules}
    # that can handle the Bot instance's protocol
    #
    # @param [String] path to load files from
    #
    # @return [Array<Module>] successfully loaded {Module Modules}

    def get_unique_modules_form_path(path)
      return [] if path.nil?

      Module.load_path path

      Module.loaded.select do |mod|
        @config.modules.include?(mod.name) && mod.speaks?(@config.protocol)
      end
    end


    ##
    # Load all modules in a file or a directory. At first the library's
    # {Module Modules} are loaded from `rib/modules/` directory and
    # then user modules - specified in {Configuration#modules_dir} -
    # are loaded. This ensures, that the core {Module Modules} commands
    # are preferred in case of naming collisions.
    #
    # @return [Array<Module>] all Modules for this Bot instance's
    #   protocol

    def load_modules
      @modules = get_unique_modules_form_path("modules/*.rb")
      @modules += get_unique_modules_form_path(@config.modules_dir)
      @modules.each { |mod| mod.init(self) }
    end


    ##
    # Load the replies from the file specified in
    # {Configuration#replies_file}.
    #
    # @return [Hash{String => Array<String>] all loaded replies

    def load_replies
      hash = YAML.load_file(@config.replies_file)

      @replies = hash.select &reply_validation
      sanitize_replies
    end


    ##
    # Replies should be stored alphabetically with values as array.
    # Empty triggers and values are removed.
    #
    # @return [Hash{String => Array<String>] all loaded replies

    def sanitize_replies
      @replies = @replies.sort.inject({}) do |hash, (key, value)|
        value.compact! if value.respond_to?(:compact)
        hash[key] = [value].flatten if value && !value.empty?
        hash
      end
    end


    ##
    # Write the current {#replies} Hash to the file specified in
    # {Configuration#replies_file}.
    #
    # @return [Fixnum] bytes written if successful
    # @return [FalseClass] if the file isn't writeable

    def save_replies
      sanitize_replies

      if File.writable?(@config.replies)
        File.write(@config.replies, @replies.to_yaml)
      else
        false
      end
    end


    ##
    # Lambda function for Validation of a trigger name and its value.
    # First argument must be a String, second argumwnt must be a String
    # or an Array of Strings.
    #
    # This is intended to be used for direct invocation or for passing
    # it to an Enumerator.
    #
    # @example for a single pair
    #   reply_validation.call('moo', 'mooo000ooo')
    #
    # @example with Enumerator
    #   hash = {'one' => 'silence', 'two' => 3}
    #   hash.select &reply_validation #=> {'one' => 'silence'}
    #
    # @return [Proc (lambda)] validation lambda function

    def reply_validation
      ->(name, value) do
        return false unless name.is_a? String

        if value.is_a? Array
          value.all? { |element| element.is_a? String }
        else
          value.is_a?(String)
        end
      end
    end


    ##
    # Start IRC Connection, authenticate and join all channels.
    #
    # @return [void]

    def init_server
      @log.info "Server starts"

      @connection = init_connection

      # Once the connection is established and the motd is done, all
      # further suff hould be logged
      @connection.togglelogging

      @connection.login
      @connection.auth_nick @config.auth if @config.defined?(:auth)

      join_channels

      # make the bot aware of himself
      @connection.setme @config.nick
    end


    ##
    # Iterate through channel list and join all of them.
    #
    # @return [void]

    def join_channels
      @config.channel.split( /\s+|\s*,\s*/ ).each do |chan|
        @connection.join_channel( chan )
        @log.info("Connected to #{@config.server} as #{@config.nick} in #{chan}")
      end
    end


    ##
    # For each received message, check if it matches an Action the instance
    # has loaded. If a matching {Command}, {Response} or Reply is found,
    # process it.
    #
    # @!macro handler_tags
    #   @param [Hash] msg values that should be available in the Handler
    #   @option msg [String] :msg    message that has been received
    #   @option msg [String] :user   user that sent the message
    #   @option msg [String] :source source of the message, e.g. the
    #                               channel
    #   @option msg [Bot] :bot       the bot instance that received the
    #                               message
    #
    #   @return [String]            response to send back to the source
    #                               the message was received from
    #   @return [(String, String)]  response and target to send back to
    #   @return [nil]               if nothing should be sent back

    def process_msg(msg)
      return false unless action = get_action(msg[:msg])

      @log.debug "found action: #{action}; message: #{msg[:msg]}"

      get_reply(action, msg)
    end


    ##
    # Analyze the message and if it looks like a {Command} or a Reply
    # find it, else check if a {Response} trigger matches.
    #
    # @param [String] msg message that has been received
    #
    # @return [Command, Response]
    # @return [String, Array<String>] if a Reply is found

    def get_action(msg)
      if msg[0] == @config.tc
        find_handler(msg)
      else
        find_response(msg)
      end
    end


    ##
    # Evaluate the found action. For childs of {Action} that means to
    # run their {Action#action `action`} block. For Replies this means
    # to pick a random one from the found array or using them as is, if
    # a single one was found and passed.
    #
    # @param [Command,Response,String,Array<String>] action
    # @!macro handler_tags

    def get_reply(action, msg)
      if [Command, Response].include? action.class
        action.call(msg.merge(bot: self))
      elsif action.respond_to?(:sample)
        action.sample
      else
        action
      end
    end


    ##
    # If the message starts with the defined trigger character, look if
    # there is a {Command} or Reply witch a matching name.
    #
    # @param (see #get_action)
    #
    # @return [Command, String, Array<String>] if something is found
    # @return [nil] if nothing is found

    def find_handler(msg)
      name = msg[/\A#{@config.tc}(\S+)(?:\s+(\d+))?/, 1]
      find_command(name) || find_reply(name, $2)
    end


    ##
    # Search the loaded {Command Commands} for one that has the
    # requested name.
    #
    # @param [String] name name to search for
    #
    # @return[Command, nil] {Command} or nil if none found

    def find_command(name)
      commands.find { |cmd| cmd.name == name.to_sym }
    end


    ##
    # Search the loaded Replies for one that has the requested name.
    # If an `index` is passed, than return that element of the array.
    # Otherwise pick a random one.
    #
    # @param [String] name name to search for
    # @param [Fixnum] index index of element to return
    #
    # @return [String, Array<String>, nil] nil if none matches

    def find_reply(name, index = nil)
      reply = @replies[name]
      if index && reply.is_a?(Array) && reply.size > index.to_i
        reply[index.to_i]
      else
        reply
      end
    end


    ##
    # Search the loaded {Response Responses} for one that has a trigger
    # that matches.
    #
    # @param [String] msg message that has been received
    #
    # @return [Response, nil] {Response} or nil if none found

    def find_response(msg)
      responses.find { |resp| msg.match(resp.trigger) }
    end


    ##
    # Wrapper for {Protocol} specific {Connection} instantiation. This
    # dummy method is replaced by the loaded {Protocol} module's method.

    def init_connection
      # dummy replaced by a {Protocol} module
    end


    ##
    # Wrapper for {Protocol} specific message processing loop. This
    # dummy method is replaced by the loaded {Protocol} module's method.

    def run_loop(msg)
      # dummy replaced by a {Protocol} module
    end


    ##
    # Wrapper for {Protocol} specific message sending. This dummy method
    # is replaced by the loaded {Protocol} module's method.
    #
    # @param [String] line message to send
    # @param [String] target recipient of the message (user or channel)

    def server_say(line, target)
      # dummy replaced by a {Protocol} module
    end

  end # class Bot

end # module RIB
