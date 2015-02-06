# coding: utf-8

class RIB::Command

  attr_reader :name, :modul


  def initialize(name, modul)
    @name, @modul = name, modul
  end


  ##
  # Check if the command takes the number of arguments.
  #
  # @params args_count [Fixnum]
  #
  # @return [Boolean]

  def takes_args?(args_count)
    if args_count < args[:min]
      false
    elsif args[:max] and args_count > args[:max]
      false
    else
      true
    end
  end


  def timeout
    @modul.timeouts[@name]
  end


  def description
    @modul.descriptions[@name]
  end

  alias :desc :description


  def call(bot, msg)
    @modul.new(bot, msg).send(@name, *msg.arguments)
  end


  private

  def args
    params = method.parameters.group_by(&:first)

    args_min = params[:req].to_a.count
    args_max = args_min + params[:opt].to_a.count

    {min: args_min, max: params[:rest] ? nil : args_max}
  end


  def method
    @modul.instance_method(name)
  end

end

