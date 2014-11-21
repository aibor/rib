# coding: utf-8

require 'rib/connection.rb'
require 'socket'
require 'openssl'
require 'logger'
require 'date'


module RIB::Connection

  class IRC::Connection < Base

    class Message < Struct.new(:prefix, :user, :source, :command, :params,
                               :data)

      ##
      # regular expression for parsing a message received by the server.

      RE = / \A
      (?::((?:([^!]+)!)?\S+)\s)?  # prefix and user
      ([A-Za-z]+|\d{3})           # command
      ((?:\s[^:]\S+)*)            # params, minus last
      (?:\s:?(?>(.*)))?           # data
      \Z /x


      ##
      # Parse a received message string into a handy object.
      #
      # @param msg [String] message to parse
      #
      # @return [Message]

      def self.parse(msg = '')
        raise(RIB::MalformedMessageError, msg) unless msg.to_s =~ RE

        prefix, user, command, params = $1, $2, $3, $4.split + [$5].compact
        source = unless params[0].to_s.empty?
                   params[0].to_s[/\A#.*/] || user
                 end

        new(prefix, user, source, command, params, params.last)
      end

    end


    User = Struct.new(:user, :channels, :server, :auth)

    NON_LOG_CMDS = %w(PONG WHOIS PRIVMSG NOTICE)

    DEFAULT_OPTIONS = {
      port: 6667,
      ssl:  {
        use:      false,
        ca_path:  '/etc/ssl/certs',
        verify:   false,
        cert:     false
      }
    }

    MESSAGE_METHODS = %i(nick join privmsg notice user mode quit action part)

    PING_INTERVAL = 300


    ##
    # @param log_path [String] path where the logs shall be stored
    # @param host     [String] hostname or IP address of the server
    # @param nick     [String] nickname to use
    # @param options  [Hash]   optional options to iuse for the connection

    def initialize(log_path, host, nick, options = Hash.new)
      @options = DEFAULT_OPTIONS.merge options
      @host, @nick, @mutex = host, nick, Mutex.new

      connect

      super
    end


    ##
    # Login to the IRC server. This will send a `NICK` and `USER` command
    # and wait for a `001` command reply by the server. If the login
    # succeed, a new thread is started for pinging the server ourself, in
    # order to notice stalled connections.
    #
    # @see #start_ping_thread
    #
    # @raise [LoginError]
    #
    # @return [Thread]

    def login
      nick @nick
      user @nick, 'hostname', 'servername', ":#{@nick}"

      reply = receive_until do |c|
        c.command =~ /\A(?:43[1236]|46[12]|001)\Z/
      end

      if reply && reply.command == "001"
        start_ping_thread
      else
        raise(RIB::LoginError, reply)
      end
    end


    ##
    # Send an authentication string to the server. This will be sent as
    # a PRIVMSG to the server. It will also set the mode `+x` for itself.
    #
    # @param authdata [String] 
    #
    # @raise [AuthError] if invalid authdata is given
    #
    # @return ["auth sent"]

    def auth_nick(authdata)
      raise RIB::AuthError.new(authdata) unless authdata.is_a?(String)

      authdata = authdata.split(/\s+/)
      privmsg authdata.shift, authdata * ' '
      mode "#{@nick} +x", " "
      "auth sent"
    end


    ##
    # Do a WHOIS for its own nick and sets `@me`.
    #
    # @param me [String] nick of the bot
    #
    # @return [String] user string

    def setme(me)
      mearr = whois(me).user.split.shift(2)
      @me = ":#{me}!#{mearr * '@'} "
    end


    ##
    # Join a channel and add a Logger for this channel to the logging
    # object.
    #
    # @param channel [String] name of the channel to join
    #
    # @raise [ChannelJoinError]
    #
    # @return [Boolean]

    def join_channel(channel)
      join channel

      reply = receive_until do |c|
        c.command =~ /\A(?:461|47[13456]|40[35]|332|353)\Z/
      end

      unless reply && reply.command[/\A3(?:32|53)\Z/]
        raise RIB::ChannelJoinError, reply.data
      end

      !!@logging.add_channel_log(channel)
    end


    ##
    # Read messages from the server. Some messages are handled
    # automatically and are not parsed and returned, like PING requests
    # by the server or CTCP requests by other users.
    #
    # @raise [ReceivedError] if an error is received
    #
    # @return [Message]

    def receive
      true until msg = receive_message

      if msg =~ /ERROR:.*/
        raise RIB::ReceivedError, msg
      elsif response = instant_action(msg)
        send_message(response)
        receive
      else
        irclog(msg)
        rib_msg = Message.parse(msg)
        ctcp?(rib_msg) || pong?(rib_msg) ? receive : rib_msg
      end
    end


    ##
    # Do a WHOIS request for a nickname.
    #
    # @param user [String]
    #
    # @return [User]

    def whois(user)
      send_message "WHOIS #{user}"

      out = User.new

      while msg = receive
        2.times {|i| msg.params.shift}
        case msg.command
        when /\A(?:311)\Z/ then out.user = msg.params * " "
        when /\A(?:319)\Z/ then out.channels = msg.params[0].split
        when /\A(?:312)\Z/ then out.server = msg.params * " "
        when /\A(?:330)\Z/ then out.auth = msg.params[0]
        when /\A(?:318)\Z/ then break
        end
      end

      out
    end


    ##
    # Wait until a message is received that yields true.
    #
    # @yieldparam msg [Message] the message to evaluate
    # @yieldreturn [Boolean] 
    #
    # @return [Message] message that yielded true

    def receive_until
      while msg = receive
        return msg if yield msg
      end
    end


    ##
    # Dynamically handle allowed Messages defined in {MESSAGE_METHODS}.
    # This way one can use methods like `self.quit("Bye!")` or 
    # `self.privmsg('#example', 'Hi There')`.
    # 
    # @return [void]

    def method_missing(meth, *args)
      if MESSAGE_METHODS.include? meth
        params = args.dup
        params[-1] = params.last.sub(/\A[^:].* /, ':\&')
        send_message "#{meth.to_s.upcase} #{params * ' '}"
      else
        super
      end
    end


    def stop_ping_thread
      @ping_thread.kill if @ping_thread.is_a?(Thread)
      @ping_thread = nil
    end


    private

    ##
    # Connect to the IRC server.
    #
    # @return [TCPSocket, OpenSSL::SSL::SSLSocket]

    def connect
      tcp_socket  = TCPSocket.new @host, @options[:port]
      @irc_socket = if @options[:ssl][:use]
                      ssl_connection(tcp_socket, @options[:ssl])
                    else
                      tcp_socket
                    end
    end


    ##
    # Wrap the passed Socket in TLS. 
    #
    # @param socket [TCPSocket]
    # @param options [Hash]
    #
    # @return [OpenSSL::SSL::SSLSocket]

    def ssl_connection(socket, options = {})
      ssl_context = OpenSSL::SSL::SSLContext.new

      if options[:cert]
        cert = File.read(options[:cert])
        ssl_context.cert = OpenSSL::X509::Certificate.new(cert)
        ssl_context.key = OpenSSL::PKey::RSA.new(cert)
      end

      if Dir.exists?(options[:ca_path].to_s)
        ssl_context.ca_path = options[:ca_path].to_s
      end

      const = options[:verify] ? 'VERIFY_PEER' : 'VERIFY_NONE'
      ssl_context.verify_mode = OpenSSL::SSL.const_get(const)

      ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
      ssl_socket.sync = true
      ssl_socket.connect

      ssl_socket
    end


    ##
    # Start a thread for sending PINGs to the server. Do this until the
    # server stops responding. This is noticed by checking the last
    # received PONG. If it doesn't match the last sent PING, an exception
    # is raised.
    #
    # @raise [LostConnectionError]
    #
    # @return [Thread]

    def start_ping_thread
      @ping_thread.kill if @ping_thread && @ping_thread.alive?
      last_ping = 0

      @ping_thread = Thread.new do
        while @mutex.synchronize { @last_pong.to_i } == last_ping
          @irc_socket.puts("PING #{last_ping += 1}")
          sleep PING_INTERVAL
        end
        raise RIB::LostConnectionError
      end
    end


    ##
    # Read a message from the server. If it is empty, keep on reading.
    #
    # @return [String]

    def receive_message
      true until msg = @irc_socket.gets
      msg.strip!
      msg.empty? ? receive_message : msg
    end


    ##
    # Check if the message is a request we just want to answer and forget
    # about it, e.g. a server's PING request.
    #
    # @param msg [String] raw message received by the server
    #
    # @return [String] reply to send back if a matching instant action is
    #   found
    # @return [false] if nothing matches

    def instant_action(msg)
      case msg
      when /\APING (.*?)\z/ then "PONG #{$1}"
      else false
      end
    end


    ##
    # Sends a message to the server and logs it unless it is is a command
    # that shouldn't be logged.
    #
    # @param msg [String]
    #
    # @return [nil]

    def send_message(msg)
      return if msg.to_s.empty?
      irclog("#{@me} #{msg}") unless non_log?(msg)
      @irc_socket.print "#{msg}\r\n"
    end


    ##
    # Find the appropriate Logger instance and log the object.
    #
    # @param obj [Object] object to log
    #
    # @return [Boolean] if logging was successful

    def irclog(obj)
      msg = obj.to_s
      target = if msg =~ /:(\S+)!(?:\S+)\s(\w+)\s((#\S+)\s)?:(.*)/ && $4
                 @logging.channels[$4]
               else
                 @logging.server
               end
      target.send(:info, msg.gsub(/||(\d,\d+)?/, '')) if target
    end


    ##
    # Check if a message to send is a IRC command that shouldn't be
    # logged.
    #
    # @param msg [String] string that should be checked
    #
    # @return [Boolean] true if it should not be logged

    def non_log?(msg)
      !!(msg =~ /\A(?:#{NON_LOG_CMDS * '|'} [^#])/)
    end


    ##
    # Check if the {Message} is a CTCP request and reply appropriately.
    # 
    # @param msg [Message]
    #
    # @return [Boolean] if it is a CTCP request or not

    def ctcp?(msg)
      resp = case msg.data
             when /\APING (.*)\z/
               "PING #{$1}"
             when /\ATIME\z/
               "TIME #{Time.now.strftime('%c %Z')}"
             when /\AVERSION\z/
               "VERSION RIB:#{RIB::VERSION}:idling on WankyOS" 
             else
               return false
             end

      !!notice(msg.source, resp)
    end


    ##
    # Check if the message is a PONG reply to our PING. If it is, get the
    # value and store it.
    #
    # @param msg [String] raw message received from the server
    #
    # @return [Booelan] if it is a PONG or not

    def pong?(msg)
      if msg.command == 'PONG'
        !!@mutex.synchronize { @last_pong = msg.data }
      else
        false
      end
    end

  end

end

