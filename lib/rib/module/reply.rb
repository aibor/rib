# coding: utf-8

require 'yaml'


class RIB::Module::Reply < RIB::Module::Base
  
  describe 'Simple replies with management tools'

  register replies_file: 'data/replies.yml'

  init { load_replies }


  describe reply: <<-EOS
    Manage replies. Without trigger, show all trigger. With trigger and
    without command, shows the trigger's values array. Pass an arbitrary
    string with "add" or an index number with "del" (starts with 0)
  EOS

  def reply(trigger = nil, subcommand = nil, *args)
    hints = ['How about no?', 'Go away!', '°.°', '<_<', 'sryly?']

    return @replies.keys * ', ' unless trigger

    unless subcommand
      replies = @replies[trigger]
      return "Unknown trigger: #{trigger}" unless replies
      return replies.map.with_index { |e, i| %(#{i}: "#{e}") } * ', '
    end

    return hints.sample unless msg.user == bot.config.admin
    return "No arguments passed" if args.empty?

    case subcommand
    when 'add'
      if add_reply(trigger, args * ' ')
        'Added this crap!'
      else
        'Me or you failed :/'
      end
    when 'del'
      id = args.first
      if id[/\A\d+\z/] && delete_reply(trigger, id.to_i)
        'Wooohooo - delete all the junk!'
      else
        "Doesn't work this way!"
      end
    else
      "What? Try '#{bot.config.tc}help reply'."
    end
  end


  @protected = public_instance_methods(false)

  private

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
    if reply_validation.call(trigger, value.to_s)
      @replies[trigger] = [@replies[trigger], value].flatten.compact
      save_replies
    end
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
    if @replies && @replies[trigger] && @replies[trigger][index]
      @replies[trigger].delete_at(index)
      save_replies
    end
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

  def define_reply_method(name)
    return if respond_to?(name)
    self.class.send(:define_method, name) do |index = nil|
      replies = @replies[name]
      reply = replies[index.to_i] if index.to_s[/\A\d+\z/] 
      reply || replies.sample
    end
  end


  def remove_reply_method(name)
    protect = self.class.instance_variable_get(:@protected)
    return if !respond_to?(name) || protect.include?(name)
    remove_method(name)
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
    ->(*args) { args.flatten.all? { |e| e.is_a? String } }
  end


  ##
  # Load the replies from the file specified in
  # {Configuration#replies_file}.
  #
  # @return [Hash{String => Array<String>] all loaded replies

  def load_replies
    file = bot.config.replies_file
    hash = YAML.load_file(file) if File.exists?(file)
    @replies = hash.select(&reply_validation) if hash
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
      if value && value.any?
        hash[key] = [value].flatten
        define_reply_method(key)
      else
        remove_reply_method(key.to_sym)
      end
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

    if File.writable?(bot.config.replies_file)
      File.write(bot.config.replies_file, @replies.to_yaml)
    else
      bot.logger.warn "Couldn't save replies to file"
      false
    end
  end

end
