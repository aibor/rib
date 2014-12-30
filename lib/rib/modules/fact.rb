# coding: utf-8

require 'yaml'


class RIB::Module::Fact < RIB::Module

  class << self

    ##
    # Hash with all facts.
    #
    # @return [Hash{Symbol => Array<String>}]

    attr_reader :facts


    ##
    # Lambda function for Validation of a fact's name and its value.
    # First argument must be a String, second argumwnt must be a String
    # or an Array of Strings.
    #
    # This is intended to be used for direct invocation or for passing
    # it to an Enumerator.
    #
    # @example for a single pair
    #   validator.call('moo', 'mooo000ooo')
    #
    # @example with Enumerator called from instance
    #   hash = {'one' => 'silence', 'two' => 3}
    #   hash.select &self.class.validator #=> {'one' => 'silence'}
    #
    # @return [Proc (lambda)] validation lambda function

    attr_reader :validator


    private

    ##
    # Define a public method for a fact hash key, so that it can be used
    # as a bot command for getting the facts for this key.
    #
    # @param name [String] name of the new method, the key
    #
    # @return [String, Array<String>, nil] nil if none matches

    def define_fact_method(name)
      return if public_instance_methods(false).include?(name)
      old_verbose = $VERBOSE
      $VERBOSE = nil
      define_method(name) do |index = nil|
      facts_a = facts[name]
      fact = facts_a[index.to_i] if index.to_s[/\A\d+\z/] 
      fact || facts_a.sample
      end
      $VERBOSE = old_verbose
    end


    def remove_fact_method(name)
      return if instance_variable_get(:@protected).include?(name)
      return unless instance_methods(false).include?(name)
      undef_method(name)
    end


    ##
    # Facts should be stored alphabetically with values as array.
    # Empty fact names and values are removed.
    #
    # @return [Hash{String => Array<String>] all loaded facts

    def sanitize_facts
      return unless @facts.respond_to?(:sort)
      @facts.sort.inject({}) do |hash, (key, value)|
        value.compact! if value.respond_to?(:compact)
        if value && value.any?
          hash[key] = [value].flatten
          define_fact_method(key)
        else
          remove_fact_method(key.to_sym)
        end
        hash
      end
    end

  end


  @facts = {}
  @validator = ->(*a) { a.flatten.all? { |e| e.is_a? String } }

  describe 'Simple fact replies with management tools'

  register facts_file: 'data/facts.yml'

  on_init do |bot|
    file = bot.config.facts_file
    hash = YAML.load_file(file) if File.exist?(file)
    @facts = hash.select(&@validator) if hash
    sanitize_facts
  end


  describe facts: <<-EOS
    Manage facts. Without fact_name, show all facts. With fact_name and
    without command, shows the fact's values array. Pass an arbitrary
    string with "add" or an index number with "del" (starts with 0)
  EOS

  def fact(fact_name = nil, subcommand = nil, *args)
    hints = ['How about no?', 'Go away!', '°.°', '<_<', 'sryly?']

    return facts.keys * ', ' unless fact_name

    unless subcommand
      fact_a = facts[fact_name]
      return "Unknown fact_name: #{fact_name}" unless fact_a
      return fact_a.map.with_index { |e, i| %(#{i}: "#{e}") } * ', '
    end

    return hints.sample unless msg.user == bot.config.admin
    return "No arguments passed" if args.empty?

    case subcommand
    when 'add'
      if add_fact(fact_name, args * ' ')
        'Added this crap!'
      else
        'Me or you failed :/'
      end
    when 'del'
      id = args.first
      if id[/\A\d+\z/] && delete_fact(fact_name, id.to_i)
        'Wooohooo - delete all the junk!'
      else
        "Doesn't work this way!"
      end
    else
      "What? Try '#{bot.config.tc}help fact'."
    end
  end


  @protected = public_instance_methods(false)

  private

  def facts
    self.class.facts
  end


  ##
  # Add a fact to the facts Hash. On success the current facts
  # Hash will be saved to the `facts_file`.
  #
  # @param fact_name [String] name of the fact to add a value for
  # @param value     [String] String to add to the fact's value array
  #
  # @return [Fixnum] length of written bytes on success
  # @return [FalseClass] if something went wrong

  def add_fact(fact_name, value)
    if self.class.validator.call(fact_name, value.to_s)
      facts[fact_name] = [facts[fact_name], value].flatten.compact
      save_facts
    end
  end


  ##
  # Delete a fact from the facts Hash. On success the current facts
  # Hash will be saved to the `facts_file`.
  #
  # @param fact_name [String] name of the fact to delete a value
  #                           from
  # @param index     [Fixnum] index to delete from the fact's value
  #                           array
  #
  # @return [Fixnum] length of written bytes on success
  # @return [FalseClass] if something went wrong

  def delete_fact(fact_name, index)
    if facts && facts[fact_name] && facts[fact_name][index]
      facts[fact_name].delete_at(index)
      save_facts
    end
  end


  ##
  # Write the current facts Hash to the file specified in
  # `facts_file`.
  #
  # @return [Fixnum] bytes written if successful
  # @return [FalseClass] if the file isn't writeable

  def save_facts
    self.class.send(:sanitize_facts)

    if File.writable?(bot.config.facts_file)
      File.write(bot.config.facts_file, facts.to_yaml)
    else
      bot.logger.warn "Couldn't save facts to file"
      false
    end
  end

end

